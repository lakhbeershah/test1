# GitHub Secrets Configuration

This document explains the GitHub Secrets required for the AWS Data Pipeline deployment workflow and how to configure OIDC authentication with AWS.

## Required GitHub Secrets

The following secrets must be configured in your GitHub repository under `Settings > Secrets and variables > Actions`:

| Secret Name | Description | Example Value |
|-------------|-------------|---------------|
| `AWS_REGION` | AWS region for deployment | `us-east-1` |
| `DEV_ACCOUNT_ID` | AWS Account ID for development environment | `123456789012` |
| `PROD_ACCOUNT_ID` | AWS Account ID for production environment | `987654321098` |
| `S3_BUCKET` | S3 bucket name for CloudFormation artifacts | `my-company-cfn-artifacts` |

## AWS IAM Role Configuration for OIDC

To enable OIDC authentication between GitHub Actions and AWS, you need to create IAM roles in your AWS accounts with the appropriate trust policies.

### Trust Policy for Development Account

Create the following trust policy for your development account IAM role:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::<DEV_ACCOUNT_ID>:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:<YOUR_GITHUB_USERNAME>/<YOUR_REPO_NAME>:ref:refs/heads/develop"
        }
      }
    }
  ]
}
```

### Trust Policy for Production Account

Create the following trust policy for your production account IAM role:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::<PROD_ACCOUNT_ID>:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:<YOUR_GITHUB_USERNAME>/<YOUR_REPO_NAME>:ref:refs/heads/main"
        }
      }
    }
  ]
}
```

## IAM Policy for GitHub Actions Role

Attach the following policy to both the development and production IAM roles to grant necessary permissions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      "Resource": [
        "arn:aws:s3:::<S3_BUCKET>",
        "arn:aws:s3:::<S3_BUCKET>/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "cloudformation:CreateStack",
        "cloudformation:UpdateStack",
        "cloudformation:DeleteStack",
        "cloudformation:DescribeStacks",
        "cloudformation:DescribeStackEvents",
        "cloudformation:ValidateTemplate",
        "cloudformation:CreateChangeSet",
        "cloudformation:DescribeChangeSet",
        "cloudformation:ExecuteChangeSet",
        "cloudformation:DeleteChangeSet"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "iam:PassRole"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "iam:PassedToService": "glue.amazonaws.com"
        }
      }
    }
  ]
}
```

## GitHub Environment Configuration

The workflow uses GitHub Environments for deployment:

1. Create a `dev` environment in your GitHub repository
2. Create a `prod` environment in your GitHub repository
3. Configure environment protection rules as needed

## Workflow Triggers

The deployment workflow is triggered by:

1. Pushes to `main` branch (deploys to production)
2. Pushes to `develop` branch (deploys to development)
3. Manual workflow dispatch with environment selection

## Directory Structure

Ensure your repository follows this structure:

```
├── .github/
│   └── workflows/
│       └── deploy.yml
├── cfn/
│   └── pipeline.yaml
├── glue/
│   └── scripts/
│       └── data_processing.py
└── docs/
    └── github-secrets.md
```

## Deployment Process

1. Glue scripts are uploaded to S3
2. CloudFormation template is packaged and uploaded to S3
3. CloudFormation stack is deployed or updated
4. Stack outputs are displayed in the workflow logs

For more information about the AWS resources created, see the CloudFormation template at `cfn/pipeline.yaml`.