#!/usr/bin/env node
import 'source-map-support/register';
import * as cdk from 'aws-cdk-lib';
import { ProjectionMappingStack } from '../lib/projection-mapping-stack';

const app = new cdk.App();
new ProjectionMappingStack(app, 'ProjectionMappingStack', {
  env: {
    account: process.env.CDK_DEFAULT_ACCOUNT,
    region: process.env.CDK_DEFAULT_REGION ?? 'us-east-1',
  },
});
