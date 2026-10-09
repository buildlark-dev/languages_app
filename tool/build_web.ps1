# Compila la versión web para publicar.
#
# No es un atajo para escribir menos: existe porque `flutter build web` a secas
# publicó un paquete roto y nadie lo notó.
#
# Lo que pasó, con fechas: el registro de plugins web
# (`.dart_tool/flutter_build/<hash>/web_plugin_registrant.dart`) se generó a las
# 07:28, `shared_preferences` entró en `pubspec.yaml` a las 12:58, y el build
# que se desplegó se compiló a las 21:49 **reutilizando el registro viejo**. La
# app desplegada escribía `MissingPluginException` en la consola y perdía el
# tema y la velocidad de voz en silencio. Un build incremental conservó una
# tabla de plugins anterior a una dependencia.
#
# De ahí los tres trabajos de este script:
#
#   1. Borrar el estado incremental antes de compilar.
#   2. Inyectar un identificador de compilación, que es cómo una PWA ya
#      instalada se entera de que hay una versión nueva.
#   3. Comprobar, **después** de compilar, que el registro de plugins contiene
#      todos los que el proyecto declara para web. Si falta uno, se para aquí y
#      no se publica.
#
# Uso:  pwsh -File tool/build_web.ps1
#       pwsh -File tool/build_web.ps1 -Deploy

[CmdletBinding()]
param(
    # Publica en Firebase Hosting si el build y las comprobaciones pasan.
    [switch]$Deploy
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $projectRoot

# --- 1. Identificador de la compilación -------------------------------------

$shortSha = (& git rev-parse --short HEAD).Trim()
if (-not $shortSha) { throw 'No se pudo leer el commit actual' }
$buildId = '{0}-{1}' -f $shortSha, (Get-Date -Format 'yyyyMMdd-HHmm')
Write-Host "Identificador de compilacion: $buildId"

# --- 2. Build en limpio ------------------------------------------------------

foreach ($stale in @('build/web', '.dart_tool/flutter_build')) {
    if (Test-Path $stale) {
        Write-Host "Borrando $stale"
        Remove-Item -Recurse -Force $stale
    }
}

# `--no-web-resources-cdn` sirve canvaskit desde nuestro propio dominio.
#
# Por defecto Flutter lo pide a `www.gstatic.com`, y medido en el sitio
# desplegado era así: `canvaskit.wasm` y `canvaskit.js` venían de alli. Un
# recurso de otro origen no lo puede guardar nuestro service worker —la
# respuesta es opaca—, de modo que sin red la app no tenia con que dibujar y no
# arrancaba, que es lo contrario de FR-039 y SC-003.
#
# Cuesta unos megabytes servidos por nosotros. Los paga el service worker una
# vez.
& flutter build web --release --no-web-resources-cdn "--dart-define=BUILD_ID=$buildId"
if ($LASTEXITCODE -ne 0) { throw 'flutter build web fallo' }

# --- 3. El registro de plugins web, que es lo que falló ----------------------

$declared = (Get-Content '.flutter-plugins-dependencies' -Raw | ConvertFrom-Json).plugins.web |
    ForEach-Object { $_.name }

$registrants = @(Get-ChildItem -Path '.dart_tool/flutter_build' -Recurse `
        -Filter 'web_plugin_registrant.dart' -ErrorAction SilentlyContinue)

if ($registrants.Count -eq 0) {
    throw 'El build no genero web_plugin_registrant.dart: no se puede comprobar que los plugins web esten dentro'
}

$missing = @()
foreach ($registrant in $registrants) {
    $source = Get-Content $registrant.FullName -Raw
    foreach ($plugin in $declared) {
        if ($source -notmatch [regex]::Escape("package:$plugin/")) {
            $missing += "$plugin (en $($registrant.Name))"
        }
    }
}

if ($missing.Count -gt 0) {
    Write-Host 'Plugins web declarados que NO estan en el registro generado:' -ForegroundColor Red
    $missing | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    throw 'El paquete web se compilo sin algun plugin: no se publica'
}

Write-Host "Registro de plugins web completo ($($declared.Count) plugins)" -ForegroundColor Green

# --- 4. El identificador, junto al paquete -----------------------------------

# La app lo pide **siempre por red** y lo compara con el que lleva compilado
# dentro. Es todo el mecanismo de «hay una version nueva».
$payload = [ordered]@{
    buildId = $buildId
    builtAt = (Get-Date).ToUniversalTime().ToString('o')
}
# Sin BOM: `Set-Content -Encoding utf8` pone uno en PowerShell 5.1, y un BOM
# delante de un JSON es la clase de detalle que rompe un parser y no otro.
[System.IO.File]::WriteAllText(
    (Join-Path $projectRoot 'build/web/build-id.json'),
    ($payload | ConvertTo-Json),
    (New-Object System.Text.UTF8Encoding $false)
)
Write-Host 'Escrito build/web/build-id.json'

# --- 5. Publicar -------------------------------------------------------------

if (-not $Deploy) {
    Write-Host 'Listo. Para publicar: pwsh -File tool/build_web.ps1 -Deploy'
    exit 0
}

& firebase deploy --only hosting
if ($LASTEXITCODE -ne 0) { throw 'firebase deploy fallo' }

# Las cabeceras son lo unico que demuestra que la PWA instalada podra
# actualizarse, y no se ven desde el navegador: hay que leerlas.
Write-Host ''
Write-Host 'Cabeceras de los archivos que Flutter NO versiona por contenido:'
foreach ($path in @('/', '/flutter_bootstrap.js', '/main.dart.js', '/build-id.json')) {
    $url = "https://languages-buildlark.web.app$path"
    try {
        $response = Invoke-WebRequest -Uri $url -Method Head -UseBasicParsing
        $cache = $response.Headers['Cache-Control']
        Write-Host ("  {0,-24} {1}" -f $path, $cache)
    } catch {
        Write-Host ("  {0,-24} no se pudo consultar" -f $path) -ForegroundColor Yellow
    }
}
