# Generates the English audio clips that ship with the app.
#
# Why clips at all, when the device already has a speech engine: because
# depending on it cost three rounds of fixes. The voice list arrives empty on
# first call in a browser; on iOS it stays empty until something speaks; and the
# default voice for a page declared `lang="es"` is Spanish, which reads English
# with a Spanish accent -- audible, so no detection notices, and wrong in the one
# way a language app cannot afford.
#
# A clip removes all of that. The engine stays as the fallback for content that
# has no clip yet, which is how a new level works before its audio is generated.
#
# ## The voice, and why this one
#
# `en_US-joe-medium` from Piper, licensed **CC0**. Piper's voices are not
# uniformly licensed and most are unusable here: `ryan` is CC BY-NC-SA
# (non-commercial), `lessac` comes from a Blizzard Challenge research dataset,
# `hfc_female` is CC BY-NC-SA too. CC0 is the only category that leaves no
# question about shipping the generated audio inside a published app.
#
# Usage:  pwsh -File tool/generate_audio.ps1
#         pwsh -File tool/generate_audio.ps1 -Force   (regenerate everything)

[CmdletBinding()]
param(
    # Regenerate clips that already exist. Off by default: generating is cheap
    # but rewriting unchanged files makes a diff nobody can read.
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $projectRoot

# Pinned on purpose. "Latest" would mean the voice can change under us, and a
# different voice halfway through the vocabulary is worse than an older one.
$piperUrl = 'https://github.com/rhasspy/piper/releases/download/2023.11.14-2/piper_windows_amd64.zip'
$voiceBase = 'https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/joe/medium'
$voiceName = 'en_US-joe-medium'

# Kept out of the repository: ~85 MB of binary that anyone can fetch again.
$toolsDir = Join-Path $projectRoot '.piper'
$assetsDir = Join-Path $projectRoot 'assets/audio/en'
$manifestPath = Join-Path $projectRoot 'lib/content/en/a1_audio_manifest.dart'

# --- 1. Piper and the voice ---------------------------------------------------

New-Item -ItemType Directory -Force -Path $toolsDir | Out-Null
$piperExe = Join-Path $toolsDir 'piper/piper.exe'

if (-not (Test-Path $piperExe)) {
    Write-Host "Downloading Piper from $piperUrl"
    $zip = Join-Path $toolsDir 'piper.zip'
    Invoke-WebRequest -Uri $piperUrl -OutFile $zip
    Expand-Archive -Path $zip -DestinationPath $toolsDir -Force
    Remove-Item $zip
}

$voiceModel = Join-Path $toolsDir "$voiceName.onnx"
if (-not (Test-Path $voiceModel)) {
    Write-Host "Downloading voice $voiceName (CC0)"
    Invoke-WebRequest -Uri "$voiceBase/$voiceName.onnx" -OutFile $voiceModel
    Invoke-WebRequest -Uri "$voiceBase/$voiceName.onnx.json" -OutFile "$voiceModel.json"
}

foreach ($needed in @('ffmpeg')) {
    if (-not (Get-Command $needed -ErrorAction SilentlyContinue)) {
        throw "$needed is required and is not on PATH"
    }
}

# --- 2. What has to be spoken -------------------------------------------------

# The list comes from the content itself, through `spokenTextsOf`, so the script
# cannot drift from what the app will ask for. The same function backs the test
# that fails when a clip is missing.
Write-Host 'Reading the spoken texts from the content'
$json = & dart run tool/list_spoken_texts.dart
if ($LASTEXITCODE -ne 0) { throw 'Could not read the spoken texts' }
$entries = $json | ConvertFrom-Json
Write-Host "  $($entries.Count) texts"

# --- 3. One clip per text -----------------------------------------------------

New-Item -ItemType Directory -Force -Path $assetsDir | Out-Null
$generated = 0
$kept = 0

foreach ($entry in $entries) {
    $target = Join-Path $assetsDir "$($entry.file).mp3"

    if ((Test-Path $target) -and -not $Force) { $kept++; continue }

    $wav = Join-Path $toolsDir 'current.wav'
    # The text goes in on stdin: passing it as an argument would break on every
    # apostrophe, and the content is full of them ("What's your name?").
    $entry.text | & $piperExe --model $voiceModel --output_file $wav 2>$null
    if (-not (Test-Path $wav)) { throw "Piper produced nothing for: $($entry.text)" }

    # 48 kbps mono: speech, and consonants matter more here than in music --
    # this is what someone is going to imitate.
    & ffmpeg -y -loglevel error -i $wav -ac 1 -ar 22050 -b:a 48k $target
    if ($LASTEXITCODE -ne 0) { throw "ffmpeg failed on: $($entry.text)" }

    Remove-Item $wav -ErrorAction SilentlyContinue
    $generated++
}

Write-Host "  $generated generated, $kept already there"

# --- 4. The manifest the app reads -------------------------------------------

$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add('/// Qué clip de audio corresponde a cada texto hablado de A1.')
$lines.Add('///')
$lines.Add('/// **Generado por `tool/generate_audio.ps1`. No se edita a mano.**')
$lines.Add('///')
$lines.Add('/// La clave la produce `clipKey`, la misma función que usa el servicio al')
$lines.Add('/// buscar: si las dos no coincidieran, el clip existiría y nadie lo')
$lines.Add('/// encontraría. La voz es `en_US-joe-medium` de Piper, con licencia CC0.')
$lines.Add('library;')
$lines.Add('')
$lines.Add('const Map<String, String> a1AudioClips = <String, String>{')
foreach ($entry in $entries) {
    $key = $entry.key -replace "'", "\'"
    $lines.Add("  '$key': 'assets/audio/en/$($entry.file).mp3',")
}
$lines.Add('};')
$lines.Add('')

[System.IO.File]::WriteAllLines($manifestPath, $lines, (New-Object System.Text.UTF8Encoding $false))
Write-Host "Wrote $manifestPath"

$size = (Get-ChildItem $assetsDir -Filter *.mp3 | Measure-Object -Property Length -Sum).Sum
Write-Host ("Audio total: {0:N1} MB in {1} clips" -f ($size / 1MB), $entries.Count)
Write-Host 'Remember: flutter pub get, then flutter test'
