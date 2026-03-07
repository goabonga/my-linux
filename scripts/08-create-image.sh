#!/bin/bash
# LFS 12.2 - Chapter 10: Making the LFS System Bootable + Create disk image
# Parts run inside chroot, final image creation runs on the host
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

echo "=== Chapter 10: Making LFS Bootable ==="

# ============================================================
# Build the Linux kernel inside chroot
# ============================================================
cat > "$LFS/tmp/build-kernel.sh" << 'KERNEL_SCRIPT'
#!/bin/bash
set -euo pipefail
export MAKEFLAGS="-j$(nproc)"

echo ">>> Building Linux Kernel..."
cd /sources
tar -xf linux-6.10.5.tar.xz && cd linux-6.10.5

make mrproper

# Use a default config optimized for VMs/generic x86_64
make defconfig

# Enable some useful options
scripts/config --enable CONFIG_EXT4_FS
scripts/config --enable CONFIG_VFAT_FS
scripts/config --enable CONFIG_VIRTIO_PCI
scripts/config --enable CONFIG_VIRTIO_BLK
scripts/config --enable CONFIG_VIRTIO_NET
scripts/config --enable CONFIG_VIRTIO_CONSOLE
scripts/config --enable CONFIG_NET_9P
scripts/config --enable CONFIG_NET_9P_VIRTIO
scripts/config --enable CONFIG_9P_FS
scripts/config --enable CONFIG_SERIAL_8250
scripts/config --enable CONFIG_SERIAL_8250_CONSOLE
scripts/config --set-str CONFIG_DEFAULT_HOSTNAME "lfs"
scripts/config --enable CONFIG_DEVTMPFS
scripts/config --enable CONFIG_DEVTMPFS_MOUNT
scripts/config --enable CONFIG_TMPFS
scripts/config --enable CONFIG_TMPFS_POSIX_ACL
scripts/config --enable CONFIG_BLK_DEV_SD
scripts/config --enable CONFIG_SCSI
scripts/config --enable CONFIG_SCSI_VIRTIO
scripts/config --enable CONFIG_ATA
scripts/config --enable CONFIG_SATA_AHCI
scripts/config --enable CONFIG_E1000
scripts/config --enable CONFIG_E1000E

make olddefconfig
make
make modules_install
cp -v arch/x86/boot/bzImage /boot/vmlinuz-6.10.5-lfs-12.2
cp -v System.map /boot/System.map-6.10.5
cp -v .config /boot/config-6.10.5

cd /sources && rm -rf linux-6.10.5
echo ">>> Linux Kernel build complete"

# ============================================================
# Create /etc/lfs-release
# ============================================================
echo "12.2" > /etc/lfs-release

cat > /etc/lsb-release << "EOF"
DISTRIB_ID="Linux From Scratch"
DISTRIB_RELEASE="12.2"
DISTRIB_CODENAME="goabonga"
DISTRIB_DESCRIPTION="Linux From Scratch 12.2"
EOF

cat > /etc/os-release << "EOF"
NAME="Linux From Scratch"
VERSION="12.2"
ID=lfs
PRETTY_NAME="Linux From Scratch 12.2"
VERSION_CODENAME="goabonga"
HOME_URL="https://www.linuxfromscratch.org/"
EOF

echo ">>> System identification files created"
KERNEL_SCRIPT

chmod +x "$LFS/tmp/build-kernel.sh"

# Run kernel build in chroot
chroot "$LFS" /usr/bin/env -i \
    HOME=/root \
    TERM="$TERM" \
    PS1='(lfs chroot) \u:\w\$ ' \
    PATH=/usr/bin:/usr/sbin \
    MAKEFLAGS="-j$(nproc)" \
    /bin/bash /tmp/build-kernel.sh

# ============================================================
# Create bootable disk image (runs on host)
# ============================================================
echo ">>> Creating bootable disk image..."

IMAGE_SIZE="4G"
IMAGE_FILE="/tmp/lfs-12.2.img"

# Create sparse disk image
truncate -s "$IMAGE_SIZE" "$IMAGE_FILE"

# Partition the image: 1MB BIOS boot + rest for root
parted -s "$IMAGE_FILE" mklabel gpt
parted -s "$IMAGE_FILE" mkpart bios_grub 1MiB 2MiB
parted -s "$IMAGE_FILE" set 1 bios_grub on
parted -s "$IMAGE_FILE" mkpart root ext4 2MiB 100%

# Set up loop device
LOOP_DEV=$(losetup --find --show --partscan "$IMAGE_FILE")
echo "Loop device: $LOOP_DEV"

# Wait for partition devices
sleep 2
partprobe "$LOOP_DEV" 2>/dev/null || true
sleep 1

ROOT_PART="${LOOP_DEV}p2"

# Format root partition
mkfs.ext4 -F -L lfs-root "$ROOT_PART"

# Mount and copy LFS system
MOUNT_DIR="/tmp/lfs-image"
mkdir -p "$MOUNT_DIR"
mount "$ROOT_PART" "$MOUNT_DIR"

echo ">>> Copying LFS system to disk image..."
# Copy everything except sources, dev, proc, sys, run
rsync -aAX --exclude='/sources' \
           --exclude='/dev/*' \
           --exclude='/proc/*' \
           --exclude='/sys/*' \
           --exclude='/run/*' \
           --exclude='/tmp/*' \
           "$LFS/" "$MOUNT_DIR/"

# Create mount points
mkdir -p "$MOUNT_DIR"/{dev,proc,sys,run,tmp}

# Install GRUB
echo ">>> Installing GRUB..."
mkdir -p "$MOUNT_DIR/boot/grub"

cat > "$MOUNT_DIR/boot/grub/grub.cfg" << "GRUB_CFG"
set default=0
set timeout=5

insmod ext2
insmod gzio

menuentry "Linux From Scratch 12.2" {
    linux /boot/vmlinuz-6.10.5-lfs-12.2 root=/dev/sda2 ro console=tty0 console=ttyS0,115200
}

menuentry "Linux From Scratch 12.2 (recovery)" {
    linux /boot/vmlinuz-6.10.5-lfs-12.2 root=/dev/sda2 ro single console=tty0 console=ttyS0,115200
}
GRUB_CFG

# Install GRUB to the image
grub-install --target=i386-pc \
             --boot-directory="$MOUNT_DIR/boot" \
             --recheck \
             "$LOOP_DEV" 2>/dev/null || \
  echo "WARNING: grub-install failed - you may need to install GRUB manually"

# Update fstab with correct UUID
ROOT_UUID=$(blkid -s UUID -o value "$ROOT_PART")
if [ -n "$ROOT_UUID" ]; then
    sed -i "s|/dev/sda1|UUID=$ROOT_UUID|" "$MOUNT_DIR/etc/fstab"
    sed -i "s|root=/dev/sda2|root=UUID=$ROOT_UUID|g" "$MOUNT_DIR/boot/grub/grub.cfg"
fi

# Cleanup
sync
umount "$MOUNT_DIR"
losetup -d "$LOOP_DEV"
rmdir "$MOUNT_DIR"

# Compress the image
echo ">>> Compressing disk image..."
zstd -T0 -9 "$IMAGE_FILE" -o "/tmp/lfs-12.2.img.zst"

echo "=== Bootable disk image created ==="
echo "Image: /tmp/lfs-12.2.img.zst"
ls -lh /tmp/lfs-12.2.img*
