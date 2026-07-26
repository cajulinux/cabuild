musl() {
    print "Downloading musl source..."
    wget -nc https://git.musl-libc.org/cgit/musl/snapshot/musl-1.2.6.tar.gz
    tar -xzf musl-1.2.6.tar.gz
    cd musl-1.2.6

    print "Configuring and Compiling musl..."
    CC="clang --target=x86_64-unknown-linux-musl" ./configure --prefix=/caju --syslibdir=/caju/lib

    make -j$(nproc)

    print "Installing musl into Caju..."
    sudo make DESTDIR=/mnt/cajurootfs install
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
    sudo cp mksh "/mnt/cajurootfs/caju/bin/"
    sudo ln -sf /caju/bin/mksh "/mnt/cajurootfs/caju/bin/sh"

    print "=== Success mksh Installed in Caju ===" 

    cd ..
}

