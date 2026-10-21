param([string]$TargetDirectory=(Join-Path $PSScriptRoot 'dist'))
$ErrorActionPreference='Stop'
$target=[IO.Path]::GetFullPath($TargetDirectory)
$reportPath=Join-Path $target 'malware-scan-report.json'
$engine='Microsoft Defender Antivirus'
try {
    # Only an ephemeral GitHub runner may be reconfigured. Never change local AV settings.
    if ($env:GITHUB_ACTIONS -eq 'true') {
        $policy='HKLM:\SOFTWARE\Policies\Microsoft\Windows Advanced Threat Protection'
        if (Test-Path -LiteralPath $policy) { Set-ItemProperty -LiteralPath $policy -Name ForceDefenderPassiveMode -Value 0 -Type DWord }
        $service=Get-Service WinDefend
        if ($service.Status -ne 'Running') { Start-Service WinDefend }
        Set-MpPreference -DisableArchiveScanning $false -DisableScriptScanning $false -DisableRealtimeMonitoring $false
        foreach ($excluded in @((Get-MpPreference).ExclusionPath)) {
            if ($excluded) { Remove-MpPreference -ExclusionPath $excluded }
        }
    }
    $status=Get-MpComputerStatus
    if (-not $status.AMServiceEnabled -or -not $status.AntivirusEnabled) { throw 'Defender is not active; no valid clean scan can be reported.' }
    $platform=Get-ChildItem -LiteralPath (Join-Path $env:ProgramData 'Microsoft\Windows Defender\Platform') -Directory -ErrorAction SilentlyContinue | Sort-Object Name -Descending | Select-Object -First 1
    $scanner=Join-Path $env:ProgramFiles 'Windows Defender\MpCmdRun.exe'
    if ($platform -and (Test-Path -LiteralPath (Join-Path $platform.FullName 'MpCmdRun.exe'))) { $scanner=Join-Path $platform.FullName 'MpCmdRun.exe' }
    $updated=$false
    for ($attempt=1; $attempt -le 3; $attempt++) {
        $updateLog=@(& $scanner -SignatureUpdate -MMPC 2>&1)
        $updateCode=$LASTEXITCODE
        Write-Output ($updateLog -join "`n")
        if ($updateCode -eq 0) { $updated=$true; break }
        if ($attempt -lt 3) { Start-Sleep -Seconds 5 }
    }
    if (-not $updated) { throw 'Defender signature update failed; no clean scan can be reported.' }
    $status=Get-MpComputerStatus
    if (-not $status.AntivirusSignatureLastUpdated -or $status.AntivirusSignatureLastUpdated -lt (Get-Date).AddDays(-2)) { throw 'Defender security intelligence is older than two days.' }
    $files=@(Get-ChildItem -LiteralPath $target -Filter '*.exe' -File)
    if ($files.Count -ne 1) { throw 'Expected exactly one release executable.' }
    $checks=@()
    foreach ($path in @($files[0].FullName,(Join-Path $PSScriptRoot 'payload'),(Join-Path $PSScriptRoot 'Installer.ps1'))) {
        $log=@(& $scanner -Scan -ScanType 3 -File $path -DisableRemediation 2>&1)
        $code=$LASTEXITCODE
        $logText=($log -join "`n")
        Write-Output $logText
        if ($code -ne 0 -or $logText -match '(?im)scan failed|error code') { throw "Defender scan did not pass (exit $code)." }
        $checks+=[ordered]@{target=([IO.Path]::GetFileName($path));exitCode=$code;output=$logText.Replace($PSScriptRoot,'<source>').Replace($target,'<dist>')}
    }
    $hash=(Get-FileHash -LiteralPath $files[0].FullName -Algorithm SHA256).Hash.ToLowerInvariant()
    $report=[ordered]@{result='No threats detected';engine=$engine;scannedAtUtc=(Get-Date).ToUniversalTime().ToString('o');signatureVersion=$status.AntivirusSignatureVersion;signatureUpdatedUtc=$status.AntivirusSignatureLastUpdated.ToUniversalTime().ToString('o');engineVersion=$status.AMEngineVersion;file=$files[0].Name;sha256=$hash;checks=$checks;commit=$env:GITHUB_SHA;runUrl="https://github.com/$env:GITHUB_REPOSITORY/actions/runs/$env:GITHUB_RUN_ID";scope='Single-engine static/on-demand scan of the exact executable, extracted Lua payload and installer script. Not a safety guarantee or code signature.'}
    [IO.File]::WriteAllText($reportPath,($report|ConvertTo-Json -Depth 10),(New-Object Text.UTF8Encoding($false)))
} catch {
    $report=[ordered]@{result='Scan failed or unavailable';engine=$engine;error=$_.Exception.Message;scannedAtUtc=(Get-Date).ToUniversalTime().ToString('o')}
    [IO.File]::WriteAllText($reportPath,($report|ConvertTo-Json -Depth 5),(New-Object Text.UTF8Encoding($false)))
    throw
}
