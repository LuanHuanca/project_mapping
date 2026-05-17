# Próximos pasos (orden práctico)

## Esta semana

1. **Abrir workspace correcto en Cursor**  
   `File → Open Folder` → `D:\Applications\Project_mapping`

2. **Probar app**
   ```powershell
   cd apps\mapper_desktop
   flutter pub get
   flutter run -d windows
   ```

3. **Probar con hardware**  
   Proyector + webcam; calibración; videos locales; fullscreen.

## Siguiente bloque técnico

4. **Desplegar AWS**
   ```powershell
   cd infra
   npm install
   npx cdk deploy
   ```
   Configurar `api_config.json` con `ApiUrl`.

5. **Webcam + captura real**  
   Integrar plugin `camera` / `camera_windows` en `scene_editor_screen.dart`.  
   En analyze, enviar JPEG del frame actual (no placeholder).

6. **Mejorar tracking**  
   Evaluar OpenCV vía FFI o paquete Dart; sustituir lógica simple en `BboxTracker`.

## Git / Cursor

7. Commitear cambios de `.cursor/docs` y reglas cuando estés listo.
8. En chats nuevos: `@.cursor/README.md` o confiar en `rules/project-mapping.mdc`.

## Carpeta obsoleta

- **No usar** `C:\Users\Luan\Projects\projection-mapper` (vacía).
- **Canónica:** `D:\Applications\Project_mapping` + GitHub `LuanHuanca/project_mapping`.

## Cursor SDK (desarrollo, opcional)

Acelerar CDK/refactors desde scripts locales con `@cursor/sdk` y `local: { cwd: "D:/Applications/Project_mapping" }` — no reemplaza el runtime de la app en show.
