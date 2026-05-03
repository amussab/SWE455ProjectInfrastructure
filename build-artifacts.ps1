$ErrorActionPreference = "Stop"

$infraDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Resolve-Path (Join-Path $infraDir "..\..")
$uploadServiceDir = Join-Path $projectRoot "upload-service"
$validatorServiceDir = Join-Path $projectRoot "validator-service"
$buildDir = Join-Path $infraDir ".build"
$uploadBuildDir = Join-Path $buildDir "upload"
$validatorBuildDir = Join-Path $buildDir "validator"

function Remove-DirectorySafely($path) {
    if (-not (Test-Path -LiteralPath $path)) {
        return
    }

    $resolvedPath = Resolve-Path -LiteralPath $path
    $resolvedBuildDir = Resolve-Path -LiteralPath $buildDir -ErrorAction SilentlyContinue

    if ($null -eq $resolvedBuildDir -or -not $resolvedPath.Path.StartsWith($resolvedBuildDir.Path)) {
        throw "Refusing to delete path outside build directory: $resolvedPath"
    }

    Remove-Item -LiteralPath $resolvedPath.Path -Recurse -Force
}

if (-not (Test-Path -LiteralPath $buildDir)) {
    New-Item -ItemType Directory -Path $buildDir | Out-Null
}

Remove-DirectorySafely $uploadBuildDir
Remove-DirectorySafely $validatorBuildDir

New-Item -ItemType Directory -Path $uploadBuildDir | Out-Null
New-Item -ItemType Directory -Path $validatorBuildDir | Out-Null

Copy-Item -Path (Join-Path $uploadServiceDir "index.py") -Destination $uploadBuildDir

Copy-Item -Path (Join-Path $validatorServiceDir "index.py") -Destination $validatorBuildDir
Copy-Item -Path (Join-Path $validatorServiceDir "validation.py") -Destination $validatorBuildDir

$uploadZip = Join-Path $infraDir "upload.zip"
$validatorZip = Join-Path $infraDir "validator.zip"

if (Test-Path -LiteralPath $uploadZip) {
    Remove-Item -LiteralPath $uploadZip -Force
}

if (Test-Path -LiteralPath $validatorZip) {
    Remove-Item -LiteralPath $validatorZip -Force
}

Compress-Archive -Path (Join-Path $uploadBuildDir "*") -DestinationPath $uploadZip -Force
Compress-Archive -Path (Join-Path $validatorBuildDir "*") -DestinationPath $validatorZip -Force

Write-Host "Created $uploadZip"
Write-Host "Created $validatorZip"
