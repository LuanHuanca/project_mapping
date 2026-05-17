# Project Mapping

Aplicación de **projection mapping** para Windows: detecta objetos con Amazon Rekognition, asigna video por región (bounding box) y proyecta contenido alineado con calibración cámara→proyector.

## Estructura

```
Project_mapping/
  apps/mapper_desktop/     # Flutter Windows (UI + presentación)
  packages/mapper_core/    # Modelos, homografía, escenas
  packages/mapper_aws_api/ # Cliente HTTP → API Gateway
  packages/mapper_vision/  # Tracking local entre re-detecciones
  infra/                   # AWS CDK (serverless)
```

## Requisitos

- Flutter 3.38+ con soporte Windows
- Node.js 18+ y AWS CDK CLI (`npm install -g aws-cdk`)
- Cuenta AWS con permisos para Lambda, API Gateway, S3, DynamoDB, Rekognition

## Ejecutar la app

```bash
cd apps/mapper_desktop
flutter pub get
flutter run -d windows
```

### Modos

| Modo | Uso |
|------|-----|
| **Setup** | Editar regiones, calibrar, analizar con Rekognition, asignar videos |
| **Ensayo** | Vista con rejilla de depuración |
| **Show** | Salida limpia para presentación |

Atajos en Ensayo/Show: **Espacio** = re-sync tracking · **R** = re-analizar en AWS

## Configurar API AWS

Tras desplegar `infra/`:

1. Copia la URL del API Gateway del output de CDK.
2. Crea `%APPDATA%\...\api_config.json` o edita el archivo generado en soporte de la app:

```json
{
  "baseUrl": "https://xxxx.execute-api.us-east-1.amazonaws.com",
  "apiKey": "",
  "enabled": true
}
```

## Desplegar infraestructura

```bash
cd infra
npm install
npx cdk bootstrap   # una vez por cuenta/región
npx cdk deploy
```

## Subir a GitHub

```bash
git init
git branch -M main
git add .
git commit -m "Initial commit: projection mapping app"
git remote add origin https://github.com/TU_USUARIO/Project_mapping.git
git push -u origin main
```

## Licencia

MIT
