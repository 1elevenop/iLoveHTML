# Builds the Windows app wrapper (ADR 0007) into windows_template/dist/.
# The Windows iLoveHTML app copies it next to its exe at build time
# (app/windows/CMakeLists.txt). Rebuild whenever windows_template/ changes.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

# Microsoft.Web.WebView2 NuGet package, pinned by version and SHA-256.
$sdkVersion = '1.0.2903.40'
$sdkSha256 = 'EF128016DD1E51C59178C827ED5B8AA3322C57AFA8675D930F8109505542AD74'
$tools = Join-Path $root '.tools'
$sdk = Join-Path $tools "webview2-$sdkVersion"
if (-not (Test-Path (Join-Path $sdk 'build\native\include\WebView2.h'))) {
  New-Item -ItemType Directory -Force $tools | Out-Null
  $pkg = Join-Path $tools "microsoft.web.webview2.$sdkVersion.nupkg"
  Invoke-WebRequest "https://www.nuget.org/api/v2/package/Microsoft.Web.WebView2/$sdkVersion" -OutFile $pkg
  $hash = (Get-FileHash $pkg -Algorithm SHA256).Hash
  if ($hash -ne $sdkSha256) { Remove-Item $pkg; throw "WebView2 SDK checksum mismatch: $hash" }
  Expand-Archive $pkg $sdk -Force
}

$vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
$vs = & $vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
if (-not $vs) { throw 'Visual Studio with "Desktop development with C++" is required' }
$cmake = Join-Path $vs 'Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe'

$src = Join-Path $root 'windows_template'
$build = Join-Path $src 'build'
& $cmake -S $src -B $build -G 'Visual Studio 17 2022' -A x64 "-DWEBVIEW2_SDK=$sdk"
if ($LASTEXITCODE -ne 0) { throw 'CMake configure failed' }
& $cmake --build $build --config Release
if ($LASTEXITCODE -ne 0) { throw 'Wrapper build failed' }

$dist = Join-Path $src 'dist'
New-Item -ItemType Directory -Force $dist | Out-Null
Copy-Item (Join-Path $build 'Release\html2apk_wrapper.exe') $dist -Force
$exe = Get-Item (Join-Path $dist 'html2apk_wrapper.exe')
"Wrapper: $($exe.FullName) ($($exe.Length) bytes)"
