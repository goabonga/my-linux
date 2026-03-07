# My Linux - Linux From Scratch 12.2

Automated build of [Linux From Scratch 12.2](https://www.linuxfromscratch.org/lfs/view/12.2/) via GitHub Actions.

## What is this?

This project builds a complete Linux system from source code, following the LFS 12.2 book. The entire build is automated through GitHub Actions and produces a bootable disk image.

### What gets built

- **Cross-toolchain**: Binutils, GCC, Glibc (cross-compiled)
- **80+ packages**: From the Linux kernel to Bash, Vim, Python, OpenSSL, and more
- **Bootable image**: GPT-partitioned disk image with GRUB bootloader
- **Linux Kernel 6.10.5**: Configured for x86_64 with VirtIO support

## Build Pipeline

The build is split into 5 stages to work within GitHub Actions' 6-hour job limit:

| Stage | Description | Estimated Time |
|-------|-------------|---------------|
| 1 | Download all source packages (~80 tarballs) | ~10 min |
| 2 | Cross-toolchain + temporary tools (Ch. 5-6) | ~2-3 hours |
| 3 | Chroot setup + system build part 1 (Ch. 7-8a) | ~3-4 hours |
| 4 | System build part 2 + configuration (Ch. 8b-9) | ~2-3 hours |
| 5 | Linux kernel + bootable disk image (Ch. 10) | ~1 hour |

Each stage saves its output as a GitHub artifact that the next stage picks up.

## How to Build

### Via GitHub Actions (recommended)

1. Push this repo to GitHub
2. Go to **Actions** > **Build Linux From Scratch 12.2**
3. Click **Run workflow**
4. Select which stage to start from (default: 1)
5. Wait for all 5 stages to complete
6. Download the `lfs-12.2-bootable-image` artifact

### Boot the Image

```bash
# Decompress
zstd -d lfs-12.2.img.zst

# Boot with QEMU
qemu-system-x86_64 \
  -drive file=lfs-12.2.img,format=raw \
  -m 2G \
  -nographic \
  -serial mon:stdio

# Or with a graphical display
qemu-system-x86_64 \
  -drive file=lfs-12.2.img,format=raw \
  -m 2G \
  -enable-kvm
```

Default root password: `root`

### Write to a USB drive

```bash
zstd -d lfs-12.2.img.zst
sudo dd if=lfs-12.2.img of=/dev/sdX bs=4M status=progress
```

## Project Structure

```
.github/workflows/
  build-lfs.yml          # Main CI/CD pipeline (5 stages)
scripts/
  config.sh              # Package versions and helper functions
  01-download-sources.sh # Download all source tarballs
  02-build-cross-toolchain.sh  # Chapter 5: Cross-toolchain
  03-build-temp-tools.sh       # Chapter 6: Temporary tools
  04-chroot-setup.sh           # Chapter 7: Chroot environment
  05-build-system.sh           # Chapter 8 part 1: Core system
  06-build-system-part2.sh     # Chapter 8 part 2: Remaining packages
  07-configure-system.sh       # Chapter 9: System configuration
  08-create-image.sh           # Chapter 10: Kernel + disk image
sources/
  wget-list              # Package download URLs
  patches-list           # LFS patches
```

## Customization

### Kernel config
Edit `scripts/08-create-image.sh` to modify kernel options. The default config uses `make defconfig` with additional VirtIO and common hardware drivers enabled.

### Network
Edit `scripts/07-configure-system.sh` to change hostname, IP address, DNS servers.

### Packages
All package versions are defined in `scripts/config.sh`. Update versions there and in `sources/wget-list` to upgrade packages.

### Locale
Edit `scripts/05-build-system.sh` (Glibc section) to add more locales beyond `en_US.UTF-8`.

## Troubleshooting

### Build fails at a specific stage
Use the `start_stage` input when triggering the workflow to restart from a specific stage. You'll need the artifact from the previous stage to be available.

### Disk space issues
The workflow removes pre-installed software from the GitHub runner to free ~30GB. If a stage still runs out of space, the build scripts can be split further.

### Package download fails
Some mirrors may be temporarily unavailable. The download script retries failed downloads. You can also manually add alternative mirror URLs to `sources/wget-list`.

## References

- [LFS 12.2 Book](https://www.linuxfromscratch.org/lfs/view/12.2/)
- [LFS FAQ](https://www.linuxfromscratch.org/faq/)
- [BLFS (Beyond LFS)](https://www.linuxfromscratch.org/blfs/view/12.2/) - for additional packages
