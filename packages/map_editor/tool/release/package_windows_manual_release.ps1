param(
  [Parameter(Mandatory = $true)][string]$Version,
  [Parameter(Mandatory = $true)][string]$BundleDir,
  [Parameter(Mandatory = $true)][string]$OutputDir,
  [string]$InnoCompiler = "C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
)

$ErrorActionPreference = "Stop"
$installerScript = Join-Path $PSScriptRoot "..\..\windows\installer\pokemap.iss"

foreach ($requiredPath in @($BundleDir, $InnoCompiler, $installerScript)) {
  if (-not (Test-Path $requiredPath)) {
    throw "Required manual packaging path is missing: $requiredPath"
  }
}
if (-not (Test-Path (Join-Path $BundleDir "PokeMap.exe"))) {
  throw "PokeMap.exe is missing from the Windows Release bundle."
}

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
$resolvedBundleDir = (Resolve-Path -LiteralPath $BundleDir).Path
$resolvedOutputDir = (Resolve-Path -LiteralPath $OutputDir).Path
& $InnoCompiler "/DAppVersion=$Version" "/DSourceDir=$resolvedBundleDir" "/DOutputDir=$resolvedOutputDir" $installerScript
if ($LASTEXITCODE -ne 0) {
  throw "ISCC.exe failed with exit code $LASTEXITCODE."
}

$installerName = "PokeMap-Editor-Setup-$Version.exe"
$installerPath = Join-Path $resolvedOutputDir $installerName
if (-not (Test-Path $installerPath)) {
  throw "Inno Setup did not produce $installerName."
}

Write-Output $installerPath
