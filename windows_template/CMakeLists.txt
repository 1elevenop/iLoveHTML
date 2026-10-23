# iLoveHTML Windows wrapper (ADR 0007). Built once by
# tools/build_windows_wrapper.ps1; iLoveHTML copies the exe for every app.
cmake_minimum_required(VERSION 3.20)
project(html2apk_wrapper LANGUAGES CXX)

set(WEBVIEW2_SDK "" CACHE PATH "Unpacked Microsoft.Web.WebView2 NuGet package")
if(NOT EXISTS "${WEBVIEW2_SDK}/build/native/include/WebView2.h")
  message(FATAL_ERROR "Set WEBVIEW2_SDK to the unpacked Microsoft.Web.WebView2 package")
endif()

# Static C runtime: generated apps must not need the VC++ redistributable.
set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded")

add_executable(html2apk_wrapper WIN32 src/main.cpp src/app.manifest)
target_compile_features(html2apk_wrapper PRIVATE cxx_std_17)
target_compile_definitions(html2apk_wrapper PRIVATE UNICODE _UNICODE)
target_compile_options(html2apk_wrapper PRIVATE /W4 /permissive- /guard:cf /GS)
target_include_directories(html2apk_wrapper PRIVATE "${WEBVIEW2_SDK}/build/native/include")
target_link_options(html2apk_wrapper PRIVATE /guard:cf /DYNAMICBASE /NXCOMPAT /HIGHENTROPYVA)
target_link_libraries(html2apk_wrapper PRIVATE
  "${WEBVIEW2_SDK}/build/native/x64/WebView2LoaderStatic.lib"
  shlwapi wininet shell32 ole32 user32 advapi32 version)
