# PowerShell deployment script for AWS Data Pipeline

param(
    [Parameter(Mandatory=$true)]
    [string]$ParametersFile,
    
    [Parameter(Mandatory=$true)]
    [ValidateSet('dev','prod')]
    [string]$Environment
)

# Function to check if AWS CLI is installed and configured
function Test-AwsCli {
    try {
        $null = aws --version
        $null = aws sts get-caller-identity
        Write-Host "✅ AWS CLI is installed and configured" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "❌ AWS CLI is not installed or not configured properly" -ForegroundColor Red
        Write-Host "Please run 'aws configure' to set up your AWS credentials" -ForegroundColor Yellow
        return $false
    }
}

# Function to deploy a CloudFormation stack
function Deploy-Stack {
    param(
        [string]$StackName,
        [string]$TemplateFile,
        [string]$ParametersFile
    )
    
    Write-Host "Deploying stack: $StackName" -ForegroundColor Cyan
    
    try {
        # Check if stack exists
        $stackExists = aws cloudformation describe-stacks --stack-name $StackName 2>$null
        
        if ($stackExists) {
            Write-Host "Updating existing stack: $StackName" -ForegroundColor Yellow
            aws cloudformation update-stack `
                --stack-name $StackName `
                --template-body file://$TemplateFile `
                --parameters file://$ParametersFile `
                --capabilities CAPABILITY_NAMED_IAM
        }
        else {
            Write-Host "Creating new stack: $StackName" -ForegroundColor Green
            aws cloudformation create-stack `
                --stack-name $StackName `
                --template-body file://$TemplateFile `
                --parameters file://$ParametersFile `
                --capabilities CAPABILITY_NAMED_IAM
        }
        
        # Wait for stack creation/update to complete
        Write-Host "Waiting for stack operation to complete..." -ForegroundColor Cyan
        aws cloudformation wait stack-create-complete --stack-name $StackName
        
        Write-Host "✅ Stack $StackName deployed successfully" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Error deploying stack $StackName" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        exit 1
    }
}

# Main deployment script
Write-Host "Starting deployment for environment: $Environment" -ForegroundColor Cyan

# Check AWS CLI
if (-not (Test-AwsCli)) {
    exit 1
}

# Check if parameters file exists
if (-not (Test-Path $ParametersFile)) {
    Write-Host "❌ Parameters file not found: $ParametersFile" -ForegroundColor Red
    exit 1
}

# Deploy stacks in order
$stacks = @(
    @{
        Name = "data-pipeline-iam-$Environment"
        Template = ".\cfn\iam-roles.yaml"
    },
    @{
        Name = "data-pipeline-logging-$Environment"
        Template = ".\cfn\cloudwatch-logging.yaml"
    },
    @{
        Name = "data-pipeline-redshift-loader-$Environment"
        Template = ".\cfn\lambda-redshift-loader.yaml"
    },
    @{
        Name = "data-pipeline-main-$Environment"
        Template = ".\cfn\pipeline.yaml"
    }
)

foreach ($stack in $stacks) {
    Deploy-Stack -StackName $stack.Name -TemplateFile $stack.Template -ParametersFile $ParametersFile
}

Write-Host "✅ All stacks deployed successfully!" -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Create your Redshift table with the appropriate schema" -ForegroundColor Yellow
Write-Host "2. Upload a CSV file to the raw data bucket to test the pipeline" -ForegroundColor Yellow
Write-Host "3. Monitor the process in CloudWatch Logs" -ForegroundColor Yellow
