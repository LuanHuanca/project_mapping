# Idea principal — Project Mapping

## En una frase

App de **projection mapping interactivo** en Windows: la cámara ve lo que ilumina el proyector, **Amazon Rekognition** detecta objetos con cajas (bounding boxes), tú asignas un **video o tema por objeto**, y la app proyecta ese contenido **solo dentro de cada región**, alineada con calibración cámara→proyector.

## No es esto

- No es un gestor de proyectos tipo Jira/Notion.
- No es un mind map genérico.
- No es AR en el móvil sin proyector.

## Sí es esto

- **Instalación física:** mesa, escena, objetos reales, proyector HDMI, webcam.
- **Contenido por objeto:** cada caja detectada puede llevar su video, color o playlist.
- **Modo híbrido:** Rekognition en calibración / re-sync + **tracking local** entre análisis (porque Rekognition no va a 30 FPS).

## Usuario objetivo (fase actual)

- **Herramienta interna:** tú y tu equipo, presentaciones y experimentos.
- Más adelante: equipos con Cognito, workspaces, Custom Labels.

## Stack elegido

| Capa | Tecnología |
|------|------------|
| Cliente | Flutter Desktop **Windows** |
| Backend | **AWS serverless** (API Gateway, Lambda, S3, DynamoDB, Rekognition) |
| IaC | **AWS CDK** (TypeScript) en `infra/` |
| Repo | https://github.com/LuanHuanca/project_mapping |
| Ruta local | `D:\Applications\Project_mapping` |

## Valor de la app

1. Montar una demo visual impactante en minutos (regiones + video).
2. Reutilizar servicios AWS que ya conoces.
3. Escalar a detección en la nube sin reescribir la UI.
4. Presentaciones “grandiosas” con modo Show limpio.

## Decisiones de producto ya tomadas

- Plataforma host: **PC Windows** + proyector + webcam (no solo tablet).
- Detección: **DetectLabels** (MVP); Custom Labels en fase 3.
- Sincronización: **híbrida** (calibrar + re-detectar manual o cada N segundos + tracker local).
- Git remoto: `git@github-personal:LuanHuanca/project_mapping.git`
