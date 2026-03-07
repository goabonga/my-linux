#!/bin/bash
# LFS 12.2 - Chapter 8: Installing Basic System Software
# This script runs INSIDE the chroot environment
set -euo pipefail

export MAKEFLAGS="-j$(nproc)"

echo "=== Chapter 8: Building the LFS System ==="

# ============================================================
# 8.3 Man-pages-6.9.1
# ============================================================
echo ">>> Installing Man-pages..."
cd /sources && tar -xf man-pages-6.9.1.tar.xz && cd man-pages-6.9.1
rm -v man3/crypt*
make prefix=/usr install
cd /sources && rm -rf man-pages-6.9.1

# ============================================================
# 8.4 Iana-Etc-20240806
# ============================================================
echo ">>> Installing Iana-Etc..."
cd /sources && tar -xf iana-etc-20240806.tar.gz && cd iana-etc-20240806
cp services protocols /etc
cd /sources && rm -rf iana-etc-20240806

# ============================================================
# 8.5 Glibc-2.40
# ============================================================
echo ">>> Building Glibc (final)..."
cd /sources && tar -xf glibc-2.40.tar.xz && cd glibc-2.40
patch -Np1 -i /sources/glibc-2.40-fhs-1.patch
mkdir -v build && cd build
echo "rootsbindir=/usr/sbin" > configparms
../configure --prefix=/usr \
             --disable-werror \
             --enable-kernel=4.19 \
             --enable-stack-protector=strong \
             --disable-nscd \
             libc_cv_slibdir=/usr/lib
make
# Skip test suite in CI for speed
# make check
touch /etc/ld.so.conf
sed '/test-hierarchical-cleanup/d' -i ../Makefile
make install
sed '/HIERARCHICAL/d' -i /etc/ld.so.conf
# Install locale (minimal set)
mkdir -pv /usr/lib/locale
localedef -i C -f UTF-8 C.UTF-8
localedef -i en_US -f UTF-8 en_US.UTF-8

cat > /etc/nsswitch.conf << "EOF"
passwd: files
group: files
shadow: files
hosts: files dns
networks: files
protocols: files
services: files
ethers: files
rpc: files
EOF

cat > /etc/ld.so.conf << "EOF"
/usr/local/lib
/opt/lib
EOF

cd /sources && rm -rf glibc-2.40

# ============================================================
# 8.6 Zlib-1.3.1
# ============================================================
echo ">>> Building Zlib..."
cd /sources && tar -xf zlib-1.3.1.tar.gz && cd zlib-1.3.1
./configure --prefix=/usr
make
make install
rm -fv /usr/lib/libz.a
cd /sources && rm -rf zlib-1.3.1

# ============================================================
# 8.7 Bzip2-1.0.8
# ============================================================
echo ">>> Building Bzip2..."
cd /sources && tar -xf bzip2-1.0.8.tar.gz && cd bzip2-1.0.8
patch -Np1 -i /sources/bzip2-1.0.8-install_docs-1.patch
sed -i 's@\(ln -s -f \)$(PREFIX)/bin/@\1@' Makefile
sed -i "s@(PREFIX)/man@(PREFIX)/share/man@g" Makefile
make -f Makefile-libbz2_so
make clean
make
make PREFIX=/usr install
cp -av libbz2.so.* /usr/lib
ln -sv libbz2.so.1.0.8 /usr/lib/libbz2.so
cp -v bzip2-shared /usr/bin/bzip2
for i in /usr/bin/{bzcat,bunzip2}; do
  ln -sfv bzip2 $i
done
rm -fv /usr/lib/libbz2.a
cd /sources && rm -rf bzip2-1.0.8

# ============================================================
# 8.8 Xz-5.6.2
# ============================================================
echo ">>> Building Xz..."
cd /sources && tar -xf xz-5.6.2.tar.xz && cd xz-5.6.2
./configure --prefix=/usr --disable-static --docdir=/usr/share/doc/xz-5.6.2
make
make install
cd /sources && rm -rf xz-5.6.2

# ============================================================
# 8.9 Zstd-1.5.6
# ============================================================
echo ">>> Building Zstd..."
cd /sources && tar -xf zstd-1.5.6.tar.gz && cd zstd-1.5.6
make prefix=/usr
make prefix=/usr install
rm -v /usr/lib/libzstd.a
cd /sources && rm -rf zstd-1.5.6

# ============================================================
# 8.10 File-5.45
# ============================================================
echo ">>> Building File..."
cd /sources && tar -xf file-5.45.tar.gz && cd file-5.45
./configure --prefix=/usr
make
make install
cd /sources && rm -rf file-5.45

# ============================================================
# 8.11 Readline-8.2.13
# ============================================================
echo ">>> Building Readline..."
cd /sources && tar -xf readline-8.2.13.tar.gz && cd readline-8.2.13
patch -Np1 -i /sources/readline-8.2.13-upstream_fixes-1.patch
sed -i '/MV.*teledit.old/d' Makefile.in
./configure --prefix=/usr --disable-static --with-curses \
            --docdir=/usr/share/doc/readline-8.2.13
make SHLIB_LIBS="-lncursesw"
make SHLIB_LIBS="-lncursesw" install
cd /sources && rm -rf readline-8.2.13

# ============================================================
# 8.12 M4-1.4.19
# ============================================================
echo ">>> Building M4..."
cd /sources && tar -xf m4-1.4.19.tar.xz && cd m4-1.4.19
./configure --prefix=/usr
make
make install
cd /sources && rm -rf m4-1.4.19

# ============================================================
# 8.13 Bc-7.0.3
# ============================================================
echo ">>> Building Bc..."
cd /sources && tar -xf bc-7.0.3.tar.xz && cd bc-7.0.3
CC=gcc ./configure --prefix=/usr -G -O3 -r
make
make install
cd /sources && rm -rf bc-7.0.3

# ============================================================
# 8.14 Flex-2.6.4
# ============================================================
echo ">>> Building Flex..."
cd /sources && tar -xf flex-2.6.4.tar.gz && cd flex-2.6.4
./configure --prefix=/usr --docdir=/usr/share/doc/flex-2.6.4 --disable-static
make
make install
ln -sv flex /usr/bin/lex
ln -sv flex.1 /usr/share/man/man1/lex.1
cd /sources && rm -rf flex-2.6.4

# ============================================================
# 8.15 Tcl-8.6.14
# ============================================================
echo ">>> Building Tcl..."
cd /sources && tar -xf tcl8.6.14-src.tar.gz && cd tcl8.6.14
SRCDIR=$(pwd)
cd unix
./configure --prefix=/usr --mandir=/usr/share/man --disable-rpath
make
sed -e "s|$SRCDIR/unix|/usr/lib|" -e "s|$SRCDIR|/usr/include|" -i tclConfig.sh
sed -e "s|$SRCDIR/unix/pkgs/tdbc1.1.7|/usr/lib/tdbc1.1.7|" \
    -e "s|$SRCDIR/pkgs/tdbc1.1.7/generic|/usr/include|" \
    -e "s|$SRCDIR/pkgs/tdbc1.1.7/library|/usr/lib/tcl8.6|" \
    -e "s|$SRCDIR/pkgs/tdbc1.1.7|/usr/include|" \
    -i pkgs/tdbc1.1.7/tdbcConfig.sh
sed -e "s|$SRCDIR/unix/pkgs/itcl4.2.4|/usr/lib/itcl4.2.4|" \
    -e "s|$SRCDIR/pkgs/itcl4.2.4/generic|/usr/include|" \
    -e "s|$SRCDIR/pkgs/itcl4.2.4|/usr/include|" \
    -i pkgs/itcl4.2.4/itclConfig.sh
unset SRCDIR
make install
chmod -v u+w /usr/lib/libtcl8.6.so
make install-private-headers
ln -sfv tclsh8.6 /usr/bin/tclsh
cd /sources && rm -rf tcl8.6.14

# ============================================================
# 8.16 Expect-5.45.4
# ============================================================
echo ">>> Building Expect..."
cd /sources && tar -xf expect5.45.4.tar.gz && cd expect5.45.4
python3 -c 'from pty import spawn; spawn(["echo","ok"])' || true
./configure --prefix=/usr --with-tcl=/usr/lib --enable-shared \
            --mandir=/usr/share/man --with-tclinclude=/usr/include
make
make install
ln -svf expect5.45.4/libexpect5.45.4.so /usr/lib
cd /sources && rm -rf expect5.45.4

# ============================================================
# 8.17 DejaGNU-1.6.3
# ============================================================
echo ">>> Building DejaGNU..."
cd /sources && tar -xf dejagnu-1.6.3.tar.gz && cd dejagnu-1.6.3
mkdir -v build && cd build
../configure --prefix=/usr
makeinfo --html --no-split -o doc/dejagnu.html ../doc/dejagnu.texi
makeinfo --plaintext -o doc/dejagnu.txt ../doc/dejagnu.texi
make install
cd /sources && rm -rf dejagnu-1.6.3

# ============================================================
# 8.18 Pkgconf-2.3.0
# ============================================================
echo ">>> Building Pkgconf..."
cd /sources && tar -xf pkgconf-2.3.0.tar.xz && cd pkgconf-2.3.0
./configure --prefix=/usr --disable-static \
            --docdir=/usr/share/doc/pkgconf-2.3.0
make
make install
ln -sv pkgconf /usr/bin/pkg-config
ln -sv pkgconf.1 /usr/share/man/man1/pkg-config.1
cd /sources && rm -rf pkgconf-2.3.0

# ============================================================
# 8.19 Binutils-2.43.1
# ============================================================
echo ">>> Building Binutils (final)..."
cd /sources && tar -xf binutils-2.43.1.tar.xz && cd binutils-2.43.1
mkdir -v build && cd build
../configure --prefix=/usr --sysconfdir=/etc --enable-gold \
             --enable-ld=default --enable-plugins \
             --enable-shared --disable-werror --enable-64-bit-bfd \
             --enable-new-dtags --with-system-zlib --enable-default-hash-style=gnu
make tooldir=/usr
make tooldir=/usr install
rm -fv /usr/lib/lib{bfd,ctf,ctf-nobfd,gprofng,opcodes,sframe}.a
cd /sources && rm -rf binutils-2.43.1

# ============================================================
# 8.20 GMP-6.3.0
# ============================================================
echo ">>> Building GMP..."
cd /sources && tar -xf gmp-6.3.0.tar.xz && cd gmp-6.3.0
./configure --prefix=/usr --enable-cxx --disable-static \
            --docdir=/usr/share/doc/gmp-6.3.0
make
make install
cd /sources && rm -rf gmp-6.3.0

# ============================================================
# 8.21 MPFR-4.2.1
# ============================================================
echo ">>> Building MPFR..."
cd /sources && tar -xf mpfr-4.2.1.tar.xz && cd mpfr-4.2.1
./configure --prefix=/usr --disable-static \
            --enable-thread-safe --docdir=/usr/share/doc/mpfr-4.2.1
make
make install
cd /sources && rm -rf mpfr-4.2.1

# ============================================================
# 8.22 MPC-1.3.1
# ============================================================
echo ">>> Building MPC..."
cd /sources && tar -xf mpc-1.3.1.tar.gz && cd mpc-1.3.1
./configure --prefix=/usr --disable-static \
            --docdir=/usr/share/doc/mpc-1.3.1
make
make install
cd /sources && rm -rf mpc-1.3.1

# ============================================================
# 8.23 Attr-2.5.2
# ============================================================
echo ">>> Building Attr..."
cd /sources && tar -xf attr-2.5.2.tar.gz && cd attr-2.5.2
./configure --prefix=/usr --disable-static --sysconfdir=/etc \
            --docdir=/usr/share/doc/attr-2.5.2
make
make install
cd /sources && rm -rf attr-2.5.2

# ============================================================
# 8.24 Acl-2.3.2
# ============================================================
echo ">>> Building Acl..."
cd /sources && tar -xf acl-2.3.2.tar.xz && cd acl-2.3.2
./configure --prefix=/usr --disable-static --docdir=/usr/share/doc/acl-2.3.2
make
make install
cd /sources && rm -rf acl-2.3.2

# ============================================================
# 8.25 Libcap-2.70
# ============================================================
echo ">>> Building Libcap..."
cd /sources && tar -xf libcap-2.70.tar.xz && cd libcap-2.70
sed -i '/install -m.*STA/d' libcap/Makefile
make prefix=/usr lib=lib
make prefix=/usr lib=lib install
cd /sources && rm -rf libcap-2.70

# ============================================================
# 8.26 Libxcrypt-4.4.36
# ============================================================
echo ">>> Building Libxcrypt..."
cd /sources && tar -xf libxcrypt-4.4.36.tar.xz && cd libxcrypt-4.4.36
./configure --prefix=/usr --enable-hashes=strong,glibc \
            --enable-obsolete-api=no --disable-static \
            --disable-failure-tokens
make
make install
cd /sources && rm -rf libxcrypt-4.4.36

# ============================================================
# 8.27 Shadow-4.16.0
# ============================================================
echo ">>> Building Shadow..."
cd /sources && tar -xf shadow-4.16.0.tar.xz && cd shadow-4.16.0
sed -i 's/groups$(EXEEXT) //' src/Makefile.in
find man -name Makefile.in -exec sed -i 's/groups\.1 / /' {} \;
find man -name Makefile.in -exec sed -i 's/getspnam\.3 / /' {} \;
find man -name Makefile.in -exec sed -i 's/passwd\.5 / /' {} \;
sed -e 's:#ENCRYPT_METHOD DES:ENCRYPT_METHOD YESCRYPT:' \
    -e 's:/var/spool/mail:/var/mail:' \
    -e '/PATH=/{s@/sbin:@@;s@/bin:@@}' \
    -i etc/login.defs
touch /usr/bin/passwd
./configure --sysconfdir=/etc --disable-static \
            --with-{b,yes}crypt --without-libbsd --with-group-name-max-length=32
make
make exec_prefix=/usr install
make -C man install-man
pwconv
grpconv
mkdir -p /etc/default
useradd -D --gid 999
# Set root password (empty for CI)
echo "root:root" | chpasswd
cd /sources && rm -rf shadow-4.16.0

# ============================================================
# 8.28 GCC-14.2.0
# ============================================================
echo ">>> Building GCC (final)..."
cd /sources && tar -xf gcc-14.2.0.tar.xz && cd gcc-14.2.0
case $(uname -m) in
  x86_64)
    sed -e '/m64=/s/lib64/lib/' -i.orig gcc/config/i386/t-linux64
    ;;
esac
mkdir -v build && cd build
../configure --prefix=/usr LD=ld \
             --enable-languages=c,c++ \
             --enable-default-pie \
             --enable-default-ssp \
             --enable-host-pie \
             --disable-multilib \
             --disable-bootstrap \
             --disable-fixincludes \
             --with-system-zlib
make
make install
ln -svr /usr/bin/cpp /usr/lib
ln -sv gcc.1 /usr/share/man/man1/cc.1
ln -sfv ../../libexec/gcc/$(gcc -dumpmachine)/14.2.0/liblto_plugin.so \
        /usr/lib/bfd-plugins/
# Sanity check
echo 'int main(){}' > dummy.c
cc dummy.c -v -Wl,--verbose &> dummy.log
readelf -l a.out | grep ': /lib'
rm -v dummy.c a.out dummy.log
mkdir -pv /usr/share/gdb/auto-load/usr/lib
mv -v /usr/lib/*gdb.py /usr/share/gdb/auto-load/usr/lib
cd /sources && rm -rf gcc-14.2.0

# ============================================================
# 8.29 Ncurses-6.5
# ============================================================
echo ">>> Building Ncurses (final)..."
cd /sources && tar -xf ncurses-6.5.tar.gz && cd ncurses-6.5
./configure --prefix=/usr --mandir=/usr/share/man --with-shared \
            --without-debug --without-normal --with-cxx-shared \
            --enable-pc-files --with-pkg-config-libdir=/usr/lib/pkgconfig
make
make DESTDIR="$PWD/dest" install
install -vm755 dest/usr/lib/libncursesw.so.6.5 /usr/lib
rm -v /usr/lib/libncursesw.so.6
cp -av dest/usr/lib/libncursesw.so.6 /usr/lib
ln -sfv libncursesw.so.6 /usr/lib/libncursesw.so
cp -av dest/usr/lib/libncurses.so /usr/lib
cp -av dest/usr/lib/libncurses++w.so* /usr/lib
install -vm644 dest/usr/lib/pkgconfig/*.pc /usr/lib/pkgconfig
rm -v  dest/usr/lib/libncursesw.so.6
cp -av dest/usr/* /usr/
for lib in ncurses form panel menu ; do
    ln -sfv lib${lib}w.so /usr/lib/lib${lib}.so
    ln -sfv ${lib}w.pc /usr/lib/pkgconfig/${lib}.pc
done
ln -sfv libncursesw.so /usr/lib/libcurses.so
cp -v -R dest/usr/share/* /usr/share/
cd /sources && rm -rf ncurses-6.5

# ============================================================
# 8.30 Sed-4.9
# ============================================================
echo ">>> Building Sed (final)..."
cd /sources && tar -xf sed-4.9.tar.xz && cd sed-4.9
./configure --prefix=/usr
make
make install
cd /sources && rm -rf sed-4.9

# ============================================================
# 8.31 Psmisc-23.7
# ============================================================
echo ">>> Building Psmisc..."
cd /sources && tar -xf psmisc-23.7.tar.xz && cd psmisc-23.7
./configure --prefix=/usr
make
make install
cd /sources && rm -rf psmisc-23.7

# ============================================================
# 8.32 Gettext-0.22.5
# ============================================================
echo ">>> Building Gettext (final)..."
cd /sources && tar -xf gettext-0.22.5.tar.xz && cd gettext-0.22.5
./configure --prefix=/usr --disable-static \
            --docdir=/usr/share/doc/gettext-0.22.5
make
make install
chmod -v 0755 /usr/lib/preloadable_libintl.so
cd /sources && rm -rf gettext-0.22.5

# ============================================================
# 8.33 Bison-3.8.2
# ============================================================
echo ">>> Building Bison (final)..."
cd /sources && tar -xf bison-3.8.2.tar.xz && cd bison-3.8.2
./configure --prefix=/usr --docdir=/usr/share/doc/bison-3.8.2
make
make install
cd /sources && rm -rf bison-3.8.2

# ============================================================
# 8.34 Grep-3.11
# ============================================================
echo ">>> Building Grep (final)..."
cd /sources && tar -xf grep-3.11.tar.xz && cd grep-3.11
sed -i "s/echo/#echo/" src/egrep.sh
./configure --prefix=/usr
make
make install
cd /sources && rm -rf grep-3.11

# ============================================================
# 8.35 Bash-5.2.32
# ============================================================
echo ">>> Building Bash (final)..."
cd /sources && tar -xf bash-5.2.32.tar.gz && cd bash-5.2.32
./configure --prefix=/usr --without-bash-malloc \
            --with-installed-readline bash_cv_strtold_broken=no \
            --docdir=/usr/share/doc/bash-5.2.32
make
make install
cd /sources && rm -rf bash-5.2.32

# ============================================================
# 8.36 Libtool-2.4.7
# ============================================================
echo ">>> Building Libtool..."
cd /sources && tar -xf libtool-2.4.7.tar.xz && cd libtool-2.4.7
./configure --prefix=/usr
make
make install
rm -fv /usr/lib/libltdl.a
cd /sources && rm -rf libtool-2.4.7

# ============================================================
# 8.37 GDBM-1.24
# ============================================================
echo ">>> Building GDBM..."
cd /sources && tar -xf gdbm-1.24.tar.gz && cd gdbm-1.24
./configure --prefix=/usr --disable-static --enable-libgdbm-compat
make
make install
cd /sources && rm -rf gdbm-1.24

# ============================================================
# 8.38 Gperf-3.1
# ============================================================
echo ">>> Building Gperf..."
cd /sources && tar -xf gperf-3.1.tar.gz && cd gperf-3.1
./configure --prefix=/usr --docdir=/usr/share/doc/gperf-3.1
make
make install
cd /sources && rm -rf gperf-3.1

# ============================================================
# 8.39 Expat-2.6.2
# ============================================================
echo ">>> Building Expat..."
cd /sources && tar -xf expat-2.6.2.tar.xz && cd expat-2.6.2
./configure --prefix=/usr --disable-static \
            --docdir=/usr/share/doc/expat-2.6.2
make
make install
cd /sources && rm -rf expat-2.6.2

# ============================================================
# 8.40 Inetutils-2.5
# ============================================================
echo ">>> Building Inetutils..."
cd /sources && tar -xf inetutils-2.5.tar.xz && cd inetutils-2.5
sed -i 's/def HAVE_DECL_GETPASS/d HAVE_DECL_GETPASS/' lib/getpass.c
./configure --prefix=/usr --bindir=/usr/bin --localstatedir=/var \
            --disable-logger --disable-whois --disable-rcp \
            --disable-rexec --disable-rlogin --disable-rsh \
            --disable-servers
make
make install
mv -v /usr/{,s}bin/ifconfig
cd /sources && rm -rf inetutils-2.5

# ============================================================
# 8.41 Less-661
# ============================================================
echo ">>> Building Less..."
cd /sources && tar -xf less-661.tar.gz && cd less-661
./configure --prefix=/usr --sysconfdir=/etc
make
make install
cd /sources && rm -rf less-661

# ============================================================
# 8.42 Perl-5.40.0
# ============================================================
echo ">>> Building Perl (final)..."
cd /sources && tar -xf perl-5.40.0.tar.xz && cd perl-5.40.0
export BUILD_ZLIB=False BUILD_BZIP2=0
sh Configure -des \
             -D prefix=/usr \
             -D vendorprefix=/usr \
             -D privlib=/usr/lib/perl5/5.40/core_perl \
             -D archlib=/usr/lib/perl5/5.40/core_perl \
             -D sitelib=/usr/lib/perl5/5.40/site_perl \
             -D sitearch=/usr/lib/perl5/5.40/site_perl \
             -D vendorlib=/usr/lib/perl5/5.40/vendor_perl \
             -D vendorarch=/usr/lib/perl5/5.40/vendor_perl \
             -D man1dir=/usr/share/man/man1 \
             -D man3dir=/usr/share/man/man3 \
             -D pager="/usr/bin/less -isR" \
             -D useshrplib \
             -D usethreads
make
make install
unset BUILD_ZLIB BUILD_BZIP2
cd /sources && rm -rf perl-5.40.0

# ============================================================
# 8.43 XML::Parser-2.47
# ============================================================
echo ">>> Building XML::Parser..."
cd /sources && tar -xf XML-Parser-2.47.tar.gz && cd XML-Parser-2.47
perl Makefile.PL
make
make install
cd /sources && rm -rf XML-Parser-2.47

# ============================================================
# 8.44 Intltool-0.51.0
# ============================================================
echo ">>> Building Intltool..."
cd /sources && tar -xf intltool-0.51.0.tar.gz && cd intltool-0.51.0
sed -i 's:\\\${:\$\\{:' intltool-update.in
./configure --prefix=/usr
make
make install
install -v -Dm644 doc/I18N-HOWTO /usr/share/doc/intltool-0.51.0/I18N-HOWTO
cd /sources && rm -rf intltool-0.51.0

# ============================================================
# 8.45 Autoconf-2.72
# ============================================================
echo ">>> Building Autoconf..."
cd /sources && tar -xf autoconf-2.72.tar.xz && cd autoconf-2.72
./configure --prefix=/usr
make
make install
cd /sources && rm -rf autoconf-2.72

# ============================================================
# 8.46 Automake-1.17
# ============================================================
echo ">>> Building Automake..."
cd /sources && tar -xf automake-1.17.tar.xz && cd automake-1.17
./configure --prefix=/usr --docdir=/usr/share/doc/automake-1.17
make
make install
cd /sources && rm -rf automake-1.17

# ============================================================
# 8.47 OpenSSL-3.3.1
# ============================================================
echo ">>> Building OpenSSL..."
cd /sources && tar -xf openssl-3.3.1.tar.gz && cd openssl-3.3.1
./config --prefix=/usr --openssldir=/etc/ssl --libdir=lib \
         shared zlib-dynamic
make
sed -i '/INSTALL_LIBS/s/libcrypto.a libssl.a//' Makefile
make MANSUFFIX=ssl install
cd /sources && rm -rf openssl-3.3.1

# ============================================================
# 8.48 Kmod-33
# ============================================================
echo ">>> Building Kmod..."
cd /sources && tar -xf kmod-33.tar.xz && cd kmod-33
./configure --prefix=/usr --sysconfdir=/etc --with-openssl \
            --with-xz --with-zstd --with-zlib --disable-manpages
make
make install
for target in depmod insmod modinfo modprobe rmmod; do
  ln -sfv ../bin/kmod /usr/sbin/$target
done
ln -sfv kmod /usr/bin/lsmod
cd /sources && rm -rf kmod-33

# ============================================================
# 8.49 Elfutils-0.191
# ============================================================
echo ">>> Building Elfutils..."
cd /sources && tar -xf elfutils-0.191.tar.bz2 && cd elfutils-0.191
./configure --prefix=/usr --disable-debuginfod --enable-libdebuginfod=dummy
make
make -C libelf install
install -vm644 config/libelf.pc /usr/lib/pkgconfig
rm /usr/lib/libelf.a
cd /sources && rm -rf elfutils-0.191

# ============================================================
# 8.50 Libffi-3.4.6
# ============================================================
echo ">>> Building Libffi..."
cd /sources && tar -xf libffi-3.4.6.tar.gz && cd libffi-3.4.6
./configure --prefix=/usr --disable-static --with-gcc-arch=native
make
make install
cd /sources && rm -rf libffi-3.4.6

# ============================================================
# 8.51 Python-3.12.5
# ============================================================
echo ">>> Building Python..."
cd /sources && tar -xf Python-3.12.5.tar.xz && cd Python-3.12.5
./configure --prefix=/usr --enable-shared --with-system-expat \
            --enable-optimizations
make
make install
cat > /etc/pip.conf << EOF
[global]
root-user-action = ignore
disable-pip-version-check = true
EOF
cd /sources && rm -rf Python-3.12.5

# ============================================================
# 8.52 Flit_core-3.9.0
# ============================================================
echo ">>> Installing Flit_core..."
cd /sources && tar -xf flit_core-3.9.0.tar.gz && cd flit_core-3.9.0
pip3 install --no-index --no-build-isolation --find-links dist flit_core
cd /sources && rm -rf flit_core-3.9.0

# ============================================================
# 8.53 Wheel-0.44.0
# ============================================================
echo ">>> Installing Wheel..."
cd /sources && tar -xf wheel-0.44.0.tar.gz && cd wheel-0.44.0
pip3 install --no-index --no-build-isolation --find-links dist wheel
cd /sources && rm -rf wheel-0.44.0

# ============================================================
# 8.54 Setuptools-72.2.0
# ============================================================
echo ">>> Installing Setuptools..."
cd /sources && tar -xf setuptools-72.2.0.tar.gz && cd setuptools-72.2.0
pip3 install --no-index --no-build-isolation --find-links dist setuptools
cd /sources && rm -rf setuptools-72.2.0

# ============================================================
# 8.55 MarkupSafe-2.1.5
# ============================================================
echo ">>> Installing MarkupSafe..."
cd /sources && tar -xf MarkupSafe-2.1.5.tar.gz && cd MarkupSafe-2.1.5
pip3 install --no-index --no-build-isolation --find-links dist MarkupSafe
cd /sources && rm -rf MarkupSafe-2.1.5

# ============================================================
# 8.56 Jinja2-3.1.4
# ============================================================
echo ">>> Installing Jinja2..."
cd /sources && tar -xf jinja2-3.1.4.tar.gz && cd jinja2-3.1.4
pip3 install --no-index --no-build-isolation --find-links dist Jinja2
cd /sources && rm -rf jinja2-3.1.4

echo "=== Chapter 8 Part 1 complete ==="
