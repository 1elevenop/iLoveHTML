# Builds the prebuilt wrapper base APK and base App Bundle used by the
# on-device engine and records where the APK's icon lives. Run on a desktop with the Android SDK.
# This compiles the converter's own runtime, never a user's project.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$template = Join-Path $root 'android_template'
# Every app that embeds the on-device engine gets a copy.
$destinations = @(
    (Join-Path $root 'app\android\app\src\main\assets'),
    (Join-Path $root 'android_ondevice_prototype\app\src\main\assets')
)
$sdk = if ($env:ANDROID_HOME) { $env:ANDROID_HOME } else { Join-Path $env:LOCALAPPDATA 'Android\Sdk' }
if (-not $env:JAVA_HOME) { $env:JAVA_HOME = 'C:\Program Files\Android\Android Studio\jbr' }

Push-Location $template
try { & .\gradlew.bat assembleRelease bundleRelease --no-daemon --console=plain -q; if ($LASTEXITCODE) { throw 'Gradle failed' } }
finally { Pop-Location }

$apk = Join-Path $template 'app\build\outputs\apk\release\app-release-unsigned.apk'
# Unsigned: no signing environment is set for this build.
$aab = Join-Path $template 'app\build\outputs\bundle\release\app-release.aab'
$bt = Get-ChildItem (Join-Path $sdk 'build-tools') | Sort-Object { [version]($_.Name -replace '-.*','') } | Select-Object -Last 1
$dump = & (Join-Path $bt.FullName 'aapt2.exe') dump resources $apk
$i = [array]::FindIndex([string[]]$dump, [Predicate[string]]{ param($l) $l -match 'drawable/app_icon$' })
if ($i -lt 0) { throw 'drawable/app_icon not found in base APK' }
$entry = ([regex]::Match($dump[$i + 1], '\(file\) (\S+)')).Groups[1].Value
if (-not $entry.EndsWith('.png')) { throw "Icon entry is not a PNG: $entry" }
$b = [array]::FindIndex([string[]]$dump, [Predicate[string]]{ param($l) $l -match 'drawable/app_banner$' })
if ($b -lt 0) { throw 'drawable/app_banner not found in base APK' }
$banner = ([regex]::Match($dump[$b + 1], '\(file\) (\S+)')).Groups[1].Value
if (-not $banner.EndsWith('.png')) { throw "Banner entry is not a PNG: $banner" }
$pkg = ([regex]::Match(($dump | Select-Object -First 3) -join "`n", 'Package name=(\S+)')).Groups[1].Value

foreach ($dest in $destinations) {
    New-Item -ItemType Directory -Force (Join-Path $dest 'base') | Out-Null
    Copy-Item $apk (Join-Path $dest 'base\base.apk')
    Copy-Item $aab (Join-Path $dest 'base\base.aab')
    @{ basePackage = $pkg; iconEntry = $entry; bannerEntry = $banner } | ConvertTo-Json | Set-Content (Join-Path $dest 'base\base_info.json')
}
Write-Output "Base APK: $((Get-Item $apk).Length) bytes, base AAB: $((Get-Item $aab).Length) bytes, package $pkg, icon $entry, banner $banner"
