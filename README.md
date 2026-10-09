# elder-assistant

Monorepo do CareApp.

| Pasta      | Conteúdo                                                        |
|------------|-----------------------------------------------------------------|
| `backend/` | API em .NET 10 (ASP.NET Core, EF Core + Npgsql, PostgreSQL)     |
| `mobile/`  | App Flutter (Riverpod, go_router, dio, localização PT-PT)       |
| `docs/`    | Documentação do projeto                                         |

## Pré-requisitos

- .NET SDK 10
- Docker (PostgreSQL local e testes de integração com Testcontainers)
- Flutter SDK (estável), com Android SDK e/ou Xcode

## Backend

Arquitetura limpa, com dependências a apontar para dentro:

```
CareApp.Api → CareApp.Infrastructure → CareApp.Application → CareApp.Domain
```

As versões dos pacotes NuGet são geridas centralmente em `backend/Directory.Packages.props`.

### Correr a API

```bash
cd backend
docker compose up -d          # PostgreSQL 17 em localhost:5432
dotnet run --project src/CareApp.Api --launch-profile http
```

- Em `Development` as migrations são aplicadas no arranque (`Database:MigrateOnStartup`).
- Health check: `GET http://localhost:5293/health`
- Swagger UI (só em Development): `http://localhost:5293/swagger`

### Migrations

```bash
cd backend
dotnet tool restore
dotnet ef migrations add <Nome> --project src/CareApp.Infrastructure --startup-project src/CareApp.Api --output-dir Persistence/Migrations
dotnet ef database update --project src/CareApp.Infrastructure --startup-project src/CareApp.Api
```

### Testes

```bash
cd backend
dotnet build
dotnet test                                              # unitários + integração (requer Docker)
dotnet test --project tests/CareApp.Tests.Unit           # só unitários
dotnet test --project tests/CareApp.Tests.Integration    # só integração
```

## Mobile

Na primeira vez, gerar as pastas nativas de Android e iOS (não altera `lib/`):

```bash
cd mobile
flutter create --platforms=android,ios --org pt.careapp --project-name careapp .
```

> Para usar a API por HTTP em desenvolvimento no Android, ativar `android:usesCleartextTraffic="true"`
> no `AndroidManifest.xml` de debug.

### Correr a app

```bash
cd mobile
flutter pub get               # também gera as localizações (lib/l10n)
flutter run                   # emulador Android: API em http://10.0.2.2:5293 por omissão
flutter run --dart-define=API_BASE_URL=http://localhost:5293   # simulador iOS
```

### Análise e testes

```bash
cd mobile
flutter analyze
flutter test
```

### Localização

Os textos estão em `mobile/lib/l10n/*.arb` (`app_pt.arb` é o template, `app_pt_PT.arb` a variante PT-PT).
Depois de alterar os ARB: `flutter gen-l10n`.

## Verificação

```bash
./.agent/verify.sh
```
