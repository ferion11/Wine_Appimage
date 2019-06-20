#!/bin/bash
# Enable Multilib
sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf

pacman -Syy
pacman -S --noconfirm wget file pacman-contrib tar grep gcc lib32-gcc-libs
# Get Wine
wget -nv -c https://www.playonlinux.com/wine/binaries/phoenicis/upstream-linux-x86/PlayOnLinux-wine-4.10-upstream-linux-x86.tar.gz
mkdir wineversion
tar xfv PlayOnLinux-wine-* -C wineversion/
ls -al

# compile & strip libhookexecv wine-preloader_hook
gcc -shared -fPIC -m32 -ldl src/libhookexecv.c -o src/libhookexecv.so
gcc -std=c99 -m32 -static src/preloaderhook.c -o src/wine-preloader_hook
strip src/libhookexecv.so src/wine-preloader_hook
chmod +x src/wine-preloader_hook

wineworkdir=(wineversion)
cd $wineworkdir

# Add a dependency library, such as freetype font library
dependencys=$(pactree -s -u wine |grep lib32 | xargs)

mkdir cache

pacman -Scc --noconfirm
pacman -Syw  --noconfirm --cachedir cache lib32-alsa-plugins lib32-fontconfig lib32-gst-plugins-base-libs lib32-mpg123 lib32-vulkan-intel lib32-vulkan-radeon lib32-vulkan-icd-loader $dependencys

find ./cache -name '*tar.xz' -exec tar --warning=no-unknown-keyword -xJf {} \;

rm -rf cache; rm -rf include; rm -rf usr/lib; rm usr/lib32/{*.a,*.o}; rm -rf usr/lib32/pkgconfig; rm -rf share/man; rm -rf usr/include; rm -rf usr/share/{applications,doc,emacs,gtk-doc,java,licenses,man,info,pkgconfig}

# Disable winemenubuilder
sed -i 's/winemenubuilder.exe -a -r/winemenubuilder.exe -r/g' share/wine/wine.inf

# appimage
cd -

wget -nv -c "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage" -O  appimagetool.AppImage
chmod +x appimagetool.AppImage

cat > AppRun <<\EOF
#!/bin/bash
HERE="$(dirname "$(readlink -f "${0}")")"

export LD_LIBRARY_PATH="$HERE/usr/lib":$LD_LIBRARY_PATH
export LD_LIBRARY_PATH="$HERE/usr/lib32":$LD_LIBRARY_PATH
export LD_LIBRARY_PATH="$HERE/lib":$LD_LIBRARY_PATH

#Sound Library
export LD_LIBRARY_PATH="$HERE/usr/lib32/pulseaudio":$LD_LIBRARY_PATH
export LD_LIBRARY_PATH="$HERE/usr/lib32/alsa-lib":$LD_LIBRARY_PATH

#Font Config
export FONTCONFIG_PATH="$HERE/etc/fonts"

#LD
export WINELDLIBRARY="$HERE/usr/lib/ld-linux.so.2"

#Wine env
export WINEDEBUG=fixme-all

if [ -n "$*" ] ; then
    LD_PRELOAD="$HERE/bin/libhookexecv.so" "$WINELDLIBRARY" "$HERE/bin/$@" | cat
else
    LD_PRELOAD="$HERE/bin/libhookexecv.so" "$WINELDLIBRARY" "$HERE/bin/wine" "$@" | cat
fi
EOF

chmod +x AppRun

cp src/{libhookexecv.so,wine-preloader_hook} $wineworkdir/bin
rm src/{libhookexecv.so,wine-preloader_hook}

cp AppRun $wineworkdir
cp resource/* $wineworkdir

ln -s lib32 lib
mv lib $wineworkdir/usr

./appimagetool.AppImage --appimage-extract

export ARCH=x86_64; squashfs-root/AppRun -v $wineworkdir -u 'gh-releases-zsync|mmtrt|Wine_Appimage|continuous|wine*arch*.AppImage.zsync' wine-i386_${ARCH}-arch.latest.AppImage
