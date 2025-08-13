# AWS Data Pipeline with Glue, S3, Lambda, and Redshift

This repository contains an AWS CloudFormation infrastructure as code (IaC) for a complete data pipeline that:
1. Ingests CSV data from S3
2. Processes it using AWS Glue to Parquet format
3. Automatically loads processed data into Redshift using Lambda

## Prerequisites

1. AWS Account with appropriate permissions
2. AWS CLI installed and configured
3. AWS credentials with permissions for:
   - IAM
   - S3
   - AWS Glue
   - Lambda
   - CloudWatch
   - Redshift
   - CloudFormation

## Repository Structure

```
├── cfn/                            # CloudFormation templates
│   ├── cloudwatch-logging.yaml     # Logging configuration
│   ├── iam-roles.yaml             # IAM roles and policies
│   ├── lambda-redshift-loader.yaml # Lambda function for Redshift loading
│   ├── pipeline.yaml              # Main pipeline infrastructure
│   └── step-functions-orchestration.yaml
├── glue/
│   └── scripts/
│       └── data_processing.py      # Glue ETL job script
└── deploy/
    └── deploy.ps1                  # Deployment PowerShell script
```

## Configuration

Create a `parameters.json` file in the root directory with your configuration:

```json
{
    "Environment": "dev",
    "S3Bucket": "your-bucket-name",
    "RedshiftClusterEndpoint": "your-cluster-endpoint",
    "RedshiftDBName": "your-database",
    "RedshiftTableName": "your-table",
    "RedshiftUsername": "your-username",
    "RedshiftPassword": "your-password"
}
```

## Deployment

1. First, make sure you have AWS CLI configured:
```powershell
aws configure
```

2. Run the deployment script:
```powershell
./deploy/deploy.ps1 -ParametersFile parameters.json -Environment dev
```

The script will deploy the CloudFormation stacks in the correct order:
1. IAM roles
2. CloudWatch logging
3. Lambda Redshift loader
4. Main pipeline

## Redshift Table Setup

Before using the pipeline, ensure your Redshift table is created with the appropriate schema. Example:

```sql
CREATE TABLE your_table (
    -- Add your columns here matching the CSV/Parquet structure
    column1 VARCHAR(255),
    column2 INTEGER,
    ...
);
```

## Monitoring

- CloudWatch Logs will contain logs from:
  - Glue jobs
  - Lambda function
  - Step Functions
- Check the S3 buckets for:
  - Raw data: `{S3Bucket}-raw-{Environment}-{AccountId}`
  - Processed data: `{S3Bucket}-processed-{Environment}-{AccountId}`

## Security

- All S3 buckets are encrypted using AES-256
- IAM roles follow least privilege principle
- Redshift credentials are stored securely
- Lambda functions run in their own VPC (if configured)

## Troubleshooting

1. Check CloudWatch Logs for:
   - `/aws/glue/jobs/{GlueJobName}-{Environment}`
   - `/aws/lambda/redshift-loader-{Environment}`

2. Common issues:
   - IAM permissions
   - S3 bucket names must be globally unique
   - Redshift connection issues
   - Schema mismatches between Parquet files and Redshift table
