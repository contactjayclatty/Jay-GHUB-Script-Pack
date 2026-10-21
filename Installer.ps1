param(
    [ValidateSet('UI','Install','Uninstall')][string]$Action = 'UI',
    [string]$TargetRoot = (Join-Path $env:LOCALAPPDATA 'LGHUB'),
    [switch]$TestMode
)
$ErrorActionPreference = 'Stop'
$packId = 'siege-operator-lua-pack-v1'
$packageRoot = $PSScriptRoot
$payload = Join-Path $packageRoot 'payload'
$catalog = Get-Content -LiteralPath (Join-Path $payload 'catalog.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$targetFull = [IO.Path]::GetFullPath($TargetRoot)
$scriptsRoot = Join-Path $targetFull 'scripts'
$stateRoot = Join-Path $targetFull ('script-pack-installs\' + $packId)
$manifestPath = Join-Path $stateRoot 'installed.json'

function Assert-Ready {
    if (-not $TestMode -and (Get-Process -Name 'lghub','lghub_agent' -ErrorAction SilentlyContinue)) {
        throw 'Fully quit G HUB from its system tray icon, then try again. If it remains running, close its background processes in Task Manager.'
    }
    if (-not $TestMode -and -not (Test-Path -LiteralPath $targetFull -PathType Container)) {
        throw 'G HUB user data was not found. Install and open G HUB once before using this installer.'
    }
}
function Get-Hash([string]$Path) {
    $algorithm = [Security.Cryptography.SHA256]::Create()
    $stream = [IO.File]::OpenRead($Path)
    try { [BitConverter]::ToString($algorithm.ComputeHash($stream)).Replace('-','').ToLowerInvariant() }
    finally { $stream.Dispose(); $algorithm.Dispose() }
}
function Write-Json($Value, [string]$Path) {
    $temp = $Path + '.tmp'
    [IO.File]::WriteAllText($temp, (ConvertTo-Json -InputObject $Value -Depth 20), (New-Object Text.UTF8Encoding($false)))
    Move-Item -LiteralPath $temp -Destination $Path -Force
}
function Resolve-OwnedFolder([string]$Id) {
    $guid = [guid]::Empty
    if (-not [guid]::TryParse($Id, [ref]$guid)) { throw 'Invalid folder ID in install manifest.' }
    Join-Path $scriptsRoot $guid.ToString()
}
function Install-Pack {
    Assert-Ready
    # Validate every bundled script before making any change to user data.
    foreach ($item in $catalog.scripts) {
        if ($item.file -notmatch '^[A-Za-z0-9_-]+\.lua$') { throw 'Invalid payload filename.' }
        if ((Get-Hash (Join-Path $payload $item.file)) -ne $item.sha256) { throw ('Payload verification failed: ' + $item.name) }
    }
    $owned = @()
    if (Test-Path -LiteralPath $manifestPath) {
        $prior = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($prior.packId -ne $packId) { throw 'Install manifest belongs to another package.' }
        $owned = @($prior.scripts)
    }
    $existingNames = @()
    if (Test-Path -LiteralPath $scriptsRoot) {
        foreach ($folder in (Get-ChildItem -LiteralPath $scriptsRoot -Directory)) {
            $config = Join-Path $folder.FullName 'config.json'
            if (Test-Path -LiteralPath $config) {
                try { $existingNames += (Get-Content -LiteralPath $config -Raw -Encoding UTF8 | ConvertFrom-Json).name }
                catch { throw ('Cannot read existing script configuration: ' + $folder.Name + '. No scripts were changed.') }
            }
        }
    }
    # Preserve a complete snapshot of current scripts before adding anything.
    New-Item -ItemType Directory -Path $stateRoot -Force | Out-Null
    $snapshot = Join-Path $stateRoot ('backups\' + (Get-Date -Format 'yyyyMMdd-HHmmss-fff'))
    New-Item -ItemType Directory -Path $snapshot -Force | Out-Null
    if (Test-Path -LiteralPath $scriptsRoot) { Copy-Item -LiteralPath $scriptsRoot -Destination (Join-Path $snapshot 'scripts') -Recurse }
    if (Test-Path -LiteralPath $manifestPath) { Copy-Item -LiteralPath $manifestPath -Destination (Join-Path $snapshot 'installed.json') }
    New-Item -ItemType Directory -Path $scriptsRoot -Force | Out-Null
    $newFolders = @()
    $added = @()
    $skipped = @()
    try {
        foreach ($item in $catalog.scripts) {
            if (@(@($item.name) + @($item.aliases) | Where-Object { $existingNames -contains $_ }).Count -gt 0) { $skipped += $item.name; continue }
            $id = [guid]::NewGuid().ToString()
            $folder = Resolve-OwnedFolder $id
            New-Item -ItemType Directory -Path $folder -ErrorAction Stop | Out-Null
            $newFolders += $folder
            $scriptPath = Join-Path $folder 'script.lua'
            $configPath = Join-Path $folder 'config.json'
            Copy-Item -LiteralPath (Join-Path $payload $item.file) -Destination $scriptPath
            Write-Json ([ordered]@{description='Neutral template: vertical and horizontal strengths are 0. Calibrate before use.';fileName='.\script.lua';name=$item.name}) $configPath
            if ((Get-Hash $scriptPath) -ne $item.sha256) { throw ('Installed script verification failed: ' + $item.name) }
            $added += [pscustomobject]@{id=$id;name=$item.name;scriptHash=(Get-Hash $scriptPath);configHash=(Get-Hash $configPath)}
            $existingNames += $item.name
        }
        $owned = @($owned) + @($added)
        Write-Json ([ordered]@{packId=$packId;version=$catalog.version;updated=(Get-Date).ToString('o');scripts=@($owned)}) $manifestPath
    } catch {
        foreach ($folder in $newFolders) {
            # Only remove exact new UUID folders created by this installation attempt.
            if ([IO.Path]::GetDirectoryName($folder) -ne $scriptsRoot) { throw 'Rollback path validation failed.' }
            if (Test-Path -LiteralPath $folder) { Remove-Item -LiteralPath $folder -Recurse -Force }
        }
        throw
    }
    "Installed $($added.Count) scripts. Skipped $($skipped.Count) existing names (left unchanged).`r`n`r`nBackup: $snapshot`r`n`r`nOpen G HUB and select a script in the Scripting editor. Select it on the intended game profile. Existing scripts are never replaced."
}
function Uninstall-Pack {
    Assert-Ready
    if (-not (Test-Path -LiteralPath $manifestPath)) { return 'No scripts installed by this package were found.' }
    $manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($manifest.packId -ne $packId) { throw 'Install manifest belongs to another package.' }
    $kept = @()
    $removed = 0
    foreach ($item in @($manifest.scripts)) {
        $folder = Resolve-OwnedFolder $item.id
        if (-not (Test-Path -LiteralPath $folder)) { continue }
        $files = @(Get-ChildItem -LiteralPath $folder -Force)
        $script = Join-Path $folder 'script.lua'
        $config = Join-Path $folder 'config.json'
        if ($files.Count -ne 2 -or -not (Test-Path -LiteralPath $script) -or -not (Test-Path -LiteralPath $config)) { $kept += $item; continue }
        if ((Get-Hash $script) -ne $item.scriptHash -or (Get-Hash $config) -ne $item.configHash) { $kept += $item; continue }
        # Require exact ownership, unchanged hashes and a direct child of the scripts root.
        if ([IO.Path]::GetDirectoryName($folder) -ne $scriptsRoot) { throw 'Uninstall path validation failed.' }
        Remove-Item -LiteralPath $script -Force
        Remove-Item -LiteralPath $config -Force
        Remove-Item -LiteralPath $folder
        $removed++
    }
    $manifest.scripts = @($kept)
    Write-Json $manifest $manifestPath
    "Removed $removed package-installed scripts. Preserved $($kept.Count) modified scripts. Existing scripts and backups were retained."
}
if ($Action -eq 'Install') { Install-Pack; exit }
if ($Action -eq 'Uninstall') { Uninstall-Pack; exit }
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[Windows.Forms.Application]::EnableVisualStyles()
$form = New-Object Windows.Forms.Form
$form.Text = 'G HUB Operator Script Pack'
$form.ClientSize = New-Object Drawing.Size(570,440)
$form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false
$label = New-Object Windows.Forms.Label
$label.Location = New-Object Drawing.Point(24,20)
$label.Size = New-Object Drawing.Size(522,310)
$label.Font = New-Object Drawing.Font('Segoe UI',10)
$label.Text = "Install $(@($catalog.scripts).Count) named operator Lua templates for the current Windows user.`r`n`r`nRoster checked: $($catalog.rosterVerified). Includes Noor and Solid Snake.`r`n`r`nDefaults: vertical 0, horizontal 0. These templates require calibration; names do not imply tuned recoil.`r`n`r`nFully quit G HUB before continuing. Existing names are skipped, and current scripts are backed up first.`r`n`r`nUninstall removes only unchanged files installed by this package. Modified scripts are preserved."
$form.Controls.Add($label)
$install = New-Object Windows.Forms.Button
$install.Text = 'Install scripts'
$install.Location = New-Object Drawing.Point(24,360)
$install.Size = New-Object Drawing.Size(155,42)
$uninstall = New-Object Windows.Forms.Button
$uninstall.Text = 'Uninstall pack'
$uninstall.Location = New-Object Drawing.Point(197,360)
$uninstall.Size = New-Object Drawing.Size(155,42)
$close = New-Object Windows.Forms.Button
$close.Text = 'Close'
$close.Location = New-Object Drawing.Point(370,360)
$close.Size = New-Object Drawing.Size(155,42)
$install.Add_Click({ try { $install.Enabled=$false; $uninstall.Enabled=$false; $msg=Install-Pack; [Windows.Forms.MessageBox]::Show($msg,'Installation complete') | Out-Null } catch { [Windows.Forms.MessageBox]::Show($_.Exception.Message,'Installation stopped') | Out-Null } finally { $install.Enabled=$true; $uninstall.Enabled=$true } })
$uninstall.Add_Click({ try { $install.Enabled=$false; $uninstall.Enabled=$false; $msg=Uninstall-Pack; [Windows.Forms.MessageBox]::Show($msg,'Uninstall complete') | Out-Null } catch { [Windows.Forms.MessageBox]::Show($_.Exception.Message,'Uninstall stopped') | Out-Null } finally { $install.Enabled=$true; $uninstall.Enabled=$true } })
$close.Add_Click({ $form.Close() })
$form.Controls.AddRange(@($install,$uninstall,$close))
[void]$form.ShowDialog()
