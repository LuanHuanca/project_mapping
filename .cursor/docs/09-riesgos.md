# Riesgos y mitigaciones

| Riesgo | Impacto | Mitigación |
|--------|---------|------------|
| Latencia Rekognition en vivo | Tracking inútil si solo nube | Modo híbrido; analyze solo en calibración/re-sync |
| Labels incorrectos | Video en objeto equivocado | Edición manual UI; Custom Labels fase 3 |
| Luz ambiente variable | Detección inconsistente | Re-sync manual; iluminación controlada; umbral confidence |
| Sin calibración homografía | Desalineación visual | Wizard obligatorio antes de Show |
| Flutter no compone 60 FPS solo | Stutter en video | Plugin nativo / FFmpeg en fase 2 |
| Workspace Cursor equivocado | Agente “pierde” contexto | Abrir `D:\Applications\Project_mapping`; reglas en `.cursor/rules` |
| Secretos en git | Filtración API keys | `.gitignore`: `.env`, `api_config.json`, `cdk.context.json` |
| Dos carpetas proyecto | Confusión | Solo trabajar en ruta canónica; ver `00-idea-principal.md` |

## Deuda técnica conocida (código actual)

- Placeholder “vista cámara” sin stream real.
- JPEG mínimo en analyze si no hay frame.
- Ventana proyector no recibe stream Riverpod compartido (subventana estática).
- Tracker por velocidad, no por visión computer real.
