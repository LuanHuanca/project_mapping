import { DetectLabelsCommand, RekognitionClient } from '@aws-sdk/client-rekognition';
import { PutObjectCommand, S3Client } from '@aws-sdk/client-s3';
import { APIGatewayProxyHandlerV2 } from 'aws-lambda';

const rekognition = new RekognitionClient({});
const s3 = new S3Client({});
const bucket = process.env.MEDIA_BUCKET!;

export const handler: APIGatewayProxyHandlerV2 = async (event) => {
  const sceneId = event.pathParameters?.sceneId;
  if (!sceneId) {
    return { statusCode: 400, body: JSON.stringify({ error: 'sceneId required' }) };
  }

  const body = event.body
    ? Buffer.from(event.body, event.isBase64Encoded ? 'base64' : 'utf8')
    : Buffer.alloc(0);

  if (body.length < 100) {
    return {
      statusCode: 200,
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({
        sceneId,
        imageS3Key: null,
        objects: demoObjects(),
      }),
    };
  }

  const key = `captures/${sceneId}/${Date.now()}.jpg`;
  await s3.send(
    new PutObjectCommand({
      Bucket: bucket,
      Key: key,
      Body: body,
      ContentType: 'image/jpeg',
    }),
  );

  const labels = await rekognition.send(
    new DetectLabelsCommand({
      Image: { S3Object: { Bucket: bucket, Name: key } },
      MaxLabels: 20,
      MinConfidence: 70,
    }),
  );

  const objects =
    labels.Labels?.flatMap((label) => {
      const instances = label.Instances ?? [];
      if (instances.length === 0) {
        return [];
      }
      return instances.map((inst, idx) => ({
        label: `${label.Name} ${idx + 1}`,
        rekognitionLabel: label.Name,
        confidence: inst.Confidence ?? label.Confidence ?? 0,
        bbox: {
          left: inst.BoundingBox?.Left ?? 0,
          top: inst.BoundingBox?.Top ?? 0,
          width: inst.BoundingBox?.Width ?? 0.2,
          height: inst.BoundingBox?.Height ?? 0.2,
        },
      }));
    }) ?? [];

  return {
    statusCode: 200,
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({
      sceneId,
      imageS3Key: key,
      objects: objects.length > 0 ? objects : demoObjects(),
    }),
  };
};

function demoObjects() {
  return [
    {
      label: 'Objeto izquierda',
      rekognitionLabel: 'Demo',
      confidence: 99,
      bbox: { left: 0.12, top: 0.2, width: 0.28, height: 0.35 },
    },
    {
      label: 'Objeto derecha',
      rekognitionLabel: 'Demo',
      confidence: 99,
      bbox: { left: 0.55, top: 0.22, width: 0.3, height: 0.38 },
    },
  ];
}
