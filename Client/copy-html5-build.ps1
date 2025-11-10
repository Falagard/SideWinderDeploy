# Post-build script
$sourceDir = "Export\html5\bin"
$destDir = "..\SideWinderDeployServer\static\client"
if (-Not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
Copy-Item -Path "$sourceDir\*" -Destination $destDir -Recurse -Force
Write-Host "Copied HTML5 build" -ForegroundColor Green
