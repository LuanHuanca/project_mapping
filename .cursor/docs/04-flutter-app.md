# App Flutter (Windows)

## Ejecutar

```powershell
cd D:\Applications\Project_mapping\apps\mapper_desktop
flutter pub get
flutter run -d windows
```

## Tres modos de UI

| Modo | Pantalla | Uso |
|------|----------|-----|
| **Setup** | `SceneEditorScreen` | Editar regiones, calibrar, analyze, videos |
| **Ensayo** | `PresentationScreen` + rejilla debug | Probar alineación antes del show |
| **Show** | `PresentationScreen` limpio | Solo contenido proyectado |

## Funcionalidades implementadas

- Dos regiones demo al iniciar; añadir más manualmente.
- Overlay de bounding boxes seleccionables.
- Asignar video local por objeto (`file_picker`).
- Wizard calibración 4 esquinas → homografía.
- `ProjectionCanvas`: compone color/video por `bboxProjector`.
- Ventana fullscreen proyector (`window_manager`).
- Caché JSON escena en `%AppData%` vía `CacheService`.
- Cliente API listo (`mapper_aws_api`) cuando `api_config` está activo.

## Pendiente en Flutter (prioridad)

1. **Webcam en vivo** en lugar del placeholder en scene editor.
2. Capturar frame real al pulsar “Analizar (Rekognition)”.
3. Sincronizar ventana fullscreen con estado Riverpod en tiempo real.
4. Compositor de video de alto rendimiento (FFmpeg / nativo) si hace falta 60 FPS.

## Dependencias clave

- `flutter_riverpod` — estado
- `window_manager` — fullscreen proyector
- `video_player` + `video_player_win` — preview por región
- `file_picker` — elegir MP4
- Paquetes locales `mapper_*`

## Atajos (Ensayo / Show)

- **Espacio** — re-sync tracking local
- **R** — re-analizar escena vía AWS (si API configurada)
