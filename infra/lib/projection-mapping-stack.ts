import * as cdk from 'aws-cdk-lib';
import * as apigwv2 from 'aws-cdk-lib/aws-apigatewayv2';
import * as apigwIntegrations from 'aws-cdk-lib/aws-apigatewayv2-integrations';
import * as dynamodb from 'aws-cdk-lib/aws-dynamodb';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import { NodejsFunction } from 'aws-cdk-lib/aws-lambda-nodejs';
import * as s3 from 'aws-cdk-lib/aws-s3';
import { Construct } from 'constructs';
import * as path from 'path';

export class ProjectionMappingStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    const mediaBucket = new s3.Bucket(this, 'MediaBucket', {
      blockPublicAccess: s3.BlockPublicAccess.BLOCK_ALL,
      encryption: s3.BucketEncryption.S3_MANAGED,
      removalPolicy: cdk.RemovalPolicy.DESTROY,
      autoDeleteObjects: true,
      cors: [
        {
          allowedMethods: [s3.HttpMethods.PUT, s3.HttpMethods.GET],
          allowedOrigins: ['*'],
          allowedHeaders: ['*'],
        },
      ],
    });

    const table = new dynamodb.Table(this, 'ScenesTable', {
      partitionKey: { name: 'pk', type: dynamodb.AttributeType.STRING },
      sortKey: { name: 'sk', type: dynamodb.AttributeType.STRING },
      billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
      removalPolicy: cdk.RemovalPolicy.DESTROY,
    });

    const lambdaEnv = {
      TABLE_NAME: table.tableName,
      MEDIA_BUCKET: mediaBucket.bucketName,
    };

    const analyzeFn = new NodejsFunction(this, 'AnalyzeFn', {
      entry: path.join(__dirname, '../lambda/analyze.ts'),
      handler: 'handler',
      runtime: lambda.Runtime.NODEJS_20_X,
      timeout: cdk.Duration.seconds(30),
      memorySize: 512,
      environment: lambdaEnv,
      bundling: { minify: true },
    });

    const scenesFn = new NodejsFunction(this, 'ScenesFn', {
      entry: path.join(__dirname, '../lambda/scenes.ts'),
      handler: 'handler',
      runtime: lambda.Runtime.NODEJS_20_X,
      timeout: cdk.Duration.seconds(15),
      environment: lambdaEnv,
      bundling: { minify: true },
    });

    const mediaFn = new NodejsFunction(this, 'MediaFn', {
      entry: path.join(__dirname, '../lambda/media.ts'),
      handler: 'handler',
      runtime: lambda.Runtime.NODEJS_20_X,
      timeout: cdk.Duration.seconds(10),
      environment: lambdaEnv,
      bundling: { minify: true },
    });

    table.grantReadWriteData(analyzeFn);
    table.grantReadWriteData(scenesFn);
    mediaBucket.grantReadWrite(analyzeFn);
    mediaBucket.grantReadWrite(scenesFn);
    mediaBucket.grantReadWrite(mediaFn);

    analyzeFn.addToRolePolicy(
      new iam.PolicyStatement({
        actions: ['rekognition:DetectLabels'],
        resources: ['*'],
      }),
    );

    const httpApi = new apigwv2.HttpApi(this, 'HttpApi', {
      corsPreflight: {
        allowHeaders: ['*'],
        allowMethods: [
          apigwv2.CorsHttpMethod.GET,
          apigwv2.CorsHttpMethod.PUT,
          apigwv2.CorsHttpMethod.POST,
          apigwv2.CorsHttpMethod.OPTIONS,
        ],
        allowOrigins: ['*'],
      },
    });

    httpApi.addRoutes({
      path: '/scenes/{sceneId}',
      methods: [apigwv2.HttpMethod.GET, apigwv2.HttpMethod.PUT],
      integration: new apigwIntegrations.HttpLambdaIntegration('ScenesIntegration', scenesFn),
    });

    httpApi.addRoutes({
      path: '/scenes/{sceneId}/capture/analyze',
      methods: [apigwv2.HttpMethod.POST],
      integration: new apigwIntegrations.HttpLambdaIntegration('AnalyzeIntegration', analyzeFn),
    });

    httpApi.addRoutes({
      path: '/scenes/{sceneId}/objects/{objectId}/content',
      methods: [apigwv2.HttpMethod.PUT],
      integration: new apigwIntegrations.HttpLambdaIntegration('ContentIntegration', scenesFn),
    });

    httpApi.addRoutes({
      path: '/media/presign',
      methods: [apigwv2.HttpMethod.POST],
      integration: new apigwIntegrations.HttpLambdaIntegration('MediaIntegration', mediaFn),
    });

    new cdk.CfnOutput(this, 'ApiUrl', {
      value: httpApi.apiEndpoint,
      description: 'Base URL for mapper_desktop api_config.json',
    });

    new cdk.CfnOutput(this, 'MediaBucketName', {
      value: mediaBucket.bucketName,
    });
  }
}
