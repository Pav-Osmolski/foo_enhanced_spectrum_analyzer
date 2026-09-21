# Enhanced Spectrum Analyzer 1.9.2.9 — Community DX12 x64 Public Patcher

Original **Enhanced Spectrum Analyzer** by **Crossover**. Community maintenance, DX12 enhancement work and release packaging by **DeViLhoOD**.

This is an unofficial x64 community continuation built from the upstream 1.9.2.0 component. It is not affiliated with or endorsed by Crossover, foobar2000 or its developers.

## One-step public patcher

This package patches the **exact untouched upstream 1.9.2.0 x64 DLL directly to the final scheduler-hardened 1.9.2.9 build in one operation**. No earlier community build and no second patching stage are required.

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
| `foo_enhanced_spectrum_analyzer.dll` | 163,328 | `134fdb5d5844e0df6663c04a2f7b792c375a21b47e9f85637a2ce95dcdf77148` |
| `foo_enhanced_spectrum_analyzer_dx12.dll` | 29,184 | `46080a0c060b179bc7a5f0344b2eb8b9b0431eb7f8a67273a1a5bab762b6aee5` |

The original input is read-only and preserved. The patcher verifies every payload and the complete final hashes before writing output, and refuses to overwrite existing generated files.

## Overview of improvements

### Stability and lifecycle

- Hardened shutdown, late-render and window-lifetime handling on current x64 foobar2000 builds.
- Fixed GDI bitmap/resource leakage and tightened temporary allocation cleanup.
- Restored reliable direct timer rendering after an experimental queued repaint route could leave the analyzer black or frozen.
- Added phase-correct pacing and additional x64 PE/unwind/COM hardening.

### Rendering quality and configuration

- Improved high-quality GDI+ anti-aliasing and added a persisted Anti-aliasing option.
- Extended anti-aliasing to gradient spectrum boundaries while preserving the original FFT/signal-processing behaviour.
- Corrected configuration control alignment, spacing and visual consistency.

### Native DirectX 12 renderer

- Added an optional native D3D12 rendering path while retaining the established GDI renderer.
- Offloads spectrum fills, lines and presentation while keeping FFT/averaging/spectrum generation CPU-side.
- Uses an isolated DX12 sidecar architecture.
- Fixed loader, PE layout, descriptor-heap ABI and command-list vtable faults encountered during development.
- Replaced triangle-fan gradients with per-bin trapezoids, closed hollow gradient edges, fixed live-resize distortion and removed the residual stopped-playback baseline artefact.

### Native DX12 overlays

- Native logarithmic Grid and level lines.
- Native Left Labels and Bottom Labels.
- Native Peak Detector markers/frequency values and Calibration Line.
- Preserved Peak, RMS and Peak Max elements and the original overlay ordering/settings.

### Responsiveness and UI scheduling

- Added bounded/coalesced recovery around the original 10 ms timer route.
- Diagnosed the remaining rapid right-click/context-menu stalls with Windows Performance Recorder as UI-thread modal-menu starvation rather than a renderer fault.
- Added a thread-local `WH_MSGFILTER` / `MSGF_MENU` bridge that safely services the existing `WM_TIMER` path during modal menu loops.
- Added rate limiting, re-entrancy protection and multi-panel hook lifetime management.
- Runtime testing confirmed the previously repeatable 80–133 ms animation hesitations were eliminated.

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
