param(
    [ValidateSet('UI','Install','Uninstall')][string]$Action = 'UI',
    [string]$TargetRoot = (Join-Path $env:LOCALAPPDATA 'LGHUB'),
    [switch]$TestMode,
    [string]$RenderPreview,
    [string]$Operators = '*',
    [string]$PreviewStatus,
    [string]$PreviewFilter
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
function Get-SelectedScripts([string]$Selection) {
    if ($Selection.Trim() -eq '*') { return @($catalog.scripts) }
    $tokens=@($Selection.Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_ })
    if ($tokens.Count -eq 0) { throw 'Select at least one operator before installing.' }
    $names=@{}
    foreach ($token in $tokens) {
        $matches=@($catalog.scripts | Where-Object { $_.name -eq $token -or @($_.aliases) -contains $token })
        if ($matches.Count -ne 1) { throw ('Unknown operator: ' + $token) }
        $names[$matches[0].name]=$true
    }
    @($catalog.scripts | Where-Object { $names.ContainsKey($_.name) })
}
function Install-Pack {
    param([string]$Selection=$Operators)
    $selectedScripts=@(Get-SelectedScripts $Selection)
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
        foreach ($item in $selectedScripts) {
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
$form=New-Object Windows.Forms.Form
$form.Text="Jay's G HUB Script Pack"
$form.ClientSize=New-Object Drawing.Size(760,720)
$form.BackColor=[Drawing.ColorTranslator]::FromHtml('#0D141D')
$form.ForeColor=[Drawing.ColorTranslator]::FromHtml('#EDF3F7')
$form.Font=New-Object Drawing.Font('Segoe UI',10)
$form.StartPosition='CenterScreen'
$form.FormBorderStyle='FixedDialog'
$form.MaximizeBox=$false
$iconPath=Join-Path $PSScriptRoot 'app.ico'
if (-not (Test-Path -LiteralPath $iconPath)) { $iconPath=Join-Path $PSScriptRoot 'assets\app.ico' }
if (Test-Path -LiteralPath $iconPath) { $form.Icon=New-Object Drawing.Icon($iconPath) }
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
function New-Button([string]$Text,[int]$X,[int]$Y,[int]$Width,[int]$Height,[bool]$Primary=$false) {
    $button=New-Object Windows.Forms.Button
    $button.Text=$Text
    $button.Location=New-Object Drawing.Point($X,$Y)
    $button.Size=New-Object Drawing.Size($Width,$Height)
    $button.FlatStyle=[Windows.Forms.FlatStyle]::Flat
    $button.FlatAppearance.BorderSize=0
    $button.Font=New-Object Drawing.Font('Segoe UI',10,[Drawing.FontStyle]::Bold)
    $button.Cursor=[Windows.Forms.Cursors]::Hand
    $button.BackColor=[Drawing.ColorTranslator]::FromHtml('#1C2C3B')
    if ($Primary) {
        $button.BackColor=[Drawing.ColorTranslator]::FromHtml('#F3C84B')
        $button.ForeColor=[Drawing.ColorTranslator]::FromHtml('#0D141D')
    }
    $button
}
$stripe=New-Object Windows.Forms.Panel
$stripe.Location=New-Object Drawing.Point(0,0)
$stripe.Size=New-Object Drawing.Size(760,5)
$stripe.BackColor=[Drawing.ColorTranslator]::FromHtml('#F3C84B')
$form.Controls.Add($stripe)
Add-Text 'JAY // OPERATOR TOOLS' 30 23 650 24 11 '#F3C84B' $true
Add-Text 'CHOOSE YOUR OPERATORS' 26 57 710 48 25 '#EDF3F7' $true
Add-Text "G HUB SCRIPT PACK / v$($catalog.version) / $(@($catalog.scripts).Count) TEMPLATES" 30 113 700 25 11 '#78D9EA' $true
Add-Text 'Install a few or the full roster. Existing names and tuning are preserved.' 30 151 700 28 10 '#B5C4D0'
$search=New-Object Windows.Forms.TextBox
$search.Location=New-Object Drawing.Point(30,198)
$search.Size=New-Object Drawing.Size(425,30)
$search.BackColor=[Drawing.ColorTranslator]::FromHtml('#152331')
$search.ForeColor=$form.ForeColor
$search.BorderStyle='FixedSingle'
$search.AccessibleName='Search operators'
Add-Text 'SEARCH OPERATORS' 30 179 425 18 8 '#7D92A4' $true
$form.Controls.Add($search)
$all=New-Button 'SELECT ALL' 470 196 130 32
$none=New-Button 'CLEAR' 612 196 118 32
$form.Controls.AddRange(@($all,$none))
$list=New-Object Windows.Forms.CheckedListBox
$list.Location=New-Object Drawing.Point(30,246)
$list.Size=New-Object Drawing.Size(700,200)
$list.BackColor=[Drawing.ColorTranslator]::FromHtml('#152331')
$list.ForeColor=$form.ForeColor
$list.BorderStyle='FixedSingle'
$list.CheckOnClick=$true
$list.IntegralHeight=$false
$list.Font=New-Object Drawing.Font('Segoe UI',11)
$list.AccessibleName='Operators to install'
$form.Controls.Add($list)
$summary=New-Object Windows.Forms.Label
$summary.Location=New-Object Drawing.Point(30,458)
$summary.Size=New-Object Drawing.Size(700,25)
$summary.ForeColor=[Drawing.ColorTranslator]::FromHtml('#78D9EA')
$summary.Font=New-Object Drawing.Font('Segoe UI',11,[Drawing.FontStyle]::Bold)
$form.Controls.Add($summary)
Add-Text 'NEUTRAL VALUES // VERTICAL 0 / HORIZONTAL 0' 30 499 700 23 10 '#F3C84B' $true
Add-Text 'Selection applies to installation only. Uninstall checks every script owned by this pack and preserves edited files. Fully quit G HUB before continuing.' 30 531 700 47 10 '#B5C4D0'
$statusLabel=New-Object Windows.Forms.Label
$statusLabel.Location=New-Object Drawing.Point(30,584)
$statusLabel.Size=New-Object Drawing.Size(700,39)
$statusLabel.ForeColor=[Drawing.ColorTranslator]::FromHtml('#78D9EA')
$statusLabel.Font=New-Object Drawing.Font('Segoe UI',9)
$statusLabel.Text='Snapshots are saved before installation. Calibrate each script after selecting it in G HUB.'
if ($PreviewStatus) { $statusLabel.Text=$PreviewStatus }
$form.Controls.Add($statusLabel)
$install=New-Button 'INSTALL SELECTED' 30 630 270 43 $true
$uninstall=New-Button 'UNINSTALL PACK' 314 630 240 43
$close=New-Button 'CLOSE' 568 630 162 43
$form.Controls.AddRange(@($install,$uninstall,$close))
Add-Text 'Independent project by Jay. Not endorsed by Ubisoft or Logitech.' 30 689 700 22 8 '#7D92A4'
$script:selection=@{}
foreach ($item in @(Get-SelectedScripts $Operators)) { $script:selection[$item.name]=$true }
$script:rebuilding=$false
function Update-SelectionSummary {
    $summary.Text="$($script:selection.Count) OF $(@($catalog.scripts).Count) SELECTED  /  $($list.Items.Count) SHOWN"
    $install.Enabled=$script:selection.Count -gt 0
}
function Refresh-OperatorList {
    $script:rebuilding=$true
    $list.BeginUpdate()
    try {
        $list.Items.Clear()
        foreach ($item in @($catalog.scripts | Sort-Object name)) {
            $visible=$item.name.IndexOf($search.Text,[StringComparison]::OrdinalIgnoreCase) -ge 0
            if (-not $visible) { $visible=@($item.aliases | Where-Object { $_.IndexOf($search.Text,[StringComparison]::OrdinalIgnoreCase) -ge 0 }).Count -gt 0 }
            if ($visible) { [void]$list.Items.Add($item.name,$script:selection.ContainsKey($item.name)) }
        }
    } finally { $list.EndUpdate();$script:rebuilding=$false }
    Update-SelectionSummary
}
$list.Add_ItemCheck({
    param($sender,$eventArgs)
    if ($script:rebuilding) { return }
    $name=$sender.Items[$eventArgs.Index].ToString()
    if ($eventArgs.NewValue -eq [Windows.Forms.CheckState]::Checked) { $script:selection[$name]=$true }
    else { $script:selection.Remove($name) }
    Update-SelectionSummary
})
$search.Add_TextChanged({Refresh-OperatorList})
$all.Add_Click({foreach ($item in $catalog.scripts) {$script:selection[$item.name]=$true};Refresh-OperatorList})
$none.Add_Click({$script:selection.Clear();Refresh-OperatorList})
$install.Add_Click({
    try {
        $install.Enabled=$false;$uninstall.Enabled=$false
        $msg=Install-Pack -Selection (($script:selection.Keys | Sort-Object) -join ',')
        $statusLabel.Text=($msg -split "`r?`n")[0]
        [Windows.Forms.MessageBox]::Show($msg,'Installation complete') | Out-Null
    } catch { [Windows.Forms.MessageBox]::Show($_.Exception.Message,'Installation stopped') | Out-Null }
    finally {Update-SelectionSummary;$uninstall.Enabled=$true}
})
$uninstall.Add_Click({
    try {
        $install.Enabled=$false;$uninstall.Enabled=$false
        $msg=Uninstall-Pack
        $statusLabel.Text=$msg
        [Windows.Forms.MessageBox]::Show($msg,'Uninstall complete') | Out-Null
    } catch { [Windows.Forms.MessageBox]::Show($_.Exception.Message,'Uninstall stopped') | Out-Null }
    finally {Update-SelectionSummary;$uninstall.Enabled=$true}
})
$close.Add_Click({$form.Close()})
Refresh-OperatorList
if ($RenderPreview -and $PreviewFilter) { $search.Text=$PreviewFilter }
if ($RenderPreview) {
    $form.ShowInTaskbar=$false
    $form.StartPosition='Manual'
    $form.Location=New-Object Drawing.Point(-10000,-10000)
    $form.Show()
    [Windows.Forms.Application]::DoEvents()
    $form.Refresh()
    $bitmap=New-Object Drawing.Bitmap($form.Width,$form.Height)
    try {$form.DrawToBitmap($bitmap,(New-Object Drawing.Rectangle(0,0,$form.Width,$form.Height)));$bitmap.Save([IO.Path]::GetFullPath($RenderPreview),[Drawing.Imaging.ImageFormat]::Png)}
    finally {$bitmap.Dispose();$form.Dispose()}
    exit
}
[void]$form.ShowDialog()
