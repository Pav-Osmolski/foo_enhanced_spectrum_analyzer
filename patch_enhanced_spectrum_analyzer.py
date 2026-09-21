#!/usr/bin/env python3
"""One-step Enhanced Spectrum Analyzer 1.9.2.0 x64 -> final 1.9.2.9 Community DX12 patcher."""
from __future__ import annotations
import argparse, hashlib, json, os, sys
from pathlib import Path

EXPECTED_MANIFEST_SHA256 = "6520a8093ebbbdea6e3da67b61723732c438850dbbe947c88de31971f9d224c3"
EXPECTED_HOST_PAYLOAD_SHA256 = "e8f8f8699236a27b6573250df9047b78f61e6b31b59985492859a45192d13473"
EXPECTED_SCHEDULER_PAYLOAD_SHA256 = "c3c6519ff86488fb483074b98f97143de623be99c4da0508fb4a2b733ff4f529"
EXPECTED_DX12_PAYLOAD_SHA256 = "46080a0c060b179bc7a5f0344b2eb8b9b0431eb7f8a67273a1a5bab762b6aee5"
EXPECTED_INPUT_SHA256 = "7d49351661573a9ee27c8578ecdc66678289d2bdb531b43a1185df76ddb16b54"
EXPECTED_PRE_SCHEDULER_SHA256 = "d5f001d863429fc3f9c29e8aa4557bb5660da1d1f9194effb239ba1e0b56d859"
EXPECTED_HOST_SHA256 = "134fdb5d5844e0df6663c04a2f7b792c375a21b47e9f85637a2ce95dcdf77148"
EXPECTED_DX12_SHA256 = "46080a0c060b179bc7a5f0344b2eb8b9b0431eb7f8a67273a1a5bab762b6aee5"
EXPECTED_INPUT_SIZE = 138752
EXPECTED_PRE_SCHEDULER_SIZE = 146432
EXPECTED_HOST_SIZE = 163328
EXPECTED_DX12_SIZE = 29184
EXPECTED_BASE_CHANGED_BYTES = 341
EXPECTED_SCHEDULER_CHANGED_BYTES = 113

class PatchError(RuntimeError): pass
def sha256(v: bytes)->str: return hashlib.sha256(v).hexdigest()
def require(c: bool,m: str)->None:
    if not c: raise PatchError(m)
def read_bytes(p: Path,d: str)->bytes:
    try: return p.read_bytes()
    except OSError as e: raise PatchError(f"Could not read {d}: {p}\n{e}") from e
def decode_hex(v: object,d: str)->bytes:
    require(isinstance(v,str) and v and len(v)%2==0,f"Invalid hexadecimal data for {d}.")
    try: return bytes.fromhex(v)
    except ValueError as e: raise PatchError(f"Invalid hexadecimal data for {d}.") from e

def load_release(sd: Path):
    mr=read_bytes(sd/'PATCH-MANIFEST.json','PATCH-MANIFEST.json')
    require(sha256(mr)==EXPECTED_MANIFEST_SHA256,'PATCH-MANIFEST.json failed its integrity check. Re-extract the release ZIP.')
    try: m=json.loads(mr.decode('utf-8'))
    except Exception as e: raise PatchError('PATCH-MANIFEST.json is not valid UTF-8 JSON.') from e
    hp=read_bytes(sd/'host_patch_payload.bin','host patch payload')
    sp=read_bytes(sd/'scheduler_patch_payload.bin','scheduler patch payload')
    dx=read_bytes(sd/'dx12_runtime_payload.bin','DX12 runtime payload')
    require(sha256(hp)==EXPECTED_HOST_PAYLOAD_SHA256,'host_patch_payload.bin failed its integrity check. Re-extract the release ZIP.')
    require(sha256(sp)==EXPECTED_SCHEDULER_PAYLOAD_SHA256,'scheduler_patch_payload.bin failed its integrity check. Re-extract the release ZIP.')
    require(sha256(dx)==EXPECTED_DX12_PAYLOAD_SHA256,'dx12_runtime_payload.bin failed its integrity check. Re-extract the release ZIP.')
    require(m.get('format')=='devilhood-esa-patch-v3' and m.get('patcher_version')=='3.0.0' and m.get('producer')=='DeViLhoOD','Unexpected patch-manifest identity.')
    h=m.get('host',{})
    require(h.get('input',{}).get('size')==EXPECTED_INPUT_SIZE and h.get('input',{}).get('sha256')==EXPECTED_INPUT_SHA256,'Unexpected input contract in manifest.')
    require(h.get('pre_scheduler_output',{}).get('size')==EXPECTED_PRE_SCHEDULER_SIZE and h.get('pre_scheduler_output',{}).get('sha256')==EXPECTED_PRE_SCHEDULER_SHA256,'Unexpected base-transform contract in manifest.')
    require(h.get('output',{}).get('size')==EXPECTED_HOST_SIZE and h.get('output',{}).get('sha256')==EXPECTED_HOST_SHA256,'Unexpected final host contract in manifest.')
    return m,hp,sp,dx

def reconstruct_base(source: bytes,m: dict,payload: bytes)->bytes:
    require(len(source)==EXPECTED_INPUT_SIZE,'The input DLL has the wrong size.')
    actual=sha256(source)
    require(actual==EXPECTED_INPUT_SHA256,'The input DLL is not the exact audited x64 1.9.2.0 build.\nExpected SHA-256: '+EXPECTED_INPUT_SHA256+'\nActual SHA-256:   '+actual)
    out=bytearray(EXPECTED_PRE_SCHEDULER_SIZE); out[:len(source)]=source
    base=m['host']['base_transform']; writes=base['inherited_writes']
    previous=0; changed=0
    for n,e in enumerate(writes):
        off=e.get('offset'); rep=decode_hex(e.get('replacement_hex'),f'base write {n}'); end=off+len(rep)
        require(isinstance(off,int) and off>=previous and end<=EXPECTED_INPUT_SIZE,f'Base write {n} is overlapping or out of bounds.')
        out[off:end]=rep; previous=end; changed+=len(rep)
    require(changed==EXPECTED_BASE_CHANGED_BYTES,'Unexpected base changed-byte count.')
    layout=base['layout']; fill=layout['patch_fill']; zero=layout['patch_data_zero']
    require((fill['output_offset'],fill['length'],fill['byte'])==(0x21E00,0x1C00,0xCC),'Invalid base .patch fill layout.')
    out[0x21E00:0x23A00]=b'\xCC'*0x1C00
    require((zero['output_offset'],zero['length'])==(0x23A00,0x200),'Invalid base .patchd zero layout.')
    out[0x23A00:0x23C00]=b'\0'*0x200
    segs=m['host_payload']['segments']; cursor=0; prev=0
    for n,s in enumerate(segs):
        po,oo,l=s['payload_offset'],s['output_offset'],s['length']
        require(po==cursor and oo>=prev and po+l<=len(payload) and 0x21E00<=oo and oo+l<=0x23A00,f'Host payload segment {n} invalid.')
        out[oo:oo+l]=payload[po:po+l]; cursor+=l; prev=oo+l
    require(cursor==len(payload),'Host payload contains unreferenced bytes.')
    d=layout['dialog_copy']; so,oo,l=d['input_offset'],d['output_offset'],d['length']
    require((so,oo,l)==(0x1FF60,0x22600,0x12F4),'Invalid dialog-copy layout.')
    sd=source[so:so+l]; require(sd[:4]==b'\x01\x00\xff\xff' and int.from_bytes(sd[16:18],'little')==110,'Audited source dialog invariants do not match.')
    out[oo:oo+l]=sd; previous=0
    for n,e in enumerate(layout['dialog_writes']):
        rel=e['relative_offset']; rep=decode_hex(e['replacement_hex'],f'dialog write {n}'); end=rel+len(rep)
        require(rel>=previous and end<=l,f'Dialog write {n} invalid.'); out[oo+rel:oo+end]=rep; previous=end
    a=layout['dialog_append']; ad=decode_hex(a['data_hex'],'dialog append')
    require(a['relative_offset']==l and len(ad)==0x3C,'Invalid dialog append layout.'); out[oo+l:oo+l+len(ad)]=ad
    require(int.from_bytes(out[oo+16:oo+18],'little')==111,'Patched dialog item count invalid.')
    result=bytes(out); require(sha256(result)==EXPECTED_PRE_SCHEDULER_SHA256,'Base in-memory reconstruction failed verification.')
    return result

def apply_scheduler(base: bytes,m: dict,payload: bytes)->bytes:
    require(len(base)==EXPECTED_PRE_SCHEDULER_SIZE and sha256(base)==EXPECTED_PRE_SCHEDULER_SHA256,'Scheduler layer received an unexpected base host.')
    out=bytearray(EXPECTED_HOST_SIZE); out[:len(base)]=base
    sc=m['host']['scheduler_hardening']; previous=0; changed=0
    for n,e in enumerate(sc['overlap_writes']):
        off=e['offset']; rep=decode_hex(e['replacement_hex'],f'scheduler write {n}'); end=off+len(rep)
        require(off>=previous and end<=EXPECTED_PRE_SCHEDULER_SIZE,f'Scheduler write {n} invalid.'); out[off:end]=rep; previous=end; changed+=len(rep)
    require(changed==EXPECTED_SCHEDULER_CHANGED_BYTES,'Unexpected scheduler changed-byte count.')
    ap=sc['append']; require(ap['output_offset']==EXPECTED_PRE_SCHEDULER_SIZE and ap['length']==len(payload) and sha256(payload)==EXPECTED_SCHEDULER_PAYLOAD_SHA256,'Invalid scheduler append contract.')
    out[EXPECTED_PRE_SCHEDULER_SIZE:]=payload
    result=bytes(out); actual=sha256(result)
    require(actual==EXPECTED_HOST_SHA256,'The generated final host failed verification. No output was written.\nExpected SHA-256: '+EXPECTED_HOST_SHA256+'\nActual SHA-256:   '+actual)
    return result

def verify_dx12(v: bytes)->bytes:
    require(len(v)==EXPECTED_DX12_SIZE and sha256(v)==EXPECTED_DX12_SHA256 and v[:2]==b'MZ','The DX12 runtime failed verification.')
    return v

def write_exclusive(p: Path,v: bytes):
    flags=os.O_WRONLY|os.O_CREAT|os.O_EXCL
    if hasattr(os,'O_BINARY'): flags|=os.O_BINARY
    fd=os.open(p,flags,0o600); incomplete=True
    try:
        with os.fdopen(fd,'wb') as f: f.write(v); f.flush(); os.fsync(f.fileno())
        incomplete=False
    finally:
        if incomplete:
            try:p.unlink()
            except FileNotFoundError:pass

def write_pair(d: Path,h: bytes,dx: bytes):
    hp=d/'foo_enhanced_spectrum_analyzer.dll'; dp=d/'foo_enhanced_spectrum_analyzer_dx12.dll'
    require(not hp.exists(),f'Refusing to overwrite an existing output file:\n{hp}'); require(not dp.exists(),f'Refusing to overwrite an existing output file:\n{dp}')
    d.mkdir(parents=True,exist_ok=True); made=[]
    try:
        write_exclusive(hp,h); made.append(hp); write_exclusive(dp,dx); made.append(dp)
    except Exception:
        for p in reversed(made):
            try:p.unlink()
            except FileNotFoundError:pass
        raise
    return hp,dp

def args():
    p=argparse.ArgumentParser(description='One-step patch of exact Enhanced Spectrum Analyzer 1.9.2.0 x64 to the final DeViLhoOD 1.9.2.9 Community DX12 build.')
    p.add_argument('input',type=Path,help='path to original 1.9.2.0 x64 DLL'); p.add_argument('-o','--output-dir',type=Path); p.add_argument('--verify-only',action='store_true'); return p.parse_args()
def main():
    a=args()
    try:
        ip=a.input.expanduser().resolve(strict=True); require(ip.is_file(),f'Input is not a regular file: {ip}'); od=a.output_dir.expanduser().resolve(strict=False) if a.output_dir else ip.parent/'patched'
        m,hp,sp,dx=load_release(Path(__file__).resolve().parent); source=read_bytes(ip,'input DLL'); host=apply_scheduler(reconstruct_base(source,m,hp),m,sp); dx=verify_dx12(dx)
        if a.verify_only:
            print('PASS: exact upstream input and all payloads reconstruct the final release in one operation.'); print('Host SHA-256:',EXPECTED_HOST_SHA256); print('DX12 SHA-256:',EXPECTED_DX12_SHA256); return 0
        h,d=write_pair(od,host,dx); print('PASS: Enhanced Spectrum Analyzer 1.9.2.9 Community DX12 was generated directly from upstream 1.9.2.0.'); print('Host: ',h); print('DX12: ',d); print('Host SHA-256:',EXPECTED_HOST_SHA256); print('DX12 SHA-256:',EXPECTED_DX12_SHA256); print('The original DLL was not modified.'); return 0
    except (PatchError,OSError) as e: print('ERROR:',e,file=sys.stderr); return 1
if __name__=='__main__': raise SystemExit(main())
