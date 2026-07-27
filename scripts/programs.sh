CAJU=/mnt/cajurootfs

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

    cd ..
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

    cd ..
}

toybox() {
    print "Downloading toybox source..."
    wget -nc https://landley.net/toybox/downloads/toybox-0.8.14.tar.gz
    tar -xzf toybox-0.8.14.tar.gz
    cd toybox-0.8.14

    cat > /tmp/toycc << 'EOF'
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
    make CC=/tmp/toycc HOSTCC="clang" LDFLAGS=--static toybox

    print "Installing toybox into Caju..."
    sudo cp toybox "$CAJU/bin/"
    print "Success toybox Installed in Caju"

    print "Installing toybox symlinks..."
    for cmd in $(./toybox); do 
         sudo ln -sf /caju/bin/toybox "$CAJU/caju/bin/$cmd"
    done
    print "=== Toybox symlinks installed ==="

    cd ..
}