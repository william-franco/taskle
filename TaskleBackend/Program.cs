using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json.Serialization;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Scalar.AspNetCore;

var builder = WebApplication.CreateBuilder(args);

var jwtSection = builder.Configuration.GetSection("Jwt");
var jwtKey = jwtSection["Key"] ?? throw new InvalidOperationException("Jwt:Key is required.");
var jwtIssuer = jwtSection["Issuer"] ?? "taskle";
var jwtAudience = jwtSection["Audience"] ?? "taskle";
var jwtExpiresMinutes = int.Parse(jwtSection["ExpiresInMinutes"] ?? "60");
var refreshExpiresDays = int.Parse(jwtSection["RefreshExpiresInDays"] ?? "7");

builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseSqlite(builder.Configuration.GetConnectionString("Default")));

builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.Events = new JwtBearerEvents
        {
            OnMessageReceived = context =>
            {
                if (HttpMethods.IsOptions(context.Request.Method))
                {
                    context.NoResult();
                }
                return Task.CompletedTask;
            }
        };
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = jwtIssuer,
            ValidAudience = jwtAudience,
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey)),
            ClockSkew = TimeSpan.Zero
        };
    });

builder.Services.AddAuthorization();

builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
        policy.SetIsOriginAllowed(_ => true)
            .AllowAnyHeader()
            .AllowAnyMethod());
});

builder.Services.AddOpenApi();

var app = builder.Build();

using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    db.Database.Migrate();
}

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
    app.MapScalarApiReference();
}

app.UseCors();
app.UseAuthentication();
app.UseAuthorization();

var apiV1 = app.MapGroup("/api/v1");

// --- Auth ---

apiV1.MapPost("/auth/register", async (RegisterRequest request, AppDbContext db) =>
{
    if (string.IsNullOrWhiteSpace(request.Name) ||
        string.IsNullOrWhiteSpace(request.Email) ||
        string.IsNullOrWhiteSpace(request.Password))
    {
        return Results.BadRequest(new { message = "Name, email and password are required." });
    }

    var email = request.Email.Trim().ToLowerInvariant();
    if (await db.Users.AnyAsync(u => u.Email == email))
    {
        return Results.Conflict(new { message = "Email already registered." });
    }

    var user = new User
    {
        Name = request.Name.Trim(),
        Email = email,
        Password = BCrypt.Net.BCrypt.HashPassword(request.Password),
        CreatedAt = DateTime.UtcNow,
        UpdatedAt = DateTime.UtcNow
    };

    db.Users.Add(user);
    await db.SaveChangesAsync();

    var tokens = await CreateTokenPairAsync(db, user, jwtKey, jwtIssuer, jwtAudience, jwtExpiresMinutes, refreshExpiresDays);
    return Results.Ok(new AuthResponse(tokens.AccessToken, tokens.RefreshToken, UserDto.FromEntity(user)));
})
.WithTags("Auth")
.WithName("Register");

apiV1.MapPost("/auth/login", async (LoginRequest request, AppDbContext db) =>
{
    if (string.IsNullOrWhiteSpace(request.Email) || string.IsNullOrWhiteSpace(request.Password))
    {
        return Results.BadRequest(new { message = "Email and password are required." });
    }

    var email = request.Email.Trim().ToLowerInvariant();
    var user = await db.Users.FirstOrDefaultAsync(u => u.Email == email);
    if (user is null || !BCrypt.Net.BCrypt.Verify(request.Password, user.Password))
    {
        return Results.Unauthorized();
    }

    var tokens = await CreateTokenPairAsync(db, user, jwtKey, jwtIssuer, jwtAudience, jwtExpiresMinutes, refreshExpiresDays);
    return Results.Ok(new AuthResponse(tokens.AccessToken, tokens.RefreshToken, UserDto.FromEntity(user)));
})
.WithTags("Auth")
.WithName("Login");

apiV1.MapPost("/auth/refresh", async (RefreshRequest request, AppDbContext db) =>
{
    if (string.IsNullOrWhiteSpace(request.RefreshToken))
    {
        return Results.BadRequest(new { message = "Refresh token is required." });
    }

    var stored = await db.RefreshTokens
        .Include(r => r.User)
        .FirstOrDefaultAsync(r => r.Token == request.RefreshToken && r.RevokedAt == null);

    if (stored is null || stored.ExpiresAt <= DateTime.UtcNow)
    {
        return Results.Unauthorized();
    }

    stored.RevokedAt = DateTime.UtcNow;
    var tokens = await CreateTokenPairAsync(db, stored.User!, jwtKey, jwtIssuer, jwtAudience, jwtExpiresMinutes, refreshExpiresDays);
    await db.SaveChangesAsync();

    return Results.Ok(new TokenResponse(tokens.AccessToken, tokens.RefreshToken));
})
.WithTags("Auth")
.WithName("Refresh");

apiV1.MapPost("/auth/logout", async (RefreshRequest request, AppDbContext db) =>
{
    if (string.IsNullOrWhiteSpace(request.RefreshToken))
    {
        return Results.BadRequest(new { message = "Refresh token is required." });
    }

    var stored = await db.RefreshTokens.FirstOrDefaultAsync(r => r.Token == request.RefreshToken && r.RevokedAt == null);
    if (stored is not null)
    {
        stored.RevokedAt = DateTime.UtcNow;
        await db.SaveChangesAsync();
    }

    return Results.NoContent();
})
.WithTags("Auth")
.WithName("Logout");

apiV1.MapGet("/auth/me", async (ClaimsPrincipal user, AppDbContext db) =>
{
    var userId = GetUserId(user);
    if (userId is null) return Results.Unauthorized();

    var entity = await db.Users.FindAsync(userId.Value);
    if (entity is null) return Results.NotFound();

    return Results.Ok(UserDto.FromEntity(entity));
})
.RequireAuthorization()
.WithTags("Auth")
.WithName("GetProfile");

// --- Tasks (authenticated) ---

apiV1.MapGet("/tasks", async (ClaimsPrincipal user, AppDbContext db) =>
{
    var userId = GetUserId(user);
    if (userId is null) return Results.Unauthorized();

    var tasks = await db.TaskItems
        .Where(t => t.UserId == userId.Value)
        .OrderByDescending(t => t.CreatedAt)
        .ToListAsync();

    return Results.Ok(tasks.Select(TaskDto.FromEntity));
})
.RequireAuthorization()
.WithTags("Tasks")
.WithName("ListTasks");

apiV1.MapGet("/tasks/{id:int}", async (int id, ClaimsPrincipal user, AppDbContext db) =>
{
    var userId = GetUserId(user);
    if (userId is null) return Results.Unauthorized();

    var task = await db.TaskItems.FirstOrDefaultAsync(t => t.Id == id && t.UserId == userId.Value);
    return task is null ? Results.NotFound() : Results.Ok(TaskDto.FromEntity(task));
})
.RequireAuthorization()
.WithTags("Tasks")
.WithName("GetTask");

apiV1.MapPost("/tasks", async (TaskRequest request, ClaimsPrincipal user, AppDbContext db) =>
{
    var userId = GetUserId(user);
    if (userId is null) return Results.Unauthorized();

    if (string.IsNullOrWhiteSpace(request.Title))
    {
        return Results.BadRequest(new { message = "Title is required." });
    }

    var task = new TaskItem
    {
        UserId = userId.Value,
        Title = request.Title.Trim(),
        Content = request.Content?.Trim() ?? string.Empty,
        IsCompleted = false,
        CreatedAt = DateTime.UtcNow,
        UpdatedAt = DateTime.UtcNow
    };

    db.TaskItems.Add(task);
    await db.SaveChangesAsync();

    return Results.Created($"/api/v1/tasks/{task.Id}", TaskDto.FromEntity(task));
})
.RequireAuthorization()
.WithTags("Tasks")
.WithName("CreateTask");

apiV1.MapPut("/tasks/{id:int}", async (int id, TaskUpdateRequest request, ClaimsPrincipal user, AppDbContext db) =>
{
    var userId = GetUserId(user);
    if (userId is null) return Results.Unauthorized();

    var task = await db.TaskItems.FirstOrDefaultAsync(t => t.Id == id && t.UserId == userId.Value);
    if (task is null) return Results.NotFound();

    if (!string.IsNullOrWhiteSpace(request.Title)) task.Title = request.Title.Trim();
    if (request.Content is not null) task.Content = request.Content.Trim();
    if (request.IsCompleted.HasValue) task.IsCompleted = request.IsCompleted.Value;
    task.UpdatedAt = DateTime.UtcNow;

    await db.SaveChangesAsync();

    return Results.Ok(TaskDto.FromEntity(task));
})
.RequireAuthorization()
.WithTags("Tasks")
.WithName("UpdateTask");

apiV1.MapDelete("/tasks/{id:int}", async (int id, ClaimsPrincipal user, AppDbContext db) =>
{
    var userId = GetUserId(user);
    if (userId is null) return Results.Unauthorized();

    var task = await db.TaskItems.FirstOrDefaultAsync(t => t.Id == id && t.UserId == userId.Value);
    if (task is null) return Results.NotFound();

    var taskTitle = task.Title;
    db.TaskItems.Remove(task);
    await db.SaveChangesAsync();

    return Results.Ok(new DeleteTaskResponse(
        "Task excluida",
        $"A task {taskTitle} foi removida permanentemente"));
})
.RequireAuthorization()
.WithTags("Tasks")
.WithName("DeleteTask");

app.Run();

// --- Helpers ---

static int? GetUserId(ClaimsPrincipal user)
{
    var claim = user.FindFirstValue(ClaimTypes.NameIdentifier) ?? user.FindFirstValue(JwtRegisteredClaimNames.Sub);
    return int.TryParse(claim, out var id) ? id : null;
}

static async Task<(string AccessToken, string RefreshToken)> CreateTokenPairAsync(
    AppDbContext db,
    User user,
    string jwtKey,
    string issuer,
    string audience,
    int expiresMinutes,
    int refreshExpiresDays)
{
    var accessToken = GenerateAccessToken(user, jwtKey, issuer, audience, expiresMinutes);
    var refreshToken = GenerateRefreshToken();

    db.RefreshTokens.Add(new RefreshToken
    {
        UserId = user.Id,
        Token = refreshToken,
        ExpiresAt = DateTime.UtcNow.AddDays(refreshExpiresDays),
        RevokedAt = null
    });

    await db.SaveChangesAsync();
    return (accessToken, refreshToken);
}

static string GenerateAccessToken(User user, string jwtKey, string issuer, string audience, int expiresMinutes)
{
    var claims = new[]
    {
        new Claim(JwtRegisteredClaimNames.Sub, user.Id.ToString()),
        new Claim(JwtRegisteredClaimNames.Email, user.Email),
        new Claim(ClaimTypes.Name, user.Name),
        new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
    };

    var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey));
    var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);
    var token = new JwtSecurityToken(
        issuer: issuer,
        audience: audience,
        claims: claims,
        expires: DateTime.UtcNow.AddMinutes(expiresMinutes),
        signingCredentials: credentials);

    return new JwtSecurityTokenHandler().WriteToken(token);
}

static string GenerateRefreshToken()
{
    var bytes = new byte[64];
    RandomNumberGenerator.Fill(bytes);
    return Convert.ToBase64String(bytes);
}

// --- Entities ---

class AppDbContext(DbContextOptions<AppDbContext> options) : DbContext(options)
{
    public DbSet<User> Users => Set<User>();
    public DbSet<TaskItem> TaskItems => Set<TaskItem>();
    public DbSet<RefreshToken> RefreshTokens => Set<RefreshToken>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<User>(e =>
        {
            e.HasIndex(u => u.Email).IsUnique();
        });

        modelBuilder.Entity<TaskItem>(e =>
        {
            e.ToTable("Tasks");
            e.HasOne(t => t.User)
                .WithMany(u => u.Tasks)
                .HasForeignKey(t => t.UserId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<RefreshToken>(e =>
        {
            e.HasOne(r => r.User).WithMany().HasForeignKey(r => r.UserId).OnDelete(DeleteBehavior.Cascade);
            e.HasIndex(r => r.Token).IsUnique();
        });
    }
}

class User
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
    public List<TaskItem> Tasks { get; set; } = [];
}

class TaskItem
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public User? User { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Content { get; set; } = string.Empty;
    public bool IsCompleted { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
}

class RefreshToken
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public User? User { get; set; }
    public string Token { get; set; } = string.Empty;
    public DateTime ExpiresAt { get; set; }
    public DateTime? RevokedAt { get; set; }
}

// --- DTOs ---

record RegisterRequest(string Name, string Email, string Password);
record LoginRequest(string Email, string Password);
record RefreshRequest([property: JsonPropertyName("refreshToken")] string RefreshToken);
record TaskRequest(string Title, string? Content);
record TaskUpdateRequest(string? Title, string? Content, bool? IsCompleted);

record AuthResponse(
    [property: JsonPropertyName("accessToken")] string AccessToken,
    [property: JsonPropertyName("refreshToken")] string RefreshToken,
    UserDto User);

record TokenResponse(
    [property: JsonPropertyName("accessToken")] string AccessToken,
    [property: JsonPropertyName("refreshToken")] string RefreshToken);

record UserDto(int Id, string Name, string Email, DateTime CreatedAt)
{
    public static UserDto FromEntity(User user) =>
        new(user.Id, user.Name, user.Email, user.CreatedAt);
}

record TaskDto(
    int Id,
    string Title,
    string Content,
    bool IsCompleted,
    DateTime CreatedAt,
    DateTime UpdatedAt)
{
    public static TaskDto FromEntity(TaskItem task) =>
        new(task.Id, task.Title, task.Content, task.IsCompleted, task.CreatedAt, task.UpdatedAt);
}

record DeleteTaskResponse(string Title, string Description);
