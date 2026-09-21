[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$InputPath,

    [Parameter(Position = 1)]
    [string]$OutputDirectory,

    [switch]$VerifyOnly
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

$ExpectedManifestSha256 = '6520a8093ebbbdea6e3da67b61723732c438850dbbe947c88de31971f9d224c3'
$ExpectedHostPayloadSha256 = 'e8f8f8699236a27b6573250df9047b78f61e6b31b59985492859a45192d13473'
$ExpectedSchedulerPayloadSha256 = 'c3c6519ff86488fb483074b98f97143de623be99c4da0508fb4a2b733ff4f529'
$ExpectedDx12PayloadSha256 = '46080a0c060b179bc7a5f0344b2eb8b9b0431eb7f8a67273a1a5bab762b6aee5'
$ExpectedInputSha256 = '7d49351661573a9ee27c8578ecdc66678289d2bdb531b43a1185df76ddb16b54'
$ExpectedPreSchedulerSha256 = 'd5f001d863429fc3f9c29e8aa4557bb5660da1d1f9194effb239ba1e0b56d859'
$ExpectedHostSha256 = '134fdb5d5844e0df6663c04a2f7b792c375a21b47e9f85637a2ce95dcdf77148'
$ExpectedDx12Sha256 = '46080a0c060b179bc7a5f0344b2eb8b9b0431eb7f8a67273a1a5bab762b6aee5'
$ExpectedInputSize = 138752
$ExpectedPreSchedulerSize = 146432
$ExpectedHostSize = 163328
$ExpectedDx12Size = 29184
$ExpectedBaseChangedBytes = 341
$ExpectedSchedulerChangedBytes = 113
$CreatedOutputs = New-Object 'System.Collections.Generic.List[string]'

function Assert-Condition {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

function Get-ByteSha256 {
    param([byte[]]$Value)
    $Hasher = [System.Security.Cryptography.SHA256]::Create()
    try {
        return ([System.BitConverter]::ToString($Hasher.ComputeHash($Value))).Replace('-', '').ToLowerInvariant()
    }
    finally { $Hasher.Dispose() }
}

function Convert-HexToBytes {
    param([object]$Value, [string]$Description)
    Assert-Condition ($Value -is [string]) "Invalid hexadecimal data for $Description."
    $Hex = [string]$Value
    Assert-Condition (($Hex.Length -gt 0) -and (($Hex.Length % 2) -eq 0)) "Invalid hexadecimal data for $Description."
    [byte[]]$Result = New-Object byte[] ($Hex.Length / 2)
    for ($Index = 0; $Index -lt $Result.Length; $Index++) {
        try { $Result[$Index] = [Convert]::ToByte($Hex.Substring($Index * 2, 2), 16) }
        catch { throw "Invalid hexadecimal data for $Description." }
    }
    return $Result
}

function Get-FullPath {
    param([string]$Value)
    return [System.IO.Path]::GetFullPath($Value.Trim().Trim('"'))
}

function Write-NewFile {
    param([string]$Path, [byte[]]$Value)
    $Stream = [System.IO.File]::Open($Path, [System.IO.FileMode]::CreateNew, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None)
    $Complete = $false
    try {
        $Stream.Write($Value, 0, $Value.Length)
        $Stream.Flush($true)
        $Complete = $true
    }
    finally {
        $Stream.Dispose()
        if ((-not $Complete) -and [System.IO.File]::Exists($Path)) {
            [System.IO.File]::Delete($Path)
        }
    }
}

try {
    $ScriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
    if ([string]::IsNullOrWhiteSpace($InputPath)) {
        $AdjacentInput = Join-Path $ScriptDirectory 'foo_enhanced_spectrum_analyzer.dll'
        if ([System.IO.File]::Exists($AdjacentInput)) { $InputPath = $AdjacentInput }
        else { $InputPath = Read-Host 'Path to your original foo_enhanced_spectrum_analyzer 1.9.2.0 x64 DLL' }
    }
    Assert-Condition (-not [string]::IsNullOrWhiteSpace($InputPath)) 'No input DLL was provided.'
    $ResolvedInput = Get-FullPath $InputPath
    Assert-Condition ([System.IO.File]::Exists($ResolvedInput)) "Input DLL not found: $ResolvedInput"
    if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
        $ResolvedOutputDirectory = Join-Path ([System.IO.Path]::GetDirectoryName($ResolvedInput)) 'patched'
    }
    else { $ResolvedOutputDirectory = Get-FullPath $OutputDirectory }
    $HostOutput = Join-Path $ResolvedOutputDirectory 'foo_enhanced_spectrum_analyzer.dll'
    $Dx12Output = Join-Path $ResolvedOutputDirectory 'foo_enhanced_spectrum_analyzer_dx12.dll'
    Assert-Condition (-not $ResolvedInput.Equals($HostOutput, [System.StringComparison]::OrdinalIgnoreCase)) 'Input and host-output paths must be different.'

    [byte[]]$ManifestRaw = [System.IO.File]::ReadAllBytes((Join-Path $ScriptDirectory 'PATCH-MANIFEST.json'))
    Assert-Condition ((Get-ByteSha256 $ManifestRaw) -eq $ExpectedManifestSha256) 'PATCH-MANIFEST.json failed its integrity check. Re-extract the release ZIP.'
    $Manifest = ([System.Text.Encoding]::UTF8.GetString($ManifestRaw)) | ConvertFrom-Json
    [byte[]]$HostPayload = [System.IO.File]::ReadAllBytes((Join-Path $ScriptDirectory 'host_patch_payload.bin'))
    [byte[]]$SchedulerPayload = [System.IO.File]::ReadAllBytes((Join-Path $ScriptDirectory 'scheduler_patch_payload.bin'))
    [byte[]]$Dx12Payload = [System.IO.File]::ReadAllBytes((Join-Path $ScriptDirectory 'dx12_runtime_payload.bin'))
    Assert-Condition ((Get-ByteSha256 $HostPayload) -eq $ExpectedHostPayloadSha256) 'host_patch_payload.bin failed its integrity check. Re-extract the release ZIP.'
    Assert-Condition ((Get-ByteSha256 $SchedulerPayload) -eq $ExpectedSchedulerPayloadSha256) 'scheduler_patch_payload.bin failed its integrity check. Re-extract the release ZIP.'
    Assert-Condition ((Get-ByteSha256 $Dx12Payload) -eq $ExpectedDx12PayloadSha256) 'dx12_runtime_payload.bin failed its integrity check. Re-extract the release ZIP.'

    Assert-Condition ($Manifest.format -eq 'devilhood-esa-patch-v3') 'Unsupported patch-manifest format.'
    Assert-Condition ($Manifest.release -eq '1.9.2.9-community-dx12-x64-scheduler-hardened') 'Unexpected patch release identity.'
    Assert-Condition ($Manifest.patcher_version -eq '3.0.0') 'Unexpected patcher version.'
    Assert-Condition ($Manifest.producer -eq 'DeViLhoOD') 'Unexpected patch producer identity.'
    Assert-Condition (([int]$Manifest.host.input.size -eq $ExpectedInputSize) -and ($Manifest.host.input.sha256 -eq $ExpectedInputSha256)) 'The manifest has unexpected input properties.'
    Assert-Condition (([int]$Manifest.host.pre_scheduler_output.size -eq $ExpectedPreSchedulerSize) -and ($Manifest.host.pre_scheduler_output.sha256 -eq $ExpectedPreSchedulerSha256)) 'The manifest has unexpected in-memory base-transform properties.'
    Assert-Condition (([int]$Manifest.host.output.size -eq $ExpectedHostSize) -and ($Manifest.host.output.sha256 -eq $ExpectedHostSha256)) 'The manifest has unexpected final host-output properties.'

    [byte[]]$Source = [System.IO.File]::ReadAllBytes($ResolvedInput)
    Assert-Condition ($Source.Length -eq $ExpectedInputSize) 'The input DLL has the wrong size.'
    $ActualInputSha256 = Get-ByteSha256 $Source
    Assert-Condition ($ActualInputSha256 -eq $ExpectedInputSha256) "The input DLL is not the exact audited x64 1.9.2.0 build.`nExpected SHA-256: $ExpectedInputSha256`nActual SHA-256:   $ActualInputSha256"

    # Reconstruct the previously audited Community DX12 host in memory only.
    [byte[]]$Base = New-Object byte[] $ExpectedPreSchedulerSize
    [System.Array]::Copy($Source, 0, $Base, 0, $Source.Length)
    $PreviousEnd = 0
    $ChangedBytes = 0
    $InheritedWrites = @($Manifest.host.base_transform.inherited_writes)
    Assert-Condition ($InheritedWrites.Count -gt 0) 'The base write list is missing.'
    for ($Index = 0; $Index -lt $InheritedWrites.Count; $Index++) {
        $Entry = $InheritedWrites[$Index]
        $Offset = [int]$Entry.offset
        [byte[]]$Replacement = Convert-HexToBytes $Entry.replacement_hex "base write $Index"
        $End = $Offset + $Replacement.Length
        Assert-Condition (($Offset -ge $PreviousEnd) -and ($End -le $ExpectedInputSize)) "Base write $Index is overlapping or out of bounds."
        [System.Array]::Copy($Replacement, 0, $Base, $Offset, $Replacement.Length)
        $PreviousEnd = $End
        $ChangedBytes += $Replacement.Length
    }
    Assert-Condition ($ChangedBytes -eq $ExpectedBaseChangedBytes) 'The base write list has an unexpected changed-byte count.'

    $Fill = $Manifest.host.base_transform.layout.patch_fill
    Assert-Condition (([int]$Fill.output_offset -eq 0x21E00) -and ([int]$Fill.length -eq 0x1C00) -and ([int]$Fill.byte -eq 0xCC)) 'The base .patch fill layout is invalid.'
    for ($Index = 0x21E00; $Index -lt 0x23A00; $Index++) { $Base[$Index] = 0xCC }
    $Zero = $Manifest.host.base_transform.layout.patch_data_zero
    Assert-Condition (([int]$Zero.output_offset -eq 0x23A00) -and ([int]$Zero.length -eq 0x200)) 'The base .patchd zero-fill layout is invalid.'
    [System.Array]::Clear($Base, 0x23A00, 0x200)

    $PayloadCursor = 0
    $PreviousOutputEnd = 0
    $Segments = @($Manifest.host_payload.segments)
    Assert-Condition ($Segments.Count -gt 0) 'Host payload segments are missing.'
    for ($Index = 0; $Index -lt $Segments.Count; $Index++) {
        $Segment = $Segments[$Index]
        $PayloadOffset = [int]$Segment.payload_offset
        $OutputOffset = [int]$Segment.output_offset
        $Length = [int]$Segment.length
        Assert-Condition (($Length -gt 0) -and ($PayloadOffset -eq $PayloadCursor) -and ($OutputOffset -ge $PreviousOutputEnd) -and (($PayloadOffset + $Length) -le $HostPayload.Length) -and ($OutputOffset -ge 0x21E00) -and (($OutputOffset + $Length) -le 0x23A00)) "Host payload segment $Index is overlapping or out of bounds."
        [System.Array]::Copy($HostPayload, $PayloadOffset, $Base, $OutputOffset, $Length)
        $PayloadCursor += $Length
        $PreviousOutputEnd = $OutputOffset + $Length
    }
    Assert-Condition ($PayloadCursor -eq $HostPayload.Length) 'The host payload contains unreferenced bytes.'

    $Dialog = $Manifest.host.base_transform.layout.dialog_copy
    $DialogSource = [int]$Dialog.input_offset
    $DialogOutput = [int]$Dialog.output_offset
    $DialogLength = [int]$Dialog.length
    Assert-Condition (($DialogSource -eq 0x1FF60) -and ($DialogOutput -eq 0x22600) -and ($DialogLength -eq 0x12F4)) 'The dialog-copy layout is invalid.'
    Assert-Condition (($Source[$DialogSource] -eq 1) -and ($Source[$DialogSource + 1] -eq 0) -and ($Source[$DialogSource + 2] -eq 255) -and ($Source[$DialogSource + 3] -eq 255) -and ([System.BitConverter]::ToUInt16($Source, $DialogSource + 16) -eq 110)) 'The audited source dialog invariants do not match.'
    [System.Array]::Copy($Source, $DialogSource, $Base, $DialogOutput, $DialogLength)

    $PreviousEnd = 0
    $DialogWrites = @($Manifest.host.base_transform.layout.dialog_writes)
    for ($Index = 0; $Index -lt $DialogWrites.Count; $Index++) {
        $Entry = $DialogWrites[$Index]
        $Relative = [int]$Entry.relative_offset
        [byte[]]$Replacement = Convert-HexToBytes $Entry.replacement_hex "dialog write $Index"
        $End = $Relative + $Replacement.Length
        Assert-Condition (($Relative -ge $PreviousEnd) -and ($End -le $DialogLength)) "Dialog write $Index is overlapping or out of bounds."
        [System.Array]::Copy($Replacement, 0, $Base, $DialogOutput + $Relative, $Replacement.Length)
        $PreviousEnd = $End
    }
    $Append = $Manifest.host.base_transform.layout.dialog_append
    [byte[]]$AppendData = Convert-HexToBytes $Append.data_hex 'dialog append'
    Assert-Condition (([int]$Append.relative_offset -eq $DialogLength) -and ($AppendData.Length -eq 0x3C)) 'The dialog append layout is invalid.'
    [System.Array]::Copy($AppendData, 0, $Base, $DialogOutput + $DialogLength, $AppendData.Length)
    Assert-Condition ([System.BitConverter]::ToUInt16($Base, $DialogOutput + 16) -eq 111) 'The patched dialog item count is invalid.'
    Assert-Condition ((Get-ByteSha256 $Base) -eq $ExpectedPreSchedulerSha256) 'The in-memory base reconstruction failed verification.'

    # Apply the final scheduler hardening in memory; never write the intermediate host.
    [byte[]]$Host = New-Object byte[] $ExpectedHostSize
    [System.Array]::Copy($Base, 0, $Host, 0, $Base.Length)
    $PreviousEnd = 0
    $ChangedBytes = 0
    $SchedulerWrites = @($Manifest.host.scheduler_hardening.overlap_writes)
    Assert-Condition ($SchedulerWrites.Count -gt 0) 'The scheduler write list is missing.'
    for ($Index = 0; $Index -lt $SchedulerWrites.Count; $Index++) {
        $Entry = $SchedulerWrites[$Index]
        $Offset = [int]$Entry.offset
        [byte[]]$Replacement = Convert-HexToBytes $Entry.replacement_hex "scheduler write $Index"
        $End = $Offset + $Replacement.Length
        Assert-Condition (($Offset -ge $PreviousEnd) -and ($End -le $ExpectedPreSchedulerSize)) "Scheduler write $Index is overlapping or out of bounds."
        [System.Array]::Copy($Replacement, 0, $Host, $Offset, $Replacement.Length)
        $PreviousEnd = $End
        $ChangedBytes += $Replacement.Length
    }
    Assert-Condition ($ChangedBytes -eq $ExpectedSchedulerChangedBytes) 'The scheduler write list has an unexpected changed-byte count.'

    $SchedulerAppend = $Manifest.host.scheduler_hardening.append
    Assert-Condition (([int]$SchedulerAppend.output_offset -eq $ExpectedPreSchedulerSize) -and ([int]$SchedulerAppend.length -eq $SchedulerPayload.Length) -and ($SchedulerAppend.payload_sha256 -eq $ExpectedSchedulerPayloadSha256)) 'The scheduler append layout is invalid.'
    [System.Array]::Copy($SchedulerPayload, 0, $Host, $ExpectedPreSchedulerSize, $SchedulerPayload.Length)

    Assert-Condition ((Get-ByteSha256 $Host) -eq $ExpectedHostSha256) 'The generated final host DLL failed final verification. No output was written.'
    Assert-Condition (($Dx12Payload.Length -eq $ExpectedDx12Size) -and ((Get-ByteSha256 $Dx12Payload) -eq $ExpectedDx12Sha256) -and ($Dx12Payload[0] -eq 0x4D) -and ($Dx12Payload[1] -eq 0x5A)) 'The DX12 runtime failed final verification. No output was written.'

    if ($VerifyOnly) {
        Write-Host 'PASS: exact upstream input and all payloads reconstruct the final release in one operation.' -ForegroundColor Green
        Write-Host "Host SHA-256: $ExpectedHostSha256"
        Write-Host "DX12 SHA-256: $ExpectedDx12Sha256"
        exit 0
    }

    Assert-Condition (-not [System.IO.File]::Exists($HostOutput)) "Refusing to overwrite an existing output file:`n$HostOutput"
    Assert-Condition (-not [System.IO.File]::Exists($Dx12Output)) "Refusing to overwrite an existing output file:`n$Dx12Output"
    [void][System.IO.Directory]::CreateDirectory($ResolvedOutputDirectory)
    Write-NewFile $HostOutput $Host
    $CreatedOutputs.Add($HostOutput)
    Write-NewFile $Dx12Output $Dx12Payload
    $CreatedOutputs.Add($Dx12Output)

    Write-Host 'PASS: Enhanced Spectrum Analyzer 1.9.2.9 Community DX12 was generated directly from upstream 1.9.2.0.' -ForegroundColor Green
    Write-Host "Host:  $HostOutput"
    Write-Host "DX12:  $Dx12Output"
    Write-Host "Host SHA-256: $ExpectedHostSha256"
    Write-Host "DX12 SHA-256: $ExpectedDx12Sha256"
    Write-Host 'The original DLL was not modified.'
    $CreatedOutputs.Clear()
    exit 0
}
catch {
    for ($Index = $CreatedOutputs.Count - 1; $Index -ge 0; $Index--) {
        if ([System.IO.File]::Exists($CreatedOutputs[$Index])) {
            [System.IO.File]::Delete($CreatedOutputs[$Index])
        }
    }
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
