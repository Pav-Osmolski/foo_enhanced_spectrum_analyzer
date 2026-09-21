# Patching, Installation and Rollback

## Generate the final matched pair in one step

1. Exit foobar2000 completely.
2. Extract the complete public patcher ZIP to a normal writable folder.
3. Supply the exact untouched **1.9.2.0 x64** DLL (`7d49351661573a9ee27c8578ecdc66678289d2bdb531b43a1185df76ddb16b54`):
   - place it beside the scripts as `foo_enhanced_spectrum_analyzer.dll` and double-click `Patch-EnhancedSpectrumAnalyzer.cmd`; or
   - drag the DLL onto `Patch-EnhancedSpectrumAnalyzer.cmd`.
4. The patcher reconstructs the complete final scheduler-hardened 1.9.2.9 host in memory, verifies it, and writes the final matched pair to `patched\`.

There is no intermediate installation or second patching stage.

## Install

Back up the existing component directory, then copy both generated DLLs into:

`profile\user-components-x64\foo_enhanced_spectrum_analyzer\`

- `foo_enhanced_spectrum_analyzer.dll`
- `foo_enhanced_spectrum_analyzer_dx12.dll`

Keep both filenames unchanged and do not mix them with earlier test/community builds.

## Command-line use

PowerShell:

```powershell
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass `
  -File .\Patch-EnhancedSpectrumAnalyzer.ps1 `
  -InputPath "C:\path\to\foo_enhanced_spectrum_analyzer.dll"
```

Python 3.9+ alternative:

```text
python patch_enhanced_spectrum_analyzer.py /path/to/original.dll
python patch_enhanced_spectrum_analyzer.py /path/to/original.dll --verify-only
python patch_enhanced_spectrum_analyzer.py /path/to/original.dll --output-dir /path/to/output
```

## Rollback

Exit foobar2000, remove the generated pair and restore the complete backed-up component directory.
