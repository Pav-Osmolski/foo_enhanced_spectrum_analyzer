# Technical Notes

## Architecture

The final build uses a patched x64 host plus an independently authored D3D12 sidecar. The host dynamically locates `foo_enhanced_spectrum_analyzer_dx12.dll` beside itself and resolves the community DX12 dispatch bridge. FFT analysis, averaging and spectrum-point generation remain in the host; compatible spectrum/overlay geometry is submitted through the native D3D12 path. The established GDI renderer remains available.

The final scheduler hardening is renderer-agnostic: it changes UI servicing only and leaves both GDI and DX12 drawing implementations unchanged.

## Confirmed identities

- Upstream 1.9.2.0 x64 input: `7d49351661573a9ee27c8578ecdc66678289d2bdb531b43a1185df76ddb16b54` (138,752 bytes)
- Final scheduler-hardened host: `134fdb5d5844e0df6663c04a2f7b792c375a21b47e9f85637a2ce95dcdf77148` (163,328 bytes)
- DX12 sidecar: `46080a0c060b179bc7a5f0344b2eb8b9b0431eb7f8a67273a1a5bab762b6aee5` (29,184 bytes)

## Scheduler hardening

Windows Performance Recorder tracing showed the remaining rapid context-menu animation stalls were caused by foobar2000's UI thread spending 80–133 ms inside modal menu activity while the analyzer's normal timer servicing was starved. The final host retains the existing 10 ms timer/recovery scheduler and adds a thread-local `WH_MSGFILTER` path restricted to `MSGF_MENU`. When a frame is due it services the analyzer's existing `WM_TIMER` ID 8 route synchronously, with coalescing/re-entrancy/multi-panel lifetime safeguards and without consuming or modifying menu messages.

## Native DX12 overlays

- Grid: 30 logarithmic frequency divisions plus 11 horizontal level lines.
- Left Labels: 0 through -90 dB.
- Bottom Labels: 20, 50, 100, 200, 500, 1K, 2K, 5K, 10K and 20K.
- Peak Detector: original live peak records and frequency/decibel mappings.
- Calibration Line: original position, colour and alpha behaviour.

## Public reconstruction format

Patcher format `devilhood-esa-patch-v3` performs **one user-visible operation** from the exact untouched upstream 1.9.2.0 x64 input to the final host. Internally it reconstructs the previously audited community host in memory, applies the final scheduler-hardening write set and appended scheduler code/data/unwind payload, verifies the complete final SHA-256, and only then creates output files. The intermediate host is never written to disk.

The package contains no original or modified upstream analyzer DLL. Inherited upstream bytes (including the Options dialog) are copied from the user's own verified input at runtime. Output files use exclusive creation and are never overwritten.
