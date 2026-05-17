# Rekognition y tracking híbrido

## Verdad sobre Rekognition

`DetectLabels` **sí devuelve bounding boxes**, pero:

- Pensado para **una imagen**, no 30 FPS en vivo.
- Latencia: cientos de ms – varios segundos.
- Cajas **inestables** frame a frame.
- Labels genéricos (“Table”, “Box”) pueden no coincidir con tus props.

## Patrón híbrido (decisión del proyecto)

| Fase | Dónde | Qué hace |
|------|-------|----------|
| Descubrimiento | AWS Rekognition | Foto → objetos + boxes + confidence |
| Edición | Flutter Setup | Usuario confirma/edita cajas, asigna video |
| Presentación | Local `mapper_vision` | `BboxTracker` entre re-detecciones |
| Re-sync | AWS bajo demanda | Botón analyze, tecla **R**, o timer 10–30 s |

## Implementación actual (`BboxTracker`)

- Suavizado de velocidad al re-sync desde nuevas detecciones.
- `tick()` cada ~50 ms en modo presentación.
- No usa OpenCV aún — mejorar en fase 2.

## Cuándo usar Custom Labels (fase 3)

Si tus objetos son muy específicos (producto X, caja Y):

- Entrenar modelo con fotos de tus props.
- `DetectCustomLabels` en lugar de labels genéricos.

## Calibración obligatoria

Rekognition opera en **espacio cámara**. El proyector usa otro sistema.

1. Proyectar rectángulo de referencia.
2. Marcar 4 esquinas en vista cámara.
3. Calcular homografía (`mapper_core`).
4. Aplicar a todos los `SceneObject.bboxProjector`.

Sin esto, el contenido no alinea con objetos físicos.
