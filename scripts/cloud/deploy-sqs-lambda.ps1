param(
    [string]$AwsRegion = $(if ($env:AWS_REGION) { $env:AWS_REGION } else { "us-east-1" }),
    [string]$EnvName = "dev",
    [string]$PostulacionesApiUrl = "",
    [string]$NotificacionesApiUrl = "",
    [string]$ApiGatewayKey = $(if ($env:GATEWAY_API_KEY) { $env:GATEWAY_API_KEY } else { "talentoya-secret-key-2026" })
)

$ErrorActionPreference = "Stop"
$RootDir = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$LambdaDir = Join-Path $RootDir "serverless\procesador-postulaciones"
$JarPath = Join-Path $LambdaDir "target\procesador-postulaciones-1.0.0.jar"

$DlqName = "talentoya-postulaciones-dlq-$EnvName"
$QueueName = "talentoya-postulaciones-queue-$EnvName"
$LambdaName = "talentoya-procesador-postulaciones-$EnvName"
$RoleName = "talentoya-lambda-sqs-role-$EnvName"

Write-Host "1. Compilando y empaquetando funcion Lambda Java 21..." -ForegroundColor Cyan
mvn -B -f (Join-Path $LambdaDir "pom.xml") clean package

Write-Host "2. Creando Dead Letter Queue ($DlqName)..." -ForegroundColor Cyan
$DlqUrl = aws sqs create-queue --region $AwsRegion --queue-name $DlqName --query "QueueUrl" --output text
$DlqArn = aws sqs get-queue-attributes --region $AwsRegion --queue-url $DlqUrl --attribute-names QueueArn --query "Attributes.QueueArn" --output text

Write-Host "3. Creando cola SQS principal ($QueueName) con RedrivePolicy..." -ForegroundColor Cyan
$AttrsFile = [System.IO.Path]::GetTempFileName()
@{
    VisibilityTimeout = "60"
    MessageRetentionPeriod = "345600"
    RedrivePolicy = (@{ deadLetterTargetArn = $DlqArn; maxReceiveCount = "3" } | ConvertTo-Json -Compress)
} | ConvertTo-Json -Compress | Set-Content -Path $AttrsFile -Encoding Ascii

$QueueUrl = aws sqs create-queue --region $AwsRegion --queue-name $QueueName --attributes "file://$AttrsFile" --query "QueueUrl" --output text
Remove-Item $AttrsFile -Force
$QueueArn = aws sqs get-queue-attributes --region $AwsRegion --queue-url $QueueUrl --attribute-names QueueArn --query "Attributes.QueueArn" --output text

Write-Host "4. Verificando/creando rol IAM ($RoleName)..." -ForegroundColor Cyan
$roleExists = $true
try { aws iam get-role --role-name $RoleName *> $null } catch { $roleExists = $false }
if (-not $roleExists) {
    $TrustFile = [System.IO.Path]::GetTempFileName()
    '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' | Set-Content -Path $TrustFile -Encoding Ascii
    aws iam create-role --role-name $RoleName --assume-role-policy-document "file://$TrustFile" | Out-Null
    Remove-Item $TrustFile -Force
    aws iam attach-role-policy --role-name $RoleName --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole
    Start-Sleep -Seconds 10
}
$RoleArn = aws iam get-role --role-name $RoleName --query "Role.Arn" --output text

$EnvJson = (@{ Variables = @{ POSTULACIONES_API_URL = $PostulacionesApiUrl; NOTIFICACIONES_API_URL = $NotificacionesApiUrl; API_GATEWAY_KEY = $ApiGatewayKey } } | ConvertTo-Json -Compress)
$EnvFile = [System.IO.Path]::GetTempFileName()
$EnvJson | Set-Content -Path $EnvFile -Encoding Ascii

Write-Host "5. Desplegando funcion Lambda ($LambdaName)..." -ForegroundColor Cyan
$fnExists = $true
try { aws lambda get-function --region $AwsRegion --function-name $LambdaName *> $null } catch { $fnExists = $false }
if ($fnExists) {
    aws lambda update-function-code --region $AwsRegion --function-name $LambdaName --zip-file "fileb://$JarPath" | Out-Null
    aws lambda wait function-updated --region $AwsRegion --function-name $LambdaName
    aws lambda update-function-configuration --region $AwsRegion --function-name $LambdaName --environment "file://$EnvFile" | Out-Null
} else {
    aws lambda create-function `
        --region $AwsRegion `
        --function-name $LambdaName `
        --runtime java21 `
        --role $RoleArn `
        --handler cl.duoc.jv0101.caso02.lambda.ProcesadorPostulacionesHandler::handleRequest `
        --zip-file "fileb://$JarPath" `
        --timeout 30 `
        --memory-size 512 `
        --environment "file://$EnvFile" | Out-Null
}
Remove-Item $EnvFile -Force

Write-Host "6. Conectando trigger SQS -> Lambda..." -ForegroundColor Cyan
$ExistingUuid = aws lambda list-event-source-mappings --region $AwsRegion --function-name $LambdaName --event-source-arn $QueueArn --query "EventSourceMappings[0].UUID" --output text
if (-not $ExistingUuid -or $ExistingUuid -eq "None") {
    aws lambda create-event-source-mapping `
        --region $AwsRegion `
        --function-name $LambdaName `
        --event-source-arn $QueueArn `
        --batch-size 10 `
        --function-response-types ReportBatchItemFailures | Out-Null
}

Write-Host "`n=== Despliegue Cloud completado ===" -ForegroundColor Green
Write-Host "AWS_SQS_ENABLED=true"
Write-Host "AWS_REGION=$AwsRegion"
Write-Host "AWS_SQS_QUEUE_URL=$QueueUrl"
Write-Host "DLQ_URL=$DlqUrl"
Write-Host "LAMBDA_NAME=$LambdaName"
