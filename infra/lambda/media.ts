import { PutObjectCommand, S3Client } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { APIGatewayProxyHandlerV2 } from 'aws-lambda';

const s3 = new S3Client({});
const bucket = process.env.MEDIA_BUCKET!;

export const handler: APIGatewayProxyHandlerV2 = async (event) => {
  const body = event.body ? JSON.parse(event.body) : {};
  const filename = (body.filename as string) ?? `upload-${Date.now()}.mp4`;
  const contentType = (body.contentType as string) ?? 'video/mp4';
  const key = `media/${filename}`;

  const command = new PutObjectCommand({
    Bucket: bucket,
    Key: key,
    ContentType: contentType,
  });

  const uploadUrl = await getSignedUrl(s3, command, { expiresIn: 900 });

  return {
    statusCode: 200,
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ uploadUrl, s3Key: key }),
  };
};
