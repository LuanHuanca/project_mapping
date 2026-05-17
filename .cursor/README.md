# Contexto Cursor — Project Mapping

Esta carpeta guarda **todo el planeamiento** del proyecto para que cualquier chat de Cursor en este workspace recupere el contexto sin depender de conversaciones antiguas.

## Índice de documentos

| Archivo | Contenido |
|---------|-----------|
| [docs/00-idea-principal.md](docs/00-idea-principal.md) | Visión, problema, solución, usuario objetivo |
| [docs/01-arquitectura.md](docs/01-arquitectura.md) | Diagrama edge + AWS, flujos de datos |
| [docs/02-estructura-repo.md](docs/02-estructura-repo.md) | Carpetas, paquetes, módulos Flutter |
| [docs/03-aws-serverless.md](docs/03-aws-serverless.md) | CDK, API, DynamoDB, S3, Rekognition |
| [docs/04-flutter-app.md](docs/04-flutter-app.md) | Modos UI, calibración, proyección |
| [docs/05-rekognition-tracking.md](docs/05-rekognition-tracking.md) | Modo híbrido, límites, tracking local |
| [docs/06-roadmap.md](docs/06-roadmap.md) | Fases 0–3, estado actual, criterios de éxito |
| [docs/07-presentaciones.md](docs/07-presentaciones.md) | Setup, Ensayo, Show, demos |
| [docs/08-proximos-pasos.md](docs/08-proximos-pasos.md) | Qué hacer ahora (orden práctico) |
| [docs/09-riesgos.md](docs/09-riesgos.md) | Riesgos y mitigaciones |
| [rules/project-mapping.mdc](rules/project-mapping.mdc) | Regla always-on para el agente |

## Uso en el chat

```
@.cursor/docs/00-idea-principal.md @.cursor/docs/08-proximos-pasos.md
```

O simplemente abre esta carpeta como workspace: las reglas en `rules/` se aplican solas.

## Qué va a Git y qué no

- **Sí se sube:** `rules/`, `docs/`, este README.
- **No se sube:** planes locales, caché, sesiones (ver `.gitignore`).
