#!/bin/bash
# LFS 12.2 - Chapter 8 (continued): More System Software
# This script runs INSIDE the chroot environment
set -euo pipefail

export MAKEFLAGS="-j$(nproc)"

echo "=== Chapter 8 Part 2: Building remaining system packages ==="

# ============================================================
# 8.57 Ninja-1.12.1
# ============================================================
echo ">>> Building Ninja..."
cd /sources && tar -xf ninja-1.12.1.tar.gz && cd ninja-1.12.1
python3 configure.py --bootstrap
install -vm755 ninja /usr/bin/
cd /sources && rm -rf ninja-1.12.1

# ============================================================
# 8.58 Meson-1.5.1
# ============================================================
echo ">>> Installing Meson..."
cd /sources && tar -xf meson-1.5.1.tar.gz && cd meson-1.5.1
pip3 install --no-index --no-build-isolation --find-links dist meson
cd /sources && rm -rf meson-1.5.1

# ============================================================
# 8.59 Coreutils-9.5
# ============================================================
echo ">>> Building Coreutils (final)..."
cd /sources && tar -xf coreutils-9.5.tar.xz && cd coreutils-9.5
patch -Np1 -i /sources/coreutils-9.5-i18n-2.patch
autoreconf -fiv
FORCE_UNSAFE_CONFIGURE=1 ./configure \
            --prefix=/usr --enable-no-install-program=kill,uptime
make
make install
mv -v /usr/bin/chroot /usr/sbin
mv -v /usr/share/man/man1/chroot.1 /usr/share/man/man8/chroot.8
sed -i 's/"1"/"8"/' /usr/share/man/man8/chroot.8
cd /sources && rm -rf coreutils-9.5

# ============================================================
# 8.60 Check-0.15.2
# ============================================================
echo ">>> Building Check..."
cd /sources && tar -xf check-0.15.2.tar.gz && cd check-0.15.2
./configure --prefix=/usr --disable-static
make
make docdir=/usr/share/doc/check-0.15.2 install
cd /sources && rm -rf check-0.15.2

# ============================================================
# 8.61 Diffutils-3.10
# ============================================================
echo ">>> Building Diffutils (final)..."
cd /sources && tar -xf diffutils-3.10.tar.xz && cd diffutils-3.10
./configure --prefix=/usr
make
make install
cd /sources && rm -rf diffutils-3.10

# ============================================================
# 8.62 Gawk-5.3.0
# ============================================================
echo ">>> Building Gawk (final)..."
cd /sources && tar -xf gawk-5.3.0.tar.xz && cd gawk-5.3.0
sed -i 's/extras//' Makefile.in
./configure --prefix=/usr
make
rm -f /usr/bin/gawk-5.3.0
make install
cd /sources && rm -rf gawk-5.3.0

# ============================================================
# 8.63 Findutils-4.10.0
# ============================================================
echo ">>> Building Findutils (final)..."
cd /sources && tar -xf findutils-4.10.0.tar.xz && cd findutils-4.10.0
./configure --prefix=/usr --localstatedir=/var/lib/locate
make
make install
cd /sources && rm -rf findutils-4.10.0

# ============================================================
# 8.64 Groff-1.23.0
# ============================================================
echo ">>> Building Groff..."
cd /sources && tar -xf groff-1.23.0.tar.gz && cd groff-1.23.0
PAGE=letter ./configure --prefix=/usr
make
make install
cd /sources && rm -rf groff-1.23.0

# ============================================================
# 8.65 GRUB-2.12
# ============================================================
echo ">>> Building GRUB..."
cd /sources && tar -xf grub-2.12.tar.xz && cd grub-2.12
unset {C,CPP,CXX,LD}FLAGS
./configure --prefix=/usr --sysconfdir=/etc --disable-efiemu \
            --disable-werror
make
make install
mv -v /etc/bash_completion.d/grub /usr/share/bash-completion/completions
cd /sources && rm -rf grub-2.12

# ============================================================
# 8.66 Gzip-1.13
# ============================================================
echo ">>> Building Gzip (final)..."
cd /sources && tar -xf gzip-1.13.tar.xz && cd gzip-1.13
./configure --prefix=/usr
make
make install
cd /sources && rm -rf gzip-1.13

# ============================================================
# 8.67 IPRoute2-6.10.0
# ============================================================
echo ">>> Building IPRoute2..."
cd /sources && tar -xf iproute2-6.10.0.tar.xz && cd iproute2-6.10.0
sed -i /ARPD/d Makefile
rm -fv man/man8/arpd.8
make NETNS_RUN_DIR=/run/netns
make SBINDIR=/usr/sbin install
cd /sources && rm -rf iproute2-6.10.0

# ============================================================
# 8.68 Kbd-2.6.4
# ============================================================
echo ">>> Building Kbd..."
cd /sources && tar -xf kbd-2.6.4.tar.xz && cd kbd-2.6.4
patch -Np1 -i /sources/kbd-2.6.4-backspace-1.patch
sed -i '/RESIZECONS_PROGS=/s/444444//' configure
sed -i 's/resizecons.8 //' docs/man/man8/Makefile.in
./configure --prefix=/usr --disable-vlock
make
make install
cd /sources && rm -rf kbd-2.6.4

# ============================================================
# 8.69 Libpipeline-1.5.7
# ============================================================
echo ">>> Building Libpipeline..."
cd /sources && tar -xf libpipeline-1.5.7.tar.gz && cd libpipeline-1.5.7
./configure --prefix=/usr
make
make install
cd /sources && rm -rf libpipeline-1.5.7

# ============================================================
# 8.70 Make-4.4.1
# ============================================================
echo ">>> Building Make (final)..."
cd /sources && tar -xf make-4.4.1.tar.gz && cd make-4.4.1
./configure --prefix=/usr
make
make install
cd /sources && rm -rf make-4.4.1

# ============================================================
# 8.71 Patch-2.7.6
# ============================================================
echo ">>> Building Patch (final)..."
cd /sources && tar -xf patch-2.7.6.tar.xz && cd patch-2.7.6
./configure --prefix=/usr
make
make install
cd /sources && rm -rf patch-2.7.6

# ============================================================
# 8.72 Tar-1.35
# ============================================================
echo ">>> Building Tar (final)..."
cd /sources && tar -xf tar-1.35.tar.xz && cd tar-1.35
FORCE_UNSAFE_CONFIGURE=1 ./configure --prefix=/usr
make
make install
cd /sources && rm -rf tar-1.35

# ============================================================
# 8.73 Texinfo-7.1
# ============================================================
echo ">>> Building Texinfo (final)..."
cd /sources && tar -xf texinfo-7.1.tar.xz && cd texinfo-7.1
./configure --prefix=/usr
make
make install
cd /sources && rm -rf texinfo-7.1

# ============================================================
# 8.74 Vim-9.1.0660
# ============================================================
echo ">>> Building Vim..."
cd /sources && tar -xf vim-9.1.0660.tar.gz && cd vim-9.1.0660
echo '#define SYS_VIMRC_FILE "/etc/vimrc"' >> src/feature.h
./configure --prefix=/usr
make
make install
ln -sv vim /usr/bin/vi
for L in /usr/share/man/{,*/}man1/vim.1; do
  ln -sv vim.1 $(dirname $L)/vi.1
done
ln -sv ../vim/vim91/doc /usr/share/doc/vim-9.1.0660
# Default vimrc
cat > /etc/vimrc << "EOF"
source $VIMRUNTIME/defaults.vim
let skip_defaults_vim = 1
set nocompatible
set backspace=2
set mouse=
syntax on
if (&term == "xterm") || (&term == "putty")
  set background=dark
endif
EOF
cd /sources && rm -rf vim-9.1.0660

# ============================================================
# 8.75 MarkupSafe (already installed via pip)
# 8.76 Jinja2 (already installed via pip)
# ============================================================

# ============================================================
# 8.77 Udev from systemd-256.4
# ============================================================
echo ">>> Building Udev (from systemd)..."
cd /sources && tar -xf systemd-256.4.tar.gz && cd systemd-256.4
sed -i -e 's/GROUP="render"/GROUP="video"/' \
       -e 's/GROUP="sgx", //' rules.d/50-udev-default.rules.in
sed '/systemd-hierarchical/d' -i src/libudev/libudev.sym
mkdir -p build && cd build
meson setup .. \
      --prefix=/usr \
      --buildtype=release \
      -D mode=release \
      -D dev-kvm-mode=0660 \
      -D link-udev-shared=false \
      -D logind=false \
      -D vconsole=false
ninja udevadm systemd-hwdb \
      $(grep -o 'lib[a-z_]*\.so[.0-9]*' ../src/libudev/libudev.sym | sort -u) \
      $(grep -o 'lib[a-z_]*\.so[.0-9]*' ../src/libudev/libudev.sym | sed 's/\.so.*/.so/' | sort -u) \
      || ninja udevadm systemd-hwdb
install -vm755 udevadm                             /usr/bin/
install -vm755 systemd-hwdb                        /usr/bin/udev-hwdb
ln -sv ../bin/udevadm /usr/sbin/udevd
cp -av libudev.so{,*[0-9]} /usr/lib/
install -vm644 ../src/libudev/libudev.h /usr/include/
mkdir -pv /usr/lib/pkgconfig
install -vm644 src/libudev/libudev.pc /usr/lib/pkgconfig/ 2>/dev/null || \
  sed "s|@PREFIX@|/usr|;s|@EXEC_PREFIX@|/usr|;s|@LIBDIR@|/usr/lib|;s|@INCLUDEDIR@|/usr/include|;s|@VERSION@|256|" \
    ../src/libudev/libudev.pc.in > /usr/lib/pkgconfig/libudev.pc
mkdir -pv /usr/lib/udev/rules.d /etc/udev/rules.d
cd ../..
# Install udev man pages and rules
cd systemd-256.4
mkdir -p /usr/share/man/man{5,7,8}
for i in udevadm udevd; do
  install -vm644 man/${i}.8 /usr/share/man/man8/ 2>/dev/null || true
done
udev-hwdb update 2>/dev/null || true
cd /sources && rm -rf systemd-256.4

# ============================================================
# 8.78 Man-DB-2.12.1
# ============================================================
echo ">>> Building Man-DB..."
cd /sources && tar -xf man-db-2.12.1.tar.xz && cd man-db-2.12.1
./configure --prefix=/usr --docdir=/usr/share/doc/man-db-2.12.1 \
            --sysconfdir=/etc --disable-setuid \
            --enable-cache-owner=bin --with-browser=/usr/bin/lynx \
            --with-vgrind=/usr/bin/vgrind --with-grap=/usr/bin/grap
make
make install
cd /sources && rm -rf man-db-2.12.1

# ============================================================
# 8.79 Procps-ng-4.0.4
# ============================================================
echo ">>> Building Procps-ng..."
cd /sources && tar -xf procps-ng-4.0.4.tar.xz && cd procps-ng-4.0.4
./configure --prefix=/usr --docdir=/usr/share/doc/procps-ng-4.0.4 \
            --disable-static --disable-kill
make
make install
cd /sources && rm -rf procps-ng-4.0.4

# ============================================================
# 8.80 Util-linux-2.40.2
# ============================================================
echo ">>> Building Util-linux (final)..."
cd /sources && tar -xf util-linux-2.40.2.tar.xz && cd util-linux-2.40.2
sed -i '/test_mkfds/s/^/#/' tests/helpers/Makemodule.am
./configure --bindir=/usr/bin --libdir=/usr/lib \
            --runstatedir=/run --sbindir=/usr/sbin \
            --disable-chfn-chsh --disable-login --disable-nologin \
            --disable-su --disable-setpriv --disable-runuser \
            --disable-pylibmount --disable-liblastlog2 --disable-static \
            --without-python \
            --without-systemd --disable-makeinstall-chown \
            ADJTIME_PATH=/var/lib/hwclock/adjtime \
            --docdir=/usr/share/doc/util-linux-2.40.2
make
make install
cd /sources && rm -rf util-linux-2.40.2

# ============================================================
# 8.81 E2fsprogs-1.47.1
# ============================================================
echo ">>> Building E2fsprogs..."
cd /sources && tar -xf e2fsprogs-1.47.1.tar.gz && cd e2fsprogs-1.47.1
mkdir -v build && cd build
../configure --prefix=/usr --sysconfdir=/etc --enable-elf-shlibs \
             --disable-libblkid --disable-libuuid \
             --disable-uuidd --disable-fsck
make
make install
rm -fv /usr/lib/{libcom_err,libe2p,libext2fs,libss}.a
gunzip -v /usr/share/info/libext2fs.info.gz
install-info --dir-file=/usr/share/info/dir /usr/share/info/libext2fs.info
cd /sources && rm -rf e2fsprogs-1.47.1

# ============================================================
# 8.82 Sysklogd-2.6.1
# ============================================================
echo ">>> Building Sysklogd..."
cd /sources && tar -xf sysklogd-2.6.1.tar.gz && cd sysklogd-2.6.1
./configure --prefix=/usr --sysconfdir=/etc \
            --without-logger
make
make install

cat > /etc/syslog.conf << "EOF"
auth,authpriv.* -/var/log/auth.log
*.*;auth,authpriv.none -/var/log/sys.log
daemon.* -/var/log/daemon.log
kern.* -/var/log/kern.log
mail.* -/var/log/mail.log
user.* -/var/log/user.log
*.emerg *
EOF
cd /sources && rm -rf sysklogd-2.6.1

# ============================================================
# 8.83 SysVinit-3.10
# ============================================================
echo ">>> Building SysVinit..."
cd /sources && tar -xf sysvinit-3.10.tar.xz && cd sysvinit-3.10
patch -Np1 -i /sources/sysvinit-3.10-consolidated-1.patch
make
make install
cd /sources && rm -rf sysvinit-3.10

# ============================================================
# 8.84 Stripping (optional - save space)
# ============================================================
echo ">>> Stripping debug symbols..."
save_usrlib="$(cd /usr/lib; ls ld-linux*)"
save_usrlib="$save_usrlib libc.so.6 libthread_db.so.1 libquadmath.so.0.0.0
libstdc++.so.6.0.33 libitm.so.1.0.0 libatomic.so.1.2.0"

cd /usr/lib
for LIB in $save_usrlib; do
    objcopy --only-keep-debug "$LIB" "$LIB.dbg" 2>/dev/null || true
    cp "$LIB" /tmp/"$LIB" 2>/dev/null || true
    strip --strip-unneeded "$LIB" 2>/dev/null || true
    objcopy --add-gnu-debuglink="$LIB.dbg" "$LIB" 2>/dev/null || true
done

find /usr/lib -type f -name \*.a -exec strip --strip-debug {} ';' 2>/dev/null || true
find /usr/lib -type f -name \*.so* ! -name \*dbg \
  -exec strip --strip-unneeded {} ';' 2>/dev/null || true
find /usr/{bin,sbin,libexec} -type f \
  -exec strip --strip-all {} ';' 2>/dev/null || true

# Cleanup
rm -rf /tmp/{*,.??*} 2>/dev/null || true
find /usr/lib /usr/libexec -name \*.la -delete 2>/dev/null || true
find /usr -depth -name share -type d -empty -delete 2>/dev/null || true

# Remove test user
userdel -r tester 2>/dev/null || true

echo "=== Chapter 8: System build complete ==="
