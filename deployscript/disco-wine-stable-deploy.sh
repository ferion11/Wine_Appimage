#!/bin/bash
# Pre install
dpkg --add-architecture i386

## Download and add the repository key:
#wget -nv -c https://dl.winehq.org/wine-builds/winehq.key
#apt-key add winehq.key

## Add repository:
#apt-add-repository 'deb https://dl.winehq.org/wine-builds/ubuntu/ disco main'

apt update
apt install -y aptitude wget file bzip2 gcc-multilib

mkdir -p wineversion

# compile & strip libhookexecv wine-preloader_hook
gcc -shared -fPIC -m32 -ldl src/libhookexecv.c -o src/libhookexecv.so
gcc -std=c99 -m32 -static src/preloaderhook.c -o src/wine-preloader_hook
strip src/libhookexecv.so src/wine-preloader_hook
chmod +x src/wine-preloader_hook

wineworkdir=(wineversion/*)
cd $wineworkdir

pkgcachedir='/tmp/.winedeploycache'
mkdir -p $pkgcachedir

aptitude -y -d -o dir::cache::archives="$pkgcachedir" install wine wine32 wine64 libwine libwine:i386 fonts-wine libalsaplayer0 libalsaplayer0:i386

find $pkgcachedir -name '*deb' ! -name 'pulse*' -exec dpkg -x {} . \;

rm -rf $pkgcachedir ; rm -rf share/man ; rm -rf usr/share/doc ; rm -rf usr/share/lintian ; rm -rf var ; rm -rf sbin ; rm -rf usr/share/man ; rm -rf usr/share/mime ; rm -rf usr/share/pkgconfig ; rm -rf usr/share/wine

## Make absolutely sure it will not load stuff from /lib or /usr
#sed -i -e 's|/usr|/xxx|g' lib/ld-linux.so.2
#sed -i -e 's|/usr/lib|/ooo/ooo|g' lib/ld-linux.so.2

## Remove duplicate (why is it there?)
#rm -f lib/i386-linux-gnu/ld-*.so

## Disable winemenubuilder
#sed -i 's/winemenubuilder.exe -a -r/winemenubuilder.exe -r/g' share/wine/wine.inf

# appimage
cd -

wget -nv -c "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage" -O  appimagetool.AppImage
chmod +x appimagetool.AppImage

chmod +x AppRun

cp src/{libhookexecv.so,wine-preloader_hook} $wineworkdir/bin
rm src/{libhookexecv.so,wine-preloader_hook}

cp AppRun $wineworkdir
cp resource/* $wineworkdir

./appimagetool.AppImage --appimage-extract

export ARCH=x86_64; squashfs-root/AppRun -v $wineworkdir -u 'gh-releases-zsync|ferion11|Wine_Appimage|continuous|wine-stable*disco.AppImage.zsync' wine-stable-i386_${ARCH}-disco.AppImage