# Dev Feed Backend

Lorem ipsum.

## Migrations

```
dotnet tool install --global dotnet-ef --version 10.*
or
dotnet tool update --global dotnet-ef --version 10.*
dotnet ef database update
```

A migration `InitialCreate` já está versionada em `Migrations/`. Em um clone novo, use normalmente `dotnet ef database update` (ou apenas `dotnet run`, que aplica migrations na subida).

Só execute `dotnet ef migrations add <Nome>` após alterar entidades ou o `DbContext`.

## Run Project

```
dotnet build
dotnet run
```

## Accessing

API: http://localhost:5209

OpenAPI (docs): http://localhost:5209/openapi/v1.json

Scalar UI: http://localhost:5209/scalar

## Examples of commits

```
git add . && git commit -m ":rocket: Initial commit." && git push
git add . && git commit -m ":building_construction: Added initial project architecture." && git push
git add . && git commit -m ":building_construction: Update project architecture." && git push
git add . && git commit -m ":memo: Updated project documentation." && git push
git add . && git commit -m ":memo: Updated code documentation." && git push
git add . && git commit -m ":white_check_mark: Added feature xyz." && git push
git add . && git commit -m ":wrench: Fixed xyz usage." && git push
git add . && git commit -m ":heavy_minus_sign: Removed xyz." && git push
git add . && git commit -m ":memo: Adjusted project imports." && git push
git add . && git commit -m ":arrow_up: Updated dependencies." && git push
git add . && git commit -m ":arrow_down: Removed dependencies." && git push
git add . && git commit -m ":wastebasket: Removed unused code." && git push
```

## License

[MIT License](https://opensource.org/licenses/MIT)

Copyright (c) 2026 William Franco.
