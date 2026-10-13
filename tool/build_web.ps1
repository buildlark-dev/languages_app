# Builds the web release for publishing.
#
# This is not a shortcut for typing less: it exists because a plain
# `flutter build web` published a broken bundle and nobody noticed.
#
# What happened, with timestamps: the web plugin registry
# (`.dart_tool/flutter_build/<hash>/web_plugin_registrant.dart`) was generated at 07:28,
# `shared_preferences` entered `pubspec.yaml` at 12:58, and the bundle that was deployed
# compiled at 21:49 **reusing the old registry**. The deployed app wrote
# `MissingPluginException` to the console and silently lost the theme and the speech
# rate. An incremental build had kept a plugin table older than a dependency.
#
# Hence this script's three jobs:
#
#   1. Wipe the incremental state before building.
#   2. Inject a build id, which is how an already-installed PWA learns that a new
#      version exists.
#   3. Check, **after** building, that the plugin registry contains every plugin the
#      project declares for web. If one is missing it stops here and nothing is
#      published.
#
# Usage:  pwsh -File tool/build_web.ps1
#         pwsh -File tool/build_web.ps1 -Deploy

[CmdletBinding()]
param(
    # Publish to Firebase Hosting if the build and the checks pass.
    [switch]$Deploy
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $projectRoot

# --- 1. Build id -------------------------------------------------------------

$shortSha = (& git rev-parse --short HEAD).Trim()
if (-not $shortSha) { throw 'Could not read the current commit' }
$buildId = '{0}-{1}' -f $shortSha, (Get-Date -Format 'yyyyMMdd-HHmm')
Write-Host "Build id: $buildId"

# --- 2. Clean build ----------------------------------------------------------

foreach ($stale in @('build/web', '.dart_tool/flutter_build')) {
    if (Test-Path $stale) {
        Write-Host "Removing $stale"
        Remove-Item -Recurse -Force $stale
    }
}

# `--no-web-resources-cdn` serves canvaskit from our own domain.
#
# By default Flutter fetches it from `www.gstatic.com`, and that is what was measured on
# the deployed site: `canvaskit.wasm` and `canvaskit.js` came from there. A cross-origin
# resource cannot be stored by our service worker — the response is opaque — so with no
# network the app had nothing to draw with and would not start, which is the opposite of
# FR-039 and SC-003.
#
# It costs a few megabytes served by us. The service worker pays that once.
& flutter build web --release --no-web-resources-cdn "--dart-define=BUILD_ID=$buildId"
if ($LASTEXITCODE -ne 0) { throw 'flutter build web failed' }

# --- 3. The web plugin registry, which is what failed ------------------------

$declared = (Get-Content '.flutter-plugins-dependencies' -Raw | ConvertFrom-Json).plugins.web |
    ForEach-Object { $_.name }

$registrants = @(Get-ChildItem -Path '.dart_tool/flutter_build' -Recurse `
        -Filter 'web_plugin_registrant.dart' -ErrorAction SilentlyContinue)

if ($registrants.Count -eq 0) {
    throw 'The build did not generate web_plugin_registrant.dart: cannot verify that the web plugins are in the bundle'
}

$missing = @()
foreach ($registrant in $registrants) {
    $source = Get-Content $registrant.FullName -Raw
    foreach ($plugin in $declared) {
        if ($source -notmatch [regex]::Escape("package:$plugin/")) {
            $missing += "$plugin (in $($registrant.Name))"
        }
    }
}

if ($missing.Count -gt 0) {
    Write-Host 'Declared web plugins missing from the generated registry:' -ForegroundColor Red
    $missing | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    throw 'The web bundle compiled without a plugin: not publishing'
}

Write-Host "Web plugin registry complete ($($declared.Count) plugins)" -ForegroundColor Green

# --- 4. The build id, next to the bundle -------------------------------------

# The app always fetches this over the network and compares it with the id compiled
# into itself. That is the whole "a new version exists" mechanism.
$payload = [ordered]@{
    buildId = $buildId
    builtAt = (Get-Date).ToUniversalTime().ToString('o')
}
# No BOM: `Set-Content -Encoding utf8` writes one on PowerShell 5.1, and a BOM in front
# of JSON is the kind of detail that breaks one parser and not another.
[System.IO.File]::WriteAllText(
    (Join-Path $projectRoot 'build/web/build-id.json'),
    ($payload | ConvertTo-Json),
    (New-Object System.Text.UTF8Encoding $false)
)
Write-Host 'Wrote build/web/build-id.json'

# --- 5. Publish --------------------------------------------------------------

if (-not $Deploy) {
    Write-Host 'Done. To publish: pwsh -File tool/build_web.ps1 -Deploy'
    exit 0
}

& firebase deploy --only hosting
if ($LASTEXITCODE -ne 0) { throw 'firebase deploy failed' }

# The headers are the only proof that an installed PWA will be able to update, and they
# are invisible from a browser: they have to be read.
Write-Host ''
Write-Host 'Cache headers of the files Flutter does not content-hash:'
foreach ($path in @('/', '/flutter_bootstrap.js', '/main.dart.js', '/build-id.json')) {
    $url = "https://languages-buildlark.web.app$path"
    try {
        $response = Invoke-WebRequest -Uri $url -Method Head -UseBasicParsing
        $cache = $response.Headers['Cache-Control']
        Write-Host ("  {0,-24} {1}" -f $path, $cache)
    } catch {
        Write-Host ("  {0,-24} could not be read" -f $path) -ForegroundColor Yellow
    }
}
