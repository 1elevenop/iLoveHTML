# Builds the prebuilt wrapper base APK used by the on-device engine and
# records where its icon lives. Run on a desktop with the Android SDK.
# This compiles the converter's own runtime, never a user's project.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$template = Join-Path $root 'android_template'
$dest = Join-Path $root 'android_ondevice_prototype\app\src\main\assets'
$sdk = if ($env:ANDROID_HOME) { $env:ANDROID_HOME } else { Join-Path $env:LOCALAPPDATA 'Android\Sdk' }
if (-not $env:JAVA_HOME) { $env:JAVA_HOME = 'C:\Program Files\Android\Android Studio\jbr' }

Push-Location $template
try { & .\gradlew.bat assembleRelease --no-daemon --console=plain -q; if ($LASTEXITCODE) { throw 'Gradle failed' } }
finally { Pop-Location }

$apk = Join-Path $template 'app\build\outputs\apk\release\app-release-unsigned.apk'
$bt = Get-ChildItem (Join-Path $sdk 'build-tools') | Sort-Object { [version]($_.Name -replace '-.*','') } | Select-Object -Last 1
$dump = & (Join-Path $bt.FullName 'aapt2.exe') dump resources $apk
$i = [array]::FindIndex([string[]]$dump, [Predicate[string]]{ param($l) $l -match 'drawable/app_icon$' })
if ($i -lt 0) { throw 'drawable/app_icon not found in base APK' }
$entry = ([regex]::Match($dump[$i + 1], '\(file\) (\S+)')).Groups[1].Value
if (-not $entry.EndsWith('.png')) { throw "Icon entry is not a PNG: $entry" }
$pkg = ([regex]::Match(($dump | Select-Object -First 3) -join "`n", 'Package name=(\S+)')).Groups[1].Value

New-Item -ItemType Directory -Force (Join-Path $dest 'base') | Out-Null
Copy-Item $apk (Join-Path $dest 'base\base.apk')
@{ basePackage = $pkg; iconEntry = $entry } | ConvertTo-Json | Set-Content (Join-Path $dest 'base\base_info.json')
Write-Output "Base: $((Get-Item $apk).Length) bytes, package $pkg, icon $entry"
