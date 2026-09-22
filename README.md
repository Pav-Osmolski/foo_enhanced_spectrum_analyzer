# Enhanced Spectrum Analyzer 1.9.3.0 - Community DX12 x64 Public Patcher

Original **Enhanced Spectrum Analyzer** by **Crossover**. Community maintenance, DX12 enhancement work and release packaging by **DeViLhoOD**.

This is an unofficial x64 community continuation built from the upstream 1.9.2.0 component. It is not affiliated with or endorsed by Crossover, foobar2000 or its developers.

Special thanks to **StyxCrosser** for extensive compatibility and regression testing of the final scheduler, anti-aliasing, fullscreen and unsupported-DX12 fixes.

## One-step public patcher

This package patches the **exact untouched upstream 1.9.2.0 x64 DLL directly to the final runtime-validated 1.9.3.0 build in one operation**. No earlier community build and no second patching stage are required.

Required input:

| Property | Value |
|---|---|
| Filename | `foo_enhanced_spectrum_analyzer.dll` |
| Version | 1.9.2.0 x64 |
| Size | 138,752 bytes |
| SHA-256 | `7d49351661573a9ee27c8578ecdc66678289d2bdb531b43a1185df76ddb16b54` |

Generated pair:

| File | Size | SHA-256 |
|---|---:|---|
| `foo_enhanced_spectrum_analyzer.dll` | 163,328 | `b0e4df422ebb54246167a711cf15a8bae6a7bc544e73dd0cbadd43995ca4efe8` |
| `foo_enhanced_spectrum_analyzer_dx12.dll` | 29,184 | `151d54a4626312f1aa6acb4aae54fad2e199b67cf008e7367196ffd7d3239541` |

The original input is read-only and preserved. The patcher verifies every payload and the complete final hashes before writing output, and refuses to overwrite existing generated files.

## Overview of improvements

### Stability and lifecycle

- Hardened shutdown, late-render and window-lifetime handling on current x64 foobar2000 builds.
- Fixed GDI bitmap/resource leakage and tightened temporary allocation cleanup.
- Restored reliable direct timer rendering after an experimental queued repaint route could leave the analyzer black or frozen.
- Added phase-correct pacing and additional x64 PE/unwind/COM hardening.

### Rendering quality and configuration

- Added persisted GDI+ anti-aliasing and gradient-boundary smoothing while preserving the original FFT/signal-processing behaviour.
- Corrected the final GDI+ AA mode from the unnecessarily expensive 8x8 setting to the intended 8x4 mode.
- Corrected configuration control alignment, spacing and visual consistency.

### Native DirectX 12 renderer

- Added an optional native D3D12 rendering path while retaining the established GDI renderer.
- Offloads spectrum fills, lines and presentation while keeping FFT/averaging/spectrum generation CPU-side.
- Uses an isolated DX12 sidecar architecture.
- Fixed loader, PE layout, descriptor-heap ABI and command-list vtable faults encountered during development.
- Replaced triangle-fan gradients with per-bin trapezoids, closed hollow gradient edges, fixed live-resize distortion and removed the residual stopped-playback baseline artefact.
- Caches a conclusive `DXGI_ERROR_UNSUPPORTED` device-creation result for the current foobar2000 session so unsupported hardware falls back to GDI without repeated DX12 retries; transient failures retain normal recovery behaviour.

### Native DX12 overlays

- Native logarithmic Grid and level lines.
- Native Left Labels and Bottom Labels.
- Native Peak Detector markers/frequency values and Calibration Line.
- Preserved Peak, RMS and Peak Max elements and the original overlay ordering/settings.

### Responsiveness, fullscreen and UI scheduling

- Diagnosed rapid context-menu stalls with Windows Performance Recorder as UI-thread modal-menu starvation rather than a GDI/DX12 renderer failure.
- Retained one original 10 ms Windows timer as the **only** normal-playback render cadence, removing the duplicate 10 ms timer-queue source that could effectively double-drive rendering and starve foobar2000's UI thread.
- Kept a thread-local `WH_MSGFILTER` / `MSGF_MENU` bridge that services the existing `WM_TIMER` route only while modal menus are active, with rate limiting, re-entrancy protection and multi-panel lifetime management.
- Fixed fullscreen playback-time input starvation: double-click, Escape and context-menu interaction remain responsive while music is playing.
- Added automatic fullscreen UI Theme Integration refresh using the component's existing colour-assignment path at a low update rate, avoiding per-frame theme work.
- Runtime testing confirmed smooth nested and fullscreen operation with AA enabled and the DX12 sidecar present, including testing on hardware without D3D12 support.

### Release integrity

- Exact-input SHA-256 gating and exact-output verification.
- Single-step public reconstruction from upstream 1.9.2.0 only.
- Static x64/PE validation, manifests, changed-range audit and checksums.
- No original or modified upstream analyzer DLL is included in this public archive.

For the complete chronological history, see **`CHANGELOG.md`**.

## Quick start

1. Extract this entire ZIP to a normal writable folder.
2. Obtain your own legitimate copy of the original upstream 1.9.2.0 component.
3. Use the **x64** `foo_enhanced_spectrum_analyzer.dll` matching the hash above.
4. Place it beside `Patch-EnhancedSpectrumAnalyzer.cmd` or drag it onto that file.
5. Copy the two verified files created in `patched\` into the foobar2000 component folder after making a backup.

The patcher does not access the network, modify the registry or alter the supplied original DLL.

## Distribution boundary

This archive contains neither the original nor the modified upstream analyzer DLL. It contains reconstruction/patch data, independently authored community code and the independently authored DX12 sidecar payload. The generated host remains a derivative of the upstream component and should not be redistributed without permission from the relevant rights holder.
