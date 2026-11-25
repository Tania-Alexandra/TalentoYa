param(
    [Parameter(Mandatory = $true)]
    [string]$BackendBaseUrl,
    [string]$AwsRegion = $(if ($env:AWS_REGION) { $env:AWS_REGION } else { "us-east-1" }),
    [string]$EnvName = "dev"
)

$ErrorActionPreference = "Stop"
$RootDir = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$StackName = "talentoya-apigw-$EnvName"
$TemplateFile = Join-Path $RootDir "api-gateway\aws-apigw-template.yaml"

Write-Host "Desplegando Amazon API Gateway ($StackName) -> $BackendBaseUrl..." -ForegroundColor Cyan
aws cloudformation deploy `
    --region $AwsRegion `
    --stack-name $StackName `
    --template-file $TemplateFile `
    --parameter-overrides "EnvironmentName=$EnvName" "BackendBaseUrl=$BackendBaseUrl" `
    --no-fail-on-empty-changeset

$ApiGwUrl = aws cloudformation describe-stacks `
    --region $AwsRegion `
    --stack-name $StackName `
    --query "Stacks[0].Outputs[?OutputKey=='ApiGatewayUrl'].OutputValue" `
    --output text

Write-Host "`n=== Amazon API Gateway desplegado ===" -ForegroundColor Green
Write-Host "APIGW_URL=$ApiGwUrl"
