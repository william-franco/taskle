using Xunit;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json.Serialization;

namespace TaskleBackend.IntegrationTests;

public sealed class ApiE2ETests(CustomWebApplicationFactory factory) : IClassFixture<CustomWebApplicationFactory>
{
    private readonly HttpClient _client = factory.CreateClient();

    [Fact]
    public async Task Register_login_and_tasks_flow_succeeds()
    {
        var email = $"user-{Guid.NewGuid():N}@test.local";
        var register = await _client.PostAsJsonAsync(
            "/api/v1/auth/register",
            new { name = "E2E User", email, password = "Pass123!" });
        Assert.True(register.IsSuccessStatusCode);

        var auth = await register.Content.ReadFromJsonAsync<AuthPayload>();
        Assert.NotNull(auth?.AccessToken);

        _client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", auth.AccessToken);

        var createTask = await _client.PostAsJsonAsync(
            "/api/v1/tasks",
            new { title = "E2E Task", content = "Do something" });
        Assert.True(createTask.IsSuccessStatusCode);

        var listTasks = await _client.GetAsync("/api/v1/tasks");
        Assert.True(listTasks.IsSuccessStatusCode);
    }

    private sealed record AuthPayload(
        [property: JsonPropertyName("accessToken")] string AccessToken);
}