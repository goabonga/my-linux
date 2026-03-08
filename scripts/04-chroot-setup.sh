#!/bin/bash
# LFS 12.2 - Chapter 7: Entering Chroot and Building Additional Temporary Tools
# This script prepares the chroot environment and builds temp tools inside it
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

echo "=== Chapter 7: Chroot Environment Setup ==="

# 7.2 Changing Ownership
chown -R root:root "$LFS"/{usr,lib,var,etc,bin,sbin,tools}
case $(uname -m) in
  x86_64) chown -R root:root "$LFS/lib64" ;;
esac

# 7.3 Preparing Virtual Kernel File Systems
mkdir -pv "$LFS"/{dev,proc,sys,run}

# Mount virtual filesystems
mount -v --bind /dev "$LFS/dev"
mount -vt devpts devpts -o gid=5,mode=0620 "$LFS/dev/pts"
mount -vt proc proc "$LFS/proc"
mount -vt sysfs sysfs "$LFS/sys"
mount -vt tmpfs tmpfs "$LFS/run"

if [ -h "$LFS/dev/shm" ]; then
  install -v -d -m 1777 "$LFS/$(readlink "$LFS/dev/shm")"
else
  mount -vt tmpfs -o nosuid,nodev tmpfs "$LFS/dev/shm"
fi

# 7.4 Entering the Chroot Environment
# We create a script that will be executed inside chroot
mkdir -pv "$LFS/tmp"
cat > "$LFS/tmp/build-chroot-tools.sh" << 'CHROOT_SCRIPT'
#!/bin/bash
set -euo pipefail

export MAKEFLAGS="-j$(nproc)"

# 7.5 Creating Directories
mkdir -pv /{boot,home,mnt,opt,srv}
mkdir -pv /etc/{opt,sysconfig}
mkdir -pv /lib/firmware
mkdir -pv /media/{floppy,cdrom}
mkdir -pv /usr/{,local/}{include,src}
mkdir -pv /usr/local/{bin,lib,sbin}
mkdir -pv /usr/{,local/}share/{color,dict,doc,info,locale,man}
mkdir -pv /usr/{,local/}share/{misc,terminfo,zoneinfo}
mkdir -pv /usr/{,local/}share/man/man{1..8}
mkdir -pv /var/{cache,local,log,mail,opt,spool}
mkdir -pv /var/lib/{color,misc,locate}

ln -sfv /run /var/run
ln -sfv /run/lock /var/lock

install -dv -m 0750 /root
install -dv -m 1777 /tmp /var/tmp

# 7.6 Creating Essential Files and Symlinks
ln -sv /proc/self/mounts /etc/mtab

cat > /etc/hosts << EOF
127.0.0.1  localhost
::1        localhost
EOF

cat > /etc/passwd << "EOF"
root:x:0:0:root:/root:/bin/bash
bin:x:1:1:bin:/dev/null:/usr/bin/false
daemon:x:6:6:Daemon User:/dev/null:/usr/bin/false
messagebus:x:18:18:D-Bus Message Daemon User:/run/dbus:/usr/bin/false
uuidd:x:80:80:UUID Generation Daemon User:/dev/null:/usr/bin/false
nobody:x:65534:65534:Nobody:/nonexistent:/usr/bin/false
EOF

cat > /etc/group << "EOF"
root:x:0:
bin:x:1:daemon
sys:x:2:
kmem:x:3:
tape:x:4:
tty:x:5:
daemon:x:6:
floppy:x:7:
disk:x:8:
lp:x:9:
dialout:x:10:
audio:x:11:
video:x:12:
utmp:x:13:
cdrom:x:15:
adm:x:16:
messagebus:x:18:
input:x:24:
mail:x:34:
kvm:x:61:
uuidd:x:80:
wheel:x:97:
users:x:999:
nogroup:x:65534:
EOF

# Test user for some packages
echo "tester:x:101:101::/home/tester:/bin/bash" >> /etc/passwd
echo "tester:x:101:" >> /etc/group
install -o tester -d /home/tester

touch /var/log/{btmp,lastlog,faillog,wtmp}
chgrp -v utmp /var/log/lastlog
chmod -v 664  /var/log/lastlog
chmod -v 600  /var/log/btmp

# ============================================================
# 7.7 Gettext-0.22.5 (temporary)
# ============================================================
echo ">>> Building Gettext (temp)..."
cd /sources
tar -xf gettext-0.22.5.tar.xz && cd gettext-0.22.5
./configure --disable-shared
make
cp -v gettext-tools/src/{msgfmt,msgmerge,xgettext} /usr/bin
cd /sources && rm -rf gettext-0.22.5

# ============================================================
# 7.8 Bison-3.8.2 (temporary)
# ============================================================
echo ">>> Building Bison (temp)..."
cd /sources
tar -xf bison-3.8.2.tar.xz && cd bison-3.8.2
./configure --prefix=/usr --docdir=/usr/share/doc/bison-3.8.2
make
make install
cd /sources && rm -rf bison-3.8.2

# ============================================================
# 7.9 Perl-5.40.0 (temporary)
# ============================================================
echo ">>> Building Perl (temp)..."
cd /sources
tar -xf perl-5.40.0.tar.xz && cd perl-5.40.0
sh Configure -des \
             -D prefix=/usr \
             -D vendorprefix=/usr \
             -D useshrplib \
             -D privlib=/usr/lib/perl5/5.40/core_perl \
             -D archlib=/usr/lib/perl5/5.40/core_perl \
             -D sitelib=/usr/lib/perl5/5.40/site_perl \
             -D sitearch=/usr/lib/perl5/5.40/site_perl \
             -D vendorlib=/usr/lib/perl5/5.40/vendor_perl \
             -D vendorarch=/usr/lib/perl5/5.40/vendor_perl
make
make install
cd /sources && rm -rf perl-5.40.0

# ============================================================
# 7.10 Python-3.12.5 (temporary)
# ============================================================
echo ">>> Building Python (temp)..."
cd /sources
tar -xf Python-3.12.5.tar.xz && cd Python-3.12.5
./configure --prefix=/usr --without-ensurepip
make
make install
cd /sources && rm -rf Python-3.12.5

# ============================================================
# 7.11 Texinfo-7.1 (temporary)
# ============================================================
echo ">>> Building Texinfo (temp)..."
cd /sources
tar -xf texinfo-7.1.tar.xz && cd texinfo-7.1
./configure --prefix=/usr
make
make install
cd /sources && rm -rf texinfo-7.1

# ============================================================
# 7.12 Util-linux-2.40.2 (temporary)
# ============================================================
echo ">>> Building Util-linux (temp)..."
cd /sources
tar -xf util-linux-2.40.2.tar.xz && cd util-linux-2.40.2
mkdir -pv /var/lib/hwclock
./configure --libdir=/usr/lib \
            --runstatedir=/run \
            --disable-chfn-chsh \
            --disable-login \
            --disable-nologin \
            --disable-su \
            --disable-setpriv \
            --disable-runuser \
            --disable-pylibmount \
            --disable-static \
            --disable-liblastlog2 \
            --without-python \
            ADJTIME_PATH=/var/lib/hwclock/adjtime \
            --docdir=/usr/share/doc/util-linux-2.40.2
make
make install
cd /sources && rm -rf util-linux-2.40.2

# 7.13 Cleanup
rm -rf /usr/share/{info,man,doc}/*
find /usr/{lib,libexec} -name \*.la -delete
rm -rf /tools

echo "=== Chroot temporary tools complete ==="
CHROOT_SCRIPT

chmod +x "$LFS/tmp/build-chroot-tools.sh"

# Enter chroot and run the script
chroot "$LFS" /usr/bin/env -i \
    HOME=/root \
    TERM="$TERM" \
    PS1='(lfs chroot) \u:\w\$ ' \
    PATH=/usr/bin:/usr/sbin \
    MAKEFLAGS="-j$(nproc)" \
    /bin/bash /tmp/build-chroot-tools.sh

echo "=== Chapter 7: Chroot setup complete ==="
