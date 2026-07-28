CAJU=/mnt/cajurootfs/
TMPF=/tmp/caju/

musl() {
    print "Downloading musl source..."
    wget -nc https://git.musl-libc.org/cgit/musl/snapshot/musl-1.2.6.tar.gz
    tar -xzf musl-1.2.6.tar.gz
    cd musl-1.2.6

    print "Configuring and Compiling musl..."
    CC="clang --target=x86_64-unknown-linux-musl" ./configure --prefix=/caju --syslibdir=/caju/lib

    make -j$(nproc)

    print "Installing musl into Caju..."
    sudo make DESTDIR=$CAJU install
    print "Success musl Installed in Caju"

    cd $TMPF
}

mksh() {
    print "Downloading mksh source..."
    wget -nc http://www.mirbsd.org/MirOS/dist/mir/mksh/mksh-R59c.tgz
    tar -xzf mksh-R59c.tgz
    cd mksh

    print "Compiling mksh..."
    CC="clang --target=x86_64-unknown-linux-musl" sh Build.sh -r

    print "Installing mksh into Caju..."
    sudo cp mksh "$CAJU/caju/bin/"
    sudo ln -sf /caju/bin/mksh "$CAJU/caju/bin/sh"

    print "=== Success mksh Installed in Caju ===" 

    cd $TMPF
}

toybox() {
    print "Downloading toybox source..."
    wget -nc https://landley.net/toybox/downloads/toybox-0.8.14.tar.gz
    tar -xzf toybox-0.8.14.tar.gz
    cd toybox-0.8.14

    cat > /tmp/toycc <<'EOF'
    #!/usr/bin/sh
    exec clang --target=x86_64-unknown-linux-musl \
        -I/mnt/cajurootfs/caju/include \
        -L/mnt/cajurootfs/caju/lib \
        -B/mnt/cajurootfs/caju/lib \
        "$@"
EOF
    chmod +x /tmp/toycc

    print "Configuring toybox..."
    CC=/tmp/toycc make defconfig

    print "Compiling toybox..."
    make CC=/tmp/toycc HOSTCC="clang" toybox

    print "Installing toybox into Caju..."
    sudo cp toybox "$CAJU/bin/"
    print "Success toybox Installed in Caju"

    print "Installing toybox symlinks..."
    for cmd in $(./toybox); do 
         sudo ln -sf /caju/bin/toybox "$CAJU/caju/bin/$cmd"
    done
    print "=== Toybox symlinks installed ==="

    cd $TMPF
}

runit() {
    print "Downloading runit source..."
    wget -nc https://smarden.org/runit/runit-2.3.1.tar.gz
    tar -xzf runit-2.3.1.tar.gz
    cd admin/runit-2.3.1

    print "Configuring compiler (Hijacking conf-cc and conf-ld)..."
    echo 'clang --target=x86_64-linux-musl -O2 -Wall -Wimplicit -Wunused -Wcomment -Wchar-subscripts -Wuninitialized -Wshadow -Wcast-qual -Wcast-align -Wwrite-strings -I/mnt/cajurootfs/caju/include -L/mnt/cajurootfs/caju/lib -B/mnt/cajurootfs/caju/lib' > src/conf-cc
    echo 'clang --target=x86_64-linux-musl -s -L/mnt/cajurootfs/caju/lib' > src/conf-ld

    print "Compiling runit..."
    package/compile

    print "Installing runit into Caju..."
    sudo cp command/* $CAJU/caju/bin/
    sudo ln -sf runit-init $CAJU/caju/bin/init
    print "=== Sucess runit Installed in Caju ==="

    cd $TMPF
}

linux() {
    print "Downloading kernel source..."
    wget -nc https://cdn.kernel.org/pub/linux/kernel/v7.x/linux-7.1.5.tar.xz
    tar -xJf linux-7.1.5.tar.xz
    cd linux-7.1.5

    print "Configuring kernel..."
    make mrproper
    make ARCH=x86_64 LLVM=1 LLVM_IAS=1 x86_64_defconfig
    make ARCH=x86_64 LLVM=1 LLVM_IAS=1 olddefconfig 	 	

    print "Compiling kernel..."
    KBUILD_BUILD_TIMESTAMP='' make -j$(nproc) ARCH=x86_64 LLVM=1 LLVM_IAS=1 \
    KCFLAGS="-march=x86-64-v3" \
    KAFLAGS="-march=x86-64-v3"

    print "Installing kernel modules..."
    sudo make modules_install -j$(nproc) 

    print "Installing kernel headers"
    sudo make INSTALL_HDR_PATH="$CAJU/caju" headers_install	

    print "Installing kernel..."
    sudo cp arch/x86/boot/bzImage /mnt/cajurootfs/efi/vmlinuz
    print "=== Sucess Kernel Installed in Caju ==="

    cd $TMPF
}

build_base() {
    linux
    musl
    mksh
    toybox
    runit
}