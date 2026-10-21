param(
    [ValidateSet('UI','Install','Uninstall')][string]$Action = 'UI',
    [string]$TargetRoot = (Join-Path $env:LOCALAPPDATA 'LGHUB'),
    [switch]$TestMode,
    [string]$RenderPreview
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
$form.Text = "Jay's G HUB Script Pack"
$form.ClientSize = New-Object Drawing.Size(700,530)
$form.BackColor = [Drawing.ColorTranslator]::FromHtml('#0D141D')
$form.ForeColor = [Drawing.ColorTranslator]::FromHtml('#EDF3F7')
$form.Font = New-Object Drawing.Font('Segoe UI',10)
$form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false
$iconPath=Join-Path $PSScriptRoot 'app.ico'
if (-not (Test-Path -LiteralPath $iconPath)) { $iconPath=Join-Path $PSScriptRoot 'assets\app.ico' }
if (Test-Path -LiteralPath $iconPath) { $form.Icon = New-Object Drawing.Icon($iconPath) }
function Add-Text([string]$Text,[int]$X,[int]$Y,[int]$Width,[int]$Height,[int]$Size,[string]$Color,[bool]$Bold=$false) {
    $label=New-Object Windows.Forms.Label
    $label.Text=$Text
    $label.Location=New-Object Drawing.Point($X,$Y)
    $label.Size=New-Object Drawing.Size($Width,$Height)
    $style=[Drawing.FontStyle]::Regular
    if ($Bold) { $style=[Drawing.FontStyle]::Bold }
    $label.Font=New-Object Drawing.Font('Segoe UI',$Size,$style)
    $label.ForeColor=[Drawing.ColorTranslator]::FromHtml($Color)
    $form.Controls.Add($label)
}
$stripe=New-Object Windows.Forms.Panel
$stripe.Location=New-Object Drawing.Point(0,0)
$stripe.Size=New-Object Drawing.Size(700,5)
$stripe.BackColor=[Drawing.ColorTranslator]::FromHtml('#F3C84B')
$form.Controls.Add($stripe)
Add-Text 'JAY // OPERATOR TOOLS' 30 26 520 25 11 '#F3C84B' $true
Add-Text 'G HUB SCRIPT PACK' 27 61 560 52 27 '#EDF3F7' $true
Add-Text "$(@($catalog.scripts).Count) OPERATORS / WINDOWS / v$($catalog.version)" 30 121 630 26 11 '#78D9EA' $true
Add-Text '01  BACK UP     /     02  INSTALL     /     03  CONFIGURE' 30 171 640 28 11 '#EDF3F7' $true
Add-Text "Named Lua templates for your G HUB profiles. Existing names are skipped; a snapshot protects the scripts you already have." 30 214 640 56 11 '#B5C4D0'
Add-Text 'NEUTRAL DEFAULTS // VERTICAL 0 / HORIZONTAL 0' 30 287 640 27 11 '#F3C84B' $true
Add-Text 'Calibrate the two strengths before use. Advanced timing and controls are preserved. These templates are not operator-tuned recoil profiles.' 30 322 640 54 10 '#B5C4D0'
Add-Text 'BEFORE YOU START: FULLY QUIT G HUB FROM THE TRAY.' 30 391 640 25 10 '#EDF3F7' $true
Add-Text 'Independent project by Jay. Not endorsed by Ubisoft or Logitech.' 30 494 640 22 8 '#7D92A4'
$install = New-Object Windows.Forms.Button
$install.Text = 'INSTALL SCRIPTS'
$install.Location = New-Object Drawing.Point(30,436)
$install.Size = New-Object Drawing.Size(235,42)
$install.BackColor=[Drawing.ColorTranslator]::FromHtml('#F3C84B')
$install.ForeColor=[Drawing.ColorTranslator]::FromHtml('#0D141D')
$uninstall = New-Object Windows.Forms.Button
$uninstall.Text = 'UNINSTALL PACK'
$uninstall.Location = New-Object Drawing.Point(279,436)
$uninstall.Size = New-Object Drawing.Size(235,42)
$uninstall.BackColor=[Drawing.ColorTranslator]::FromHtml('#1C2C3B')
$close = New-Object Windows.Forms.Button
$close.Text = 'CLOSE'
$close.Location = New-Object Drawing.Point(528,436)
$close.Size = New-Object Drawing.Size(142,42)
$close.BackColor=[Drawing.ColorTranslator]::FromHtml('#1C2C3B')
foreach ($button in @($install,$uninstall,$close)) {
    $button.FlatStyle=[Windows.Forms.FlatStyle]::Flat
    $button.FlatAppearance.BorderSize=0
    $button.Font=New-Object Drawing.Font('Segoe UI',10,[Drawing.FontStyle]::Bold)
    $button.Cursor=[Windows.Forms.Cursors]::Hand
}
$install.Add_Click({ try { $install.Enabled=$false; $uninstall.Enabled=$false; $msg=Install-Pack; [Windows.Forms.MessageBox]::Show($msg,'Installation complete') | Out-Null } catch { [Windows.Forms.MessageBox]::Show($_.Exception.Message,'Installation stopped') | Out-Null } finally { $install.Enabled=$true; $uninstall.Enabled=$true } })
$uninstall.Add_Click({ try { $install.Enabled=$false; $uninstall.Enabled=$false; $msg=Uninstall-Pack; [Windows.Forms.MessageBox]::Show($msg,'Uninstall complete') | Out-Null } catch { [Windows.Forms.MessageBox]::Show($_.Exception.Message,'Uninstall stopped') | Out-Null } finally { $install.Enabled=$true; $uninstall.Enabled=$true } })
$close.Add_Click({ $form.Close() })
$form.Controls.AddRange(@($install,$uninstall,$close))
if ($RenderPreview) {
    $form.ShowInTaskbar=$false
    $form.StartPosition='Manual'
    $form.Location=New-Object Drawing.Point(-10000,-10000)
    $form.Show()
    [Windows.Forms.Application]::DoEvents()
    $form.Refresh()
    $bitmap=New-Object Drawing.Bitmap($form.Width,$form.Height)
    try { $form.DrawToBitmap($bitmap,(New-Object Drawing.Rectangle(0,0,$form.Width,$form.Height))); $bitmap.Save([IO.Path]::GetFullPath($RenderPreview),[Drawing.Imaging.ImageFormat]::Png) }
    finally { $bitmap.Dispose(); $form.Dispose() }
    exit
}
[void]$form.ShowDialog()
