# End-to-end test of the Windows pipeline:
#   demo ZIP -> debug APK, release APK and release AAB (throwaway key)
#   -> signature checks (apksigner, jarsigner, bundletool)
#   -> install the debug APK on a running emulator/device and confirm the
#      page loaded (the debug build logs the page's console output).
#
# Usage: powershell -File tools/e2e_windows.ps1 [-Device emulator-5554]
# Needs: JDK (Android Studio's jbr), Android SDK build-tools, Flutter/Dart,
# .tools/bundletool.jar, and adb with the device connected.
param([string]$Device = 'emulator-5554')
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
if (-not $env:JAVA_HOME) { $env:JAVA_HOME = 'C:\Program Files\Android\Android Studio\jbr' }
$sdk = if ($env:ANDROID_HOME) { $env:ANDROID_HOME } else { Join-Path $env:LOCALAPPDATA 'Android\Sdk' }
$bt = Get-ChildItem (Join-Path $sdk 'build-tools') | Sort-Object { [version]($_.Name -replace '-.*','') } | Select-Object -Last 1
$apksigner = Join-Path $bt.FullName 'apksigner.bat'
$java = Join-Path $env:JAVA_HOME 'bin\java.exe'
$bundletool = Join-Path $root '.tools\bundletool.jar'
$dart = 'C:\src\flutter\bin\dart.bat'

$work = Join-Path ([IO.Path]::GetTempPath()) ("html2apk-e2e-" + [guid]::NewGuid().ToString('N').Substring(0, 8))
New-Item -ItemType Directory -Force $work | Out-Null
$failures = @()
function Check($name, [bool]$ok, $detail = '') {
    if ($ok) { Write-Output "PASS  $name" } else { Write-Output "FAIL  $name $detail"; $script:failures += $name }
}

try {
    # Throwaway release key; the password lives only in this process's environment.
    $env:HTML2APK_KEYSTORE_PASSWORD = [guid]::NewGuid().ToString('N')
    $ks = Join-Path $work 'e2e.jks'
    & (Join-Path $env:JAVA_HOME 'bin\keytool.exe') -genkeypair -keystore $ks -storetype PKCS12 -alias e2e -keyalg RSA `
        -keysize 2048 -validity 10000 -dname 'CN=HTML2APK E2E' -storepass $env:HTML2APK_KEYSTORE_PASSWORD 2>&1 | Out-Null

    $cli = Join-Path $root 'packages\html2apk_core\bin\html2apk.dart'
    $zip = Join-Path $root 'samples\demo-site.zip'
    $common = @('--zip', $zip, '--name', 'E2E Demo', '--id', 'com.html2apk.e2e', '--workspace', (Join-Path $work 'ws'), '--out', $work)
    Push-Location (Join-Path $root 'packages\html2apk_core')
    try {
        & $dart run $cli @common 2>&1 | Out-Null; Check 'debug APK build' ($LASTEXITCODE -eq 0)
        & $dart run $cli @common --release --keystore $ks --alias e2e 2>&1 | Out-Null; Check 'release APK build' ($LASTEXITCODE -eq 0)
        & $dart run $cli @common --release --aab --keystore $ks --alias e2e 2>&1 | Out-Null; Check 'release AAB build' ($LASTEXITCODE -eq 0)
    } finally { Pop-Location }

    $debug = Join-Path $work 'com.html2apk.e2e-1.0.0-debug.apk'
    $release = Join-Path $work 'com.html2apk.e2e-1.0.0-release.apk'
    $aab = Join-Path $work 'com.html2apk.e2e-1.0.0-release.aab'

    & $apksigner verify $debug 2>&1 | Out-Null; Check 'debug APK signature' ($LASTEXITCODE -eq 0)
    $certs = (& $apksigner verify --print-certs $release 2>&1) -join "`n"
    Check 'release APK signed by the e2e key' ($LASTEXITCODE -eq 0 -and $certs -match 'CN=HTML2APK E2E')
    $jar = (& (Join-Path $env:JAVA_HOME 'bin\jarsigner.exe') -verify $aab 2>&1) -join "`n"
    Check 'AAB JAR signature' ($jar -match 'jar verified')
    & $java -jar $bundletool validate --bundle $aab 2>&1 | Out-Null; Check 'bundletool validate' ($LASTEXITCODE -eq 0)

    $devices = (adb devices) -join "`n"
    if ($devices -notmatch [regex]::Escape($Device) + '\s+device') {
        Check "device $Device connected" $false '(skipping install checks)'
    } else {
        adb -s $Device uninstall com.html2apk.e2e 2>&1 | Out-Null
        $inst = (adb -s $Device install $debug 2>&1) -join ' '
        Check 'install debug APK' ($inst -match 'Success') $inst
        adb -s $Device logcat -c
        adb -s $Device shell am start -W -n com.html2apk.e2e/com.html2apk.runtime.MainActivity 2>&1 | Out-Null
        $loaded = $false
        for ($i = 0; $i -lt 20 -and -not $loaded; $i++) {
            Start-Sleep -Milliseconds 500
            $loaded = ((adb -s $Device logcat -d -s HTML2APK:I) -join "`n") -match 'html2apk demo loaded'
        }
        Check 'page loaded and ran its JavaScript' $loaded
        $crash = (adb -s $Device logcat -d -b crash) -join "`n"
        Check 'no crash' (-not ($crash -match 'com.html2apk.e2e'))
        adb -s $Device uninstall com.html2apk.e2e 2>&1 | Out-Null
    }
} finally {
    Remove-Item Env:HTML2APK_KEYSTORE_PASSWORD -ErrorAction SilentlyContinue
    Remove-Item -Recurse -Force $work -ErrorAction SilentlyContinue
}

if ($failures.Count) { Write-Output "`n$($failures.Count) check(s) failed"; exit 1 }
Write-Output "`nAll end-to-end checks passed"
