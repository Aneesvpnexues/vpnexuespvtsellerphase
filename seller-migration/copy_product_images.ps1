<#
.SYNOPSIS
  Copies the files of a Supabase Storage bucket from the OLD project to the
  NEW Seller project (bucket: product-images by default).

.DESCRIPTION
  WHAT IT DOES, IN PLAIN LANGUAGE:
    1. Asks the OLD project for the list of every file in the bucket
       (read-only: it only looks).
    2. Downloads each file from the OLD project's PUBLIC url to a temp
       folder on this computer.
    3. Uploads each file to the same path in the NEW project's bucket.
    4. Verifies each upload exists in the NEW project.
    5. Prints a summary: copied / failed / skipped.

  SAFETY RULES:
    * Reads from OLD, writes ONLY to NEW. The old project is never modified.
    * Service-role keys are read from environment variables — they are NOT
      stored in this file. Never commit keys to git.
    * ALWAYS test first with -Limit 3 (copies only the first 3 files).

.PARAMETER ListOnly
  Only lists the files found in the OLD bucket; downloads/uploads nothing.

.EXAMPLE
  # Step 1: see what is there (nothing is written anywhere)
  .\copy_product_images.ps1 -ListOnly

.EXAMPLE
  # Step 2: test with the first 3 files only
  .\copy_product_images.ps1 -Limit 3

.EXAMPLE
  # Step 3: full copy
  .\copy_product_images.ps1

.EXAMPLE
  # Keys from environment variables (recommended)
  $env:SUPABASE_OLD_URL = "https://xxxx.supabase.co"
  $env:SUPABASE_OLD_SERVICE_KEY = "eyJ..."      # OLD project service_role key
  $env:SUPABASE_NEW_URL = "https://yyyy.supabase.co"
  $env:SUPABASE_NEW_SERVICE_KEY = "eyJ..."      # NEW project service_role key
  .\copy_product_images.ps1
#>

[CmdletBinding()]
param(
  [string]$OldUrl   = $env:SUPABASE_OLD_URL,
  [string]$NewUrl   = $env:SUPABASE_NEW_URL,
  [string]$OldKey   = $env:SUPABASE_OLD_SERVICE_KEY,
  [string]$NewKey   = $env:SUPABASE_NEW_SERVICE_KEY,
  [string]$Bucket   = 'product-images',
  [int]$Limit       = 0,          # 0 = copy everything; N = only first N files (test mode)
  [switch]$ListOnly
)

$ErrorActionPreference = 'Stop'

# --- 0. Guard rails -------------------------------------------------------
if (-not $OldUrl -or -not $NewUrl -or -not $OldKey -or -not $NewKey) {
  Write-Host 'ERROR: missing connection values.' -ForegroundColor Red
  Write-Host 'Provide them as parameters or environment variables:'
  Write-Host '  SUPABASE_OLD_URL, SUPABASE_OLD_SERVICE_KEY (OLD project - read only)'
  Write-Host '  SUPABASE_NEW_URL, SUPABASE_NEW_SERVICE_KEY (NEW Seller project)'
  Write-Host ''
  Write-Host 'Where to find them: Dashboard -> Project Settings -> API'
  Write-Host '  Project URL  = "Project URL" row'
  Write-Host '  service key  = the "service_role" secret row (click to reveal)'
  exit 2
}
$OldUrl = $OldUrl.TrimEnd('/')
$NewUrl = $NewUrl.TrimEnd('/')
if ($OldUrl -eq $NewUrl) {
  Write-Host 'ERROR: OLD url and NEW url are the same. Refusing to run.' -ForegroundColor Red
  exit 2
}

function Encode-Path([string]$path) {
  # URL-encode each folder/file segment but keep the "/" separators.
  (($path -split '/') | ForEach-Object { [uri]::EscapeDataString($_) }) -join '/'
}

function Invoke-OldPublicHead([string]$path) {
  try {
    $r = Invoke-WebRequest -Method Head -UseBasicParsing `
        -Uri "$OldUrl/storage/v1/object/public/$Bucket/$(Encode-Path $path)" `
        -Headers @{ apikey = $OldKey; Authorization = "Bearer $OldKey" } `
        -TimeoutSec 60
    return $r.Headers['Content-Type']
  } catch { return $null }
}

function Get-BucketFiles([string]$url, [string]$key, [string]$bucket, [string]$prefix) {
  # Recursively list every file. Returns objects with .path (full path).
  $result = @()
  $offset = 0
  $pageSize = 1000
  $files = @()
  $folders = @()
  do {
    $body = @{
      prefix  = $prefix
      limit   = $pageSize
      offset  = $offset
      sortBy  = @{ column = 'name'; order = 'asc' }
    } | ConvertTo-Json -Depth 5
    $resp = Invoke-RestMethod -Method Post `
        -Uri "$url/storage/v1/object/list/$bucket" `
        -Headers @{ apikey = $key; Authorization = "Bearer $key"; 'Content-Type' = 'application/json' } `
        -Body $body -TimeoutSec 60
    $page = @($resp)
    foreach ($item in $page) {
      $name = [string]$item.name
      $full = if ($prefix -and -not $name.StartsWith($prefix)) { $prefix + $name } else { $name }
      $hasId = ($null -ne $item.PSObject.Properties['id']) -and ($null -ne $item.id)
      if ($hasId) {
        $files += [pscustomobject]@{ path = $full }
      } else {
        $folders += [pscustomobject]@{ prefix = $full }
      }
    }
    $offset += $pageSize
  } while ($page.Count -eq $pageSize)

  $result += $files
  foreach ($f in $folders) {
    $result += Get-BucketFiles -url $url -key $key -bucket $bucket -prefix $f.prefix
  }
  return $result
}

# --- 1. List files in the OLD bucket (read only) --------------------------
Write-Host "Listing files in OLD bucket '$Bucket' ..." -ForegroundColor Cyan
$files = @(Get-BucketFiles -url $OldUrl -key $OldKey -bucket $Bucket -prefix '')
Write-Host "Found $($files.Count) file(s) in the OLD project."
if ($files.Count -eq 0) { Write-Host 'Nothing to copy.'; exit 0 }

if ($ListOnly) {
  $files | ForEach-Object { Write-Host "  $($_.path)" }
  Write-Host 'ListOnly mode: nothing was downloaded or uploaded.'
  exit 0
}

if ($Limit -gt 0) {
  $files = @($files | Select-Object -First $Limit)
  Write-Host "TEST MODE: processing only the first $($files.Count) file(s)." -ForegroundColor Yellow
}

# --- 2/3/4. Download -> Upload -> Verify ----------------------------------
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("supabase-copy-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null

$copied = 0
$failed = @()
$i = 0

foreach ($f in $files) {
  $i++
  $path = $f.path
  Write-Host "[$i/$($files.Count)] $path"
  $local = Join-Path $tempRoot ("file-{0}" -f $i)
  try {
    # a) Read the file's content type (mime) from the OLD public URL.
    $mime = Invoke-OldPublicHead $path
    if (-not $mime) { $mime = 'application/octet-stream' }

    # b) Download from OLD (read only).
    Invoke-WebRequest -UseBasicParsing -OutFile $local `
        -Uri "$OldUrl/storage/v1/object/public/$Bucket/$(Encode-Path $path)" `
        -Headers @{ apikey = $OldKey; Authorization = "Bearer $OldKey" } `
        -TimeoutSec 120

    # c) Upload to NEW at the identical path (x-upsert = overwrite-safe).
    Invoke-RestMethod -Method Post -InFile $local -ContentType $mime `
        -Uri "$NewUrl/storage/v1/object/$Bucket/$(Encode-Path $path)" `
        -Headers @{ apikey = $NewKey; Authorization = "Bearer $NewKey"; 'x-upsert' = 'true' } `
        -TimeoutSec 120 | Out-Null

    # d) Verify it really exists in the NEW project.
    $check = Invoke-WebRequest -Method Head -UseBasicParsing `
        -Uri "$NewUrl/storage/v1/object/public/$Bucket/$(Encode-Path $path)" `
        -Headers @{ apikey = $NewKey; Authorization = "Bearer $NewKey" } `
        -TimeoutSec 60
    if ($check.StatusCode -ge 200 -and $check.StatusCode -lt 300) {
      $copied++
      Write-Host "    OK (verified in NEW)" -ForegroundColor Green
    } else {
      $failed += "$path (verify failed: HTTP $($check.StatusCode))"
      Write-Host "    VERIFY FAILED" -ForegroundColor Red
    }
  } catch {
    $failed += "$path ($($_.Exception.Message))"
    Write-Host "    FAILED: $($_.Exception.Message)" -ForegroundColor Red
  } finally {
    if (Test-Path $local) { Remove-Item $local -Force -ErrorAction SilentlyContinue }
  }
}

Remove-Item $tempRoot -Recurse -Force -ErrorAction SilentlyContinue

# --- 5. Summary -----------------------------------------------------------
Write-Host ''
Write-Host '==================== SUMMARY ====================' -ForegroundColor Cyan
Write-Host "Files found in OLD : $($files.Count)"
Write-Host "Copied & verified  : $copied" -ForegroundColor Green
Write-Host "Failed             : $($failed.Count)" -ForegroundColor $(if ($failed.Count -gt 0) { 'Red' } else { 'Green' })
$failed | ForEach-Object { Write-Host "   - $_" -ForegroundColor Red }
Write-Host '================================================='
Write-Host 'NEXT: run 06_verify_storage_READ_ONLY.sql on BOTH projects and'
Write-Host "confirm the product-images file_count matches ($($files.Count) here)."

if ($failed.Count -gt 0) { exit 1 } else { exit 0 }
