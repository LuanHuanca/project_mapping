# Estructura del repositorio

```
Project_mapping/
├── apps/
│   └── mapper_desktop/          # App Flutter Windows
│       ├── lib/
│       │   ├── features/
│       │   │   ├── home/        # Shell + modos Setup/Ensayo/Show
│       │   │   ├── scene_editor/
│       │   │   ├── calibration/
│       │   │   └── presentation/
│       │   ├── providers/       # Riverpod (AppState, SceneStore)
│       │   ├── services/        # Config, cache, projection window
│       │   └── widgets/         # Bbox overlay, projection canvas
│       └── assets/config/
│           └── api_config.example.json
├── packages/
│   ├── mapper_core/             # Modelos + homografía + SceneStore
│   ├── mapper_aws_api/          # ProjectionMapperApi (Dio)
│   └── mapper_vision/           # BboxTracker
├── infra/                       # AWS CDK
│   ├── bin/app.ts
│   ├── lib/projection-mapping-stack.ts
│   └── lambda/                  # analyze, scenes, media
├── docs/                        # PLAN resumido (público en repo)
└── .cursor/                     # Contexto Cursor (este árbol)
    ├── docs/                    # Planeamiento detallado
    └── rules/                   # Reglas del agente
```

## Módulos Flutter (`mapper_desktop`)

| Módulo | Archivo clave | Función |
|--------|---------------|---------|
| Setup | `scene_editor_screen.dart` | Regiones, analyze AWS, asignar video |
| Calibración | `calibration_wizard.dart` | 4 puntos → homografía |
| Presentación | `presentation_screen.dart` | Compositor + atajos |
| Proyector | `projection_window_service.dart` | Fullscreen en monitor HDMI |
| Estado | `app_state.dart` | Modos, persistencia, API |

## Infra CDK

- Stack: `ProjectionMappingStack`
- Outputs: `ApiUrl`, `MediaBucketName`
- Despliegue: `cd infra && npm i && npx cdk deploy`

## Configuración runtime

- API: copiar `ApiUrl` → `api_config.json` en carpeta de soporte de la app (ver `config_service.dart`).
- No commitear `api_config.json` con keys reales (está en `.gitignore`).
