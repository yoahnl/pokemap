param(
  [Parameter(Mandatory = $true)][string]$Version,
  [Parameter(Mandatory = $true)][string]$BundleDir,
  [Parameter(Mandatory = $true)][string]$OutputDir,
  [Parameter(Mandatory = $true)][string]$PrivateKeyFile,
  [Parameter(Mandatory = $true)][string]$WinSparkleTool,
  [string]$InnoCompiler = "C:\Program Files (x86)\Inno Setup 6\ISCC.exe",
  [string]$Repository = "yoahnl/pokemap"
)

$ErrorActionPreference = "Stop"
$installerScript = Join-Path $PSScriptRoot "..\..\windows\installer\pokemap.iss"

foreach ($requiredPath in @($BundleDir, $PrivateKeyFile, $WinSparkleTool, $InnoCompiler, $installerScript)) {
  if (-not (Test-Path $requiredPath)) {
    throw "Required update packaging path is missing: $requiredPath"
  }
}
if (-not (Test-Path (Join-Path $BundleDir "PokeMap.exe"))) {
  throw "PokeMap.exe is missing from the Windows Release bundle."
}

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
& $InnoCompiler "/DAppVersion=$Version" "/DSourceDir=$BundleDir" "/DOutputDir=$OutputDir" $installerScript
if ($LASTEXITCODE -ne 0) {
  throw "ISCC.exe failed with exit code $LASTEXITCODE."
}

$installerName = "PokeMap-Editor-Setup-$Version.exe"
$installerPath = Join-Path $OutputDir $installerName
if (-not (Test-Path $installerPath)) {
  throw "Inno Setup did not produce $installerName."
}

$signatureOutput = & $WinSparkleTool sign --verbose --private-key-file $PrivateKeyFile $installerPath
if ($LASTEXITCODE -ne 0) {
  throw "winsparkle-tool failed with exit code $LASTEXITCODE."
}
$signatureText = $signatureOutput -join "`n"
$signatureMatch = [regex]::Match(
  $signatureText,
  'sparkle:edSignature="(?<signature>[A-Za-z0-9+/=]+)"\s+length="(?<length>\d+)"'
)
if (-not $signatureMatch.Success) {
  throw "winsparkle-tool did not return an EdDSA signature and length."
}

$actualLength = (Get-Item $installerPath).Length
if ([int64]$signatureMatch.Groups['length'].Value -ne $actualLength) {
  throw "WinSparkle signed length does not match the installer length."
}

$tag = "pokemap-v$Version"
$downloadUrl = "https://github.com/$Repository/releases/download/$tag/$installerName"
$signature = $signatureMatch.Groups['signature'].Value
$published = [DateTime]::UtcNow.ToString("R", [Globalization.CultureInfo]::InvariantCulture)
$appcast = @"
<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
  <channel>
    <title>PokeMap Editor Windows Updates</title>
    <language>fr</language>
    <item>
      <title>PokeMap Editor $Version</title>
      <pubDate>$published</pubDate>
      <sparkle:version>$Version</sparkle:version>
      <sparkle:shortVersionString>$Version</sparkle:shortVersionString>
      <enclosure url="$downloadUrl"
                 sparkle:os="windows-x64"
                 sparkle:installerArguments="/SILENT /SP-"
                 sparkle:edSignature="$signature"
                 length="$actualLength"
                 type="application/octet-stream" />
    </item>
  </channel>
</rss>
"@

$appcastPath = Join-Path $OutputDir "appcast-windows.xml"
Set-Content -Path $appcastPath -Value $appcast -Encoding utf8NoBOM
Write-Output $installerPath
Write-Output $appcastPath
