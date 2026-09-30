# DoomOS Release Engineering & Distribution Protocol

**Standard:** ISO Reassembly & Release Integrity Guarantee  
**Milestone:** v1.0.0  

---

## 1. Release Philosophy

DoomOS distributes a single, unified, bootable ISO image. Because cloud release services and file-sharing mechanisms frequently enforce individual file size boundaries (or experience timeout interruptions during 3GB+ transfers), DoomOS implements a deterministic **Multipart Release Pipeline**.

The split parts are **not** independent images; they are sequential slices of a single binary that are reassembled client-side prior to booting.

---

## 2. Release Artifact Standard

Every official release published to GitHub Releases must strictly contain:

1. **`DoomOS-x86_64-UEFI-vX.Y.Z.iso.part00`**: First sequential chunk (up to 2000 MB).
2. **`DoomOS-x86_64-UEFI-vX.Y.Z.iso.part01`**: Second sequential chunk.
3. Additional chunks (`part02`, `part03`, ...) if ISO size requires it.
4. **`DoomOS-x86_64-UEFI-vX.Y.Z.iso.sha256`**: Cryptographic SHA256 checksum of the **complete, unified ISO**.
5. **`combine.sh`**: Standalone, POSIX-compatible reassembler and verification script.
6. **`release-manifest.txt`**: Complete build metadata, git commit hash, tool versions, and individual part signatures.
7. User guides and deployment tools:
   - `test-vmware.sh` (automatic VMware VM bundle creation)
   - `flash-usb.sh` (bare-metal hybrid flasher)
   - Official documentation PDFs.

---

## 3. Strict Release Gate Checklist

No release may be finalized or tagged unless every one of the following criteria is satisfied:

- [ ] Clean build without stale artifacts.
- [ ] Target architecture is verified as `x86_64`.
- [ ] EFI System Partition contains `EFI/BOOT/BOOTX64.EFI`.
- [ ] Kernel (`vmlinuz-linux-zen`) and initramfs exist and are non-empty.
- [ ] 20-point subsystem and VMware audit passes (`verify-iso.sh`).
- [ ] Authoritative SHA256 checksum generated.
- [ ] Sequential splitting executed without missing or duplicate parts.
- [ ] Reassembly test executed on CI runner using `combine.sh`.
- [ ] Reassembled SHA256 matches the original master SHA256 bit-for-bit.
- [ ] Release manifest contains git commit, build ID, and timestamp.
