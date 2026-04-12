# Flutter Clean Architecture Blueprint

## Dependency Direction

The safe default dependency flow is:

```text
presentation -> domain <- data
```

That means:

- `presentation` knows about domain contracts and use cases
- `data` knows about domain contracts so it can implement them
- `domain` knows nothing about Flutter widgets, API clients, local storage, or concrete repositories

## Feature Slice Template

```text
lib/features/todos/
  data/
    datasources/
      todos_remote_datasource.dart
    dto/
      todo_dto.dart
    mappers/
      todo_mapper.dart
    repositories/
      todo_repository_impl.dart
  domain/
    entities/
      todo.dart
    repositories/
      todo_repository.dart
    usecases/
      get_todos.dart
      create_todo.dart
  presentation/
    controllers/
      todos_controller.dart
    pages/
      todos_page.dart
    widgets/
      todo_list.dart
```

## Layer Responsibilities

### `domain`

- entities
- value objects
- repository contracts
- use cases
- domain services

Do not put:

- JSON serialization
- Flutter widget state
- API response models
- platform or storage APIs

### `data`

- remote and local datasources
- DTOs
- mappers between DTOs and domain entities
- repository implementations
- error translation from infra to domain-friendly failures

### `presentation`

- controllers or notifiers
- pages and widgets
- UI-specific models if needed
- navigation triggers

## Suggested App-Level Structure

```text
lib/
  app/
    bootstrap/
      app_bootstrap.dart
    router/
      app_router.dart
    theme/
      app_theme.dart
  core/
    error/
      failures.dart
    network/
      api_client.dart
    storage/
      secure_storage.dart
```

## Package Recommendations

These are defaults, not mandates:

- `flutter_riverpod` for DI and state
- `go_router` for navigation
- `freezed` plus `json_serializable` for immutable models and DTOs
- `mocktail` or `mockito` for mocking
- `flutter_test` for widget tests

If the repo already uses Bloc, Provider, GetIt, or another stack, preserve the local standard unless the task is explicitly a migration.

## Review Checklist

Before finishing a task, verify:

- widgets do not call datasources directly
- domain files do not import Flutter UI libraries
- DTOs stay in `data`
- repositories exposed to `presentation` are interfaces from `domain`
- tests cover the most important business behavior added or changed
