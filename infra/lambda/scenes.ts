import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, GetCommand, PutCommand } from '@aws-sdk/lib-dynamodb';
import { APIGatewayProxyHandlerV2 } from 'aws-lambda';

const doc = DynamoDBDocumentClient.from(new DynamoDBClient({}));
const table = process.env.TABLE_NAME!;

export const handler: APIGatewayProxyHandlerV2 = async (event) => {
  const sceneId = event.pathParameters?.sceneId;
  const method = event.requestContext.http.method;
  const path = event.rawPath ?? '';

  if (path.includes('/objects/') && method === 'PUT') {
    const objectId = event.pathParameters?.objectId;
    const body = event.body ? JSON.parse(event.body) : {};
    await doc.send(
      new PutCommand({
        TableName: table,
        Item: {
          pk: `SCENE#${sceneId}`,
          sk: `OBJECT#${objectId}`,
          s3Key: body.s3Key,
          loop: body.loop ?? true,
          updatedAt: new Date().toISOString(),
        },
      }),
    );
    return { statusCode: 200, body: JSON.stringify({ ok: true }) };
  }

  if (method === 'GET' && sceneId) {
    const res = await doc.send(
      new GetCommand({
        TableName: table,
        Key: { pk: `SCENE#${sceneId}`, sk: 'META' },
      }),
    );
    if (!res.Item) {
      return {
        statusCode: 200,
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify({
          id: sceneId,
          name: 'Escena',
          projectId: 'default',
          objects: [],
          calibration: { isComplete: false },
        }),
      };
    }
    return {
      statusCode: 200,
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify(res.Item.payload),
    };
  }

  if (method === 'PUT' && sceneId) {
    const payload = event.body ? JSON.parse(event.body) : {};
    await doc.send(
      new PutCommand({
        TableName: table,
        Item: {
          pk: `SCENE#${sceneId}`,
          sk: 'META',
          payload,
          updatedAt: new Date().toISOString(),
        },
      }),
    );
    return { statusCode: 200, body: JSON.stringify({ ok: true }) };
  }

  return { statusCode: 404, body: JSON.stringify({ error: 'Not found' }) };
};
