# AGENTS.md — Project Mapping

Instrucciones para agentes de código (Cursor, Codex, etc.).

## Contexto

Lee primero [`.cursor/README.md`](.cursor/README.md) y la regla [`.cursor/rules/project-mapping.mdc`](.cursor/rules/project-mapping.mdc).

## Comandos útiles

```powershell
# App
cd apps/mapper_desktop && flutter pub get && flutter run -d windows

# Infra
cd infra && npm install && npx cdk deploy

# Tests core
cd packages/mapper_core && dart test
```

## No tocar

- Secretos en git (ver `.gitignore`)
- Carpeta obsoleta `C:\Users\Luan\Projects\projection-mapper`
