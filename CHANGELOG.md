# Changelog

This changelog covers the **community x64 maintenance and DX12 enhancement lineage** built from Crossover's upstream Enhanced Spectrum Analyzer 1.9.2.0. Version numbers after 1.9.2.0 refer to this unofficial community branch and do not imply an official release by the original author.

## 1.9.2.9 — scheduler-hardened refresh — 2026-09-21

- Fixed the remaining brief spectrum-animation pauses triggered by rapid context-menu interaction in the playlist, Waveform Minibar and other foobar2000 panels.
- Confirmed by Windows Performance Recorder tracing that the pauses were caused by UI-thread modal-menu starvation rather than a GDI or DX12 rendering failure.
- Retained the native 10 ms timer and the bounded/coalesced recovery scheduler introduced during UI-scheduler testing.
- Added a thread-local `WH_MSGFILTER` hook that acts only for `MSGF_MENU` processing on foobar2000's UI thread.
- Reused the analyzer's existing `WM_TIMER` / timer ID 8 path synchronously during modal menu loops instead of introducing a second renderer or repaint path.
- Added 10 ms modal coalescing, re-entrancy protection and multi-panel hook lifetime management.
- Preserved the analyzer's own elapsed-time/FPS gating and never consumes or alters menu messages.
- Left the GDI and DX12 rendering implementations unchanged.
- Preserved the existing DX12 sidecar byte-for-byte.
- Promoted the runtime-confirmed TEST03 scheduler build without changing the component version number.
- Updated trace documentation, validation metadata, manifests and checksums.
- Consolidated public installation into a single-step patcher from the exact untouched upstream 1.9.2.0 x64 DLL directly to this final scheduler-hardened build; no intermediate community build is required.

## 1.9.2.9 — final native-DX12 community baseline — 2026-09-07

- Completed and hardened the native DirectX 12 rendering path while retaining the established GDI renderer.
- Replaced the early triangle-fan gradient fill with per-bin trapezoids, eliminating visible gradient triangles while preserving spectrum peaks and valleys.
- Added closure geometry for hollow/open gradient edges.
- Synchronized the DX12 presentation path with live panel resizing to avoid transient resize distortion.
- Fixed the 1 px residual line that could remain after playback stopped by making anti-aliased edge emission signal-driven: zero-to-zero segments are omitted while real zero/non-zero transitions remain visible.
- Implemented the analyzer grid natively in DX12, including 30 logarithmic frequency lines and 11 level lines with the configured colour, alpha and anti-aliasing behaviour.
- Implemented Left Labels natively in DX12, covering 0 to -90 dB.
- Implemented Bottom Labels natively in DX12 using 10 logarithmically positioned frequency labels.
- Implemented Peak Detector markers and frequency values in the DX12 command stream through the host bridge.
- Implemented the Calibration Line natively in DX12.
- Preserved the original overlay order, settings and behaviour instead of falling back to mixed GDI/DX12 rendering.
- Retained the TEST12 rendering lineage after later resize/compositor experiments did not improve the result reliably enough to replace it.
- Completed private-DLL and public-patcher release hardening and validation for the native-DX12 baseline.

## 1.9.2.8 — DX12 command-list ABI correction — 2026-09-02

- Corrected the D3D12 graphics-command-list vtable indexing used by the new renderer.
- Accounted for the omitted `ResolveSubresource` entry in the earlier indexing model and corrected `ResourceBarrier` to slot 26.
- Eliminated the invalid call path responsible for the TEST7 `0xCD` crash and allowed the DX12 renderer to progress through command recording reliably.

## 1.9.2.7 — DX12 COM ABI correction — 2026-09-02

- Corrected the descriptor-heap COM ABI call convention used by the early DX12 implementation, including the hidden output-pointer handling required by the interface method.
- Removed a low-level interoperability fault that prevented the experimental DX12 path from operating reliably even after the PE loader issues had been addressed.

## 1.9.2.6 — DX12 loader and image-layout hardening — 2026-09-01

- Corrected the PE raw-section sizing error that caused the first DX12 test build to be rejected by Windows as "not a valid Win32 application".
- Continued hardening expanded-image and `.pdata` / unwind-layout handling uncovered by subsequent loader tests.
- Moved the DX12 implementation into a fixed-size sidecar architecture, avoiding unsafe growth of the original analyzer image and giving the new renderer a cleaner isolation boundary.
- Preserved the original host component as the foobar2000-facing module while delegating DX12-specific work through the sidecar bridge.

## 1.9.2.5 — initial DirectX 12 rendering path — 2026-09-01

- Added the first native D3D12 rendering path for the analyzer.
- Offloaded spectrum fills and line rendering to the GPU while keeping FFT analysis, averaging and spectrum-point generation CPU-side.
- Added GPU rendering for the principal spectrum/background and Peak/RMS/Peak Max visual elements.
- Kept the existing GDI path available while DX12 support was being brought to feature parity.
- Initially retained GDI fallback for Grid, Labels, Peak Detector and Calibration Line until those overlays could be implemented safely in native DX12.

## 1.9.2.4 — anti-aliasing and configuration-layout correction — 2026-09-01

- Moved anti-aliasing to the actual inner graphics context used by the spectrum renderer, fixing cases where the control existed but did not affect the final drawing path correctly.
- Finalized the persisted anti-aliasing checkbox and its configuration behaviour.
- Renamed/aligned the control consistently with the surrounding renderer options.
- Corrected the checkbox-row spacing and general configuration-page alignment.
- Preserved all stability, timing and rendering fixes from 1.9.2.1–1.9.2.3.

## 1.9.2.3 — gradient anti-aliasing and user control — 2026-09-01

- Added a dedicated gradient-brush boundary pass so anti-aliasing also affects gradient-rendered spectrum edges rather than only ordinary line drawing.
- Added a persisted user-facing anti-aliasing option to the component configuration.
- Continued refinement of drawing quality without changing the analyzer's FFT or signal-processing behaviour.

## 1.9.2.2 — explicit high-quality GDI+ anti-aliasing — 2026-08-31

- Applied explicit `AntiAlias8x4` smoothing to the shared graphics context used by the GDI+ renderer.
- Retained the 1.9.2.1 lifecycle, allocation, timer and pacing fixes.
- Identified that gradient-only rendering required an additional boundary pass, leading to the 1.9.2.3 work.

## 1.9.2.1 — x64 stability, lifetime and GDI hardening — 2026-08-28

- Hardened shutdown and late-render paths following crash/lifetime investigation on current x64 foobar2000 builds.
- Added guards to prevent drawing work from continuing against objects or window state that were already being torn down.
- Fixed GDI bitmap/resource leakage and tightened temporary allocation cleanup.
- Restored direct timer-driven rendering after an experimental queued `WM_PAINT` path could leave the analyzer black or permanently frozen.
- Added phase-correct render pacing so delayed frames do not progressively drift away from the intended update cadence.
- Improved high-quality anti-aliasing behaviour as the foundation for the later configurable AA work.
- Performed general x64 rendering and stability hardening while preserving the analyzer's original signal-processing behaviour.

## 1.9.2.0 — upstream baseline — 2023-05-06

- Last known public upstream release by **Crossover** used as the starting point for this community work.
- No upstream source code was available for this maintenance effort; the community changes above were developed through private binary analysis and patching.
