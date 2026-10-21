param([string]$Version = '1.1.0')
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$dist = Join-Path $root 'dist'
New-Item -ItemType Directory -Path $dist -Force | Out-Null
Add-Type -AssemblyName System.IO.Compression.FileSystem
Add-Type -AssemblyName System.IO.Compression
$catalog = Get-Content -LiteralPath (Join-Path $root 'payload\catalog.json') -Raw -Encoding UTF8 | ConvertFrom-Json
if ($catalog.version -ne $Version) { throw 'Version does not match payload catalog.' }
foreach ($item in $catalog.scripts) {
    $path = Join-Path $root ('payload\' + $item.file)
    $sha = [Security.Cryptography.SHA256]::Create()
    try { $hash = [BitConverter]::ToString($sha.ComputeHash([IO.File]::ReadAllBytes($path))).Replace('-','').ToLowerInvariant() }
    finally { $sha.Dispose() }
    if ($hash -ne $item.sha256) { throw ('Payload hash mismatch: ' + $item.name) }
}
$package = Join-Path $dist 'package.zip'
if (Test-Path -LiteralPath $package) { Remove-Item -LiteralPath $package }
$zip = [IO.Compression.ZipFile]::Open($package, [IO.Compression.ZipArchiveMode]::Create)
try {
    [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip,(Join-Path $root 'Installer.ps1'),'Installer.ps1') | Out-Null
    foreach ($file in (Get-ChildItem -LiteralPath (Join-Path $root 'payload') -File)) {
        [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip,$file.FullName,('payload/' + $file.Name)) | Out-Null
    }
} finally { $zip.Dispose() }
$compiler = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
if (-not (Test-Path -LiteralPath $compiler)) { throw '.NET Framework C# compiler not found.' }
$exe = Join-Path $dist ('Jay-GHUB-Script-Pack-v' + $Version + '.exe')
& $compiler /nologo /target:winexe /optimize+ /reference:System.Windows.Forms.dll /reference:System.IO.Compression.dll /reference:System.IO.Compression.FileSystem.dll ('/resource:' + $package + ',package.zip') ('/out:' + $exe) (Join-Path $root 'Launcher.cs')
if ($LASTEXITCODE -ne 0) { throw 'Compiler failed.' }
Copy-Item -LiteralPath (Join-Path $root 'README.txt') -Destination $dist -Force
Copy-Item -LiteralPath (Join-Path $root 'OPERATORS.txt') -Destination $dist -Force
Remove-Item -LiteralPath $package
Write-Output $exe
