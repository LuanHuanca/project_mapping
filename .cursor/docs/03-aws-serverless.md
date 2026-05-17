# AWS Serverless

## Servicios usados

| Servicio | Uso |
|----------|-----|
| API Gateway HTTP API | Endpoints REST + CORS |
| Lambda (Node 20) | analyze, scenes, media |
| Amazon Rekognition | `DetectLabels` + bounding boxes |
| S3 | JPEG capturas, videos MP4 |
| DynamoDB | Escenas y metadatos (pk/sk) |
| (Fase 3) Cognito | Auth multi-usuario |
| (Fase 3) CloudFront | CDN para medios en venue |

## Endpoints MVP

| Método | Ruta | Lambda | Descripción |
|--------|------|--------|-------------|
| POST | `/scenes/{sceneId}/capture/analyze` | analyze | JPEG → Rekognition → lista objetos |
| GET | `/scenes/{sceneId}` | scenes | Hidratar escena |
| PUT | `/scenes/{sceneId}` | scenes | Guardar escena completa |
| PUT | `/scenes/{sceneId}/objects/{objectId}/content` | scenes | Binding video S3 |
| POST | `/media/presign` | media | URL firmada upload |

## Modelo DynamoDB (simplificado)

```
pk: SCENE#{sceneId}
sk: META          → payload JSON escena
sk: OBJECT#{id}   → s3Key, loop, etc.
```

## IAM / seguridad

- Bucket S3 privado, CORS para PUT desde app.
- Lambda analyze: `rekognition:DetectLabels` (recurso `*` en MVP interno).
- No commitear `.env`, `cdk.context.json`, ni `api_config.json` con secretos.

## Despliegue

```powershell
cd D:\Applications\Project_mapping\infra
npm install
npx cdk bootstrap    # una vez por cuenta/región
npx cdk deploy
```

Copiar output `ApiUrl` a configuración de la app.

## Coste (herramienta interna)

- Rekognition: por imagen analizada (calibraciones esporádicas = bajo).
- S3/Lambda/API/Dynamo: bajo en dev.
- Evitar Rekognition Video para tracking en vivo.

## Referencias

- [DetectLabels](https://docs.aws.amazon.com/rekognition/latest/dg/labels.html)
- Patrón serverless: API Gateway → Lambda → DynamoDB (AWS samples)
