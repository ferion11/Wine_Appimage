#!/bin/bash
# Enable Multilib
sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf

pacman -Syy
#pacman -S --noconfirm wget file pacman-contrib tar grep gcc lib32-gcc-libs
pacman -S --noconfirm wget file pacman-contrib tar grep zstd xz

#===========================================================================================
# Get Wine
#wget -nv -c https://www.playonlinux.com/wine/binaries/phoenicis/upstream-linux-x86/PlayOnLinux-wine-4.10-upstream-linux-x86.tar.gz
#wget -nv -c https://www.playonlinux.com/wine/binaries/phoenicis/upstream-linux-x86/PlayOnLinux-wine-4.21-upstream-linux-x86.tar.gz
wget -nv -c https://www.playonlinux.com/wine/binaries/phoenicis/staging-linux-x86/PlayOnLinux-wine-4.21-staging-linux-x86.tar.gz
mkdir wineversion
tar xf PlayOnLinux-wine-* -C wineversion/

wget -nv -c https://github.com/ferion11/libsutil/releases/download/wine_hook_v0.9/libhookexecv.so
wget -nv -c https://github.com/ferion11/libsutil/releases/download/wine_hook_v0.9/wine-preloader_hook
mv libhookexecv.so src/
mv wine-preloader_hook src/
# compile & strip libhookexecv wine-preloader_hook
#gcc -shared -fPIC -m32 -ldl src/libhookexecv.c -o src/libhookexecv.so
#gcc -std=c99 -m32 -static src/preloaderhook.c -o src/wine-preloader_hook
#strip src/libhookexecv.so src/wine-preloader_hook
chmod +x src/wine-preloader_hook

#===========================================================================================
wineworkdir=(wineversion)
cd $wineworkdir

# Add a dependency library, such as freetype font library
dependencys=$(pactree -s -u wine |grep lib32 | xargs)

mkdir cache

pacman -Scc --noconfirm
pacman -Syw --noconfirm --cachedir cache lib32-alsa-lib lib32-alsa-plugins lib32-faudio lib32-fontconfig lib32-freetype2 lib32-gcc-libs lib32-gettext lib32-giflib lib32-glu lib32-gnutls lib32-gst-plugins-base lib32-lcms2 lib32-libjpeg-turbo lib32-libjpeg6-turbo lib32-libldap lib32-libpcap lib32-libpng lib32-libpng12 lib32-libsm lib32-libxcomposite lib32-libxcursor lib32-libxdamage lib32-libxi lib32-libxml2 lib32-libxmu lib32-libxrandr lib32-libxslt lib32-libxxf86vm lib32-mesa lib32-mesa-libgl lib32-mpg123 lib32-ncurses lib32-openal lib32-sdl2 lib32-v4l-utils lib32-libdrm lib32-libva lib32-krb5 lib32-flac lib32-gst-plugins-good lib32-libcups lib32-libwebp lib32-libvpx lib32-libvpx1.3 lib32-portaudio lib32-sdl lib32-sdl2_image lib32-sdl2_mixer lib32-sdl2_ttf lib32-sdl_image lib32-sdl_mixer lib32-sdl_ttf lib32-smpeg lib32-speex lib32-speexdsp lib32-twolame lib32-virtualgl lib32-ladspa lib32-libao lib32-soundtouch lib32-libxvmc lib32-libvdpau lib32-libpulse lib32-libcanberra-pulse lib32-libcanberra-gstreamer lib32-glew lib32-mesa-demos lib32-jansson lib32-libxinerama lib32-atk lib32-at-spi2-atk lib32-colord lib32-json-glib lib32-libepoxy lib32-librsvg lib32-libxkbcommon lib32-rest lib32-gtk3 $dependencys
#*don't have package (using the archlinux32 packages below): lib32-ffmpeg lib32-gst-libav
# removed vulkan deps for smaller size
# removed for smaller size because wine don't need: lib32-gtk2 lib32-wxgtk2

# Remove non lib32 pkgs before extracting
#echo "All files in ./cache: $(ls ./cache)"
find ./cache -type f ! -name "lib32*" -exec rm {} \; -exec echo "Removing: {}" \;
#find ./cache -type f -name "*x86_64*" -exec rm {} \; -exec echo "Removing: {}" \; #don't work because the name of lib32 multilib packages have the x86_64 too
echo "All files in ./cache: $(ls ./cache)"

# Add the archlinux32 pentium4 packages (lib32-ffmpeg lib32-gst-libav and deps):
wget -nv -c http://pool.mirror.archlinux32.org/pentium4/extra/gst-libav-1.16.2-1.0-pentium4.pkg.tar.xz -P ./cache/
wget -nv -c http://pool.mirror.archlinux32.org/pentium4/staging/ffmpeg-1:4.2.1-4.5-pentium4.pkg.tar.xz -P ./cache/
wget -nv -c http://pool.mirror.archlinux32.org/pentium4/extra/aom-1.0.0.errata1-1.2-pentium4.pkg.tar.xz -P ./cache/
wget -nv -c http://pool.mirror.archlinux32.org/pentium4/extra/gsm-1.0.18-1.4-pentium4.pkg.tar.xz -P ./cache/
wget -nv -c http://pool.mirror.archlinux32.org/pentium4/extra/lame-3.100-2.1-pentium4.pkg.tar.xz -P ./cache/
wget -nv -c http://pool.mirror.archlinux32.org/pentium4/staging/libass-0.14.0-1.10-pentium4.pkg.tar.xz -P ./cache/
wget -nv -c http://pool.mirror.archlinux32.org/pentium4/staging/libbluray-1.1.2-1.7-pentium4.pkg.tar.xz -P ./cache/
wget -nv -c http://pool.mirror.archlinux32.org/pentium4/extra/dav1d-0.5.2-1.0-pentium4.pkg.tar.xz -P ./cache/
wget -nv -c http://pool.mirror.archlinux32.org/pentium4/extra/libomxil-bellagio-0.9.3-2.4-pentium4.pkg.tar.xz -P ./cache/
wget -nv -c http://pool.mirror.archlinux32.org/pentium4/extra/libsoxr-0.1.3-1.1-pentium4.pkg.tar.xz -P ./cache/
wget -nv -c http://pool.mirror.archlinux32.org/pentium4/extra/libssh-0.9.3-1.0-pentium4.pkg.tar.xz -P ./cache/
wget -nv -c http://pool.mirror.archlinux32.org/pentium4/extra/vid.stab-1.1-2.4-pentium4.pkg.tar.xz -P ./cache/
wget -nv -c http://pool.mirror.archlinux32.org/pentium4/extra/l-smash-2.14.5-1.4-pentium4.pkg.tar.xz -P ./cache/
wget -nv -c http://pool.mirror.archlinux32.org/pentium4/staging/x264-3:0.157.r2980.34c06d1-2.2-pentium4.pkg.tar.xz -P ./cache/
wget -nv -c http://pool.mirror.archlinux32.org/pentium4/extra/x265-3.2.1-1.0-pentium4.pkg.tar.xz -P ./cache/
wget -nv -c http://pool.mirror.archlinux32.org/pentium4/extra/xvidcore-1.3.6-1.0-pentium4.pkg.tar.xz -P ./cache/
wget -nv -c http://pool.mirror.archlinux32.org/pentium4/extra/opencore-amr-0.1.5-3.0-pentium4.pkg.tar.xz -P ./cache/
wget -nv -c http://pool.mirror.archlinux32.org/pentium4/extra/openjpeg2-2.3.1-1.0-pentium4.pkg.tar.xz -P ./cache/

# Add the archlinux32 pentium4 packages (smbclient and deps):
wget -nv -c http://pool.mirror.archlinux32.org/pentium4/extra/libwbclient-4.10.10-2.0-pentium4.pkg.tar.xz -P ./cache/
wget -nv -c http://pool.mirror.archlinux32.org/pentium4/core/libtirpc-1.2.5-1.0-pentium4.pkg.tar.xz -P ./cache/
# FIXME: tevent have incomplete python deps
wget -nv -c http://pool.mirror.archlinux32.org/pentium4/extra/tevent-1:0.9.39-4.1-pentium4.pkg.tar.xz -P ./cache/
# FIXME: talloc have incomplete python deps
wget -nv -c http://pool.mirror.archlinux32.org/pentium4/extra/talloc-2.3.1-1.0-pentium4.pkg.tar.xz -P ./cache/
# FIXME: ldb incomplete deps
wget -nv -c http://pool.mirror.archlinux32.org/pentium4/extra/ldb-1:1.5.6-2.1-pentium4.pkg.tar.xz -P ./cache/
wget -nv -c http://pool.mirror.archlinux32.org/pentium4/extra/libbsd-0.10.0-1.0-pentium4.pkg.tar.xz -P ./cache/
# FIXME: avahi incomplete deps
wget -nv -c http://pool.mirror.archlinux32.org/pentium4/extra/avahi-0.7+18+g1b5f401-3.1-pentium4.pkg.tar.xz -P ./cache/
wget -nv -c http://pool.mirror.archlinux32.org/pentium4/testing/libarchive-3.4.0-3.0-pentium4.pkg.tar.xz -P ./cache/
wget -nv -c http://pool.mirror.archlinux32.org/pentium4/extra/smbclient-4.10.10-2.0-pentium4.pkg.tar.xz -P ./cache/

# FIXME: "wine --check-libs" have:
#libcapi20.so.3: missing (from isdn4k-utils)
#libodbc.so.2: missing (from unixodbc)
#libsane.so.1: missing (from sane: bigger package just for scanning paper)
#libncurses.so.5: missing (testing)
#libnetapi.so: missing (the lib is there, but missing!?)

# extracting *tar.xz...
find ./cache -name '*tar.xz' -exec tar --warning=no-unknown-keyword -xJf {} \;

# extracting *tar.zst...
find ./cache -name '*tar.zst' -exec tar --warning=no-unknown-keyword --zstd -xf {} \;

# wineworkdir cleanup
rm -rf cache; rm -rf include; rm usr/lib32/{*.a,*.o}; rm -rf usr/lib32/pkgconfig; rm -rf share/man; rm -rf usr/include; rm -rf usr/share/{applications,doc,emacs,gtk-doc,java,licenses,man,info,pkgconfig}; rm usr/lib32/locale
rm -rf boot; rm -rf dev; rm -rf home; rm -rf mnt; rm -rf opt; rm -rf proc; rm -rf root; rm sbin; rm -rf srv; rm -rf sys; rm -rf tmp; rm -rf var
rm -rf usr/src; rm -rf usr/share; rm usr/sbin; rm -rf usr/local; rm usr/lib/{*.a,*.o}

#removing libLLVM for size (needed only for opencl and some vulkan drivers):
rm -rf usr/lib32/libLLVM*
rm -rf usr/lib32/libLTO.so*
rm -rf usr/lib32/LLVMgold.so
rm -rf usr/lib32/bfd-plugins/LLVMgold.so

#===========================================================================================
# fix broken link libglx_indirect and others
rm usr/lib32/libGLX_indirect.so.0
ln -s libGLX_mesa.so.0 libGLX_indirect.so.0
mv libGLX_indirect.so.0 usr/lib32

rm usr/lib/libGLX_indirect.so.0
ln -s ../lib32/libGLX_mesa.so.0 libGLX_indirect.so.0
mv libGLX_indirect.so.0 usr/lib
#--------

rm usr/lib32/libkeyutils.so
ln -s libkeyutils.so.1 libkeyutils.so
mv libkeyutils.so usr/lib32

rm usr/lib/libkeyutils.so
ln -s ../lib32/libkeyutils.so.1 libkeyutils.so
mv libkeyutils.so usr/lib
#--------

# workaround some of "wine --check-libs" wrong versions
ln -s libncursesw.so libncursesw.so.5
mv libncursesw.so.5 usr/lib32

ln -s libpcap.so libpcap.so.0.8
mv libpcap.so.0.8 usr/lib32

ln -s libva.so libva.so.1
ln -s libva-drm.so libva-drm.so.1
ln -s libva-x11.so libva-x11.so.1
mv libva.so.1 usr/lib32
mv libva-drm.so.1 usr/lib32
mv libva-x11.so.1 usr/lib32
#===========================================================================================
# Disable PulseAudio
rm etc/asound.conf; rm -rf etc/modprobe.d/alsa.conf; rm -rf etc/pulse

# Disable winemenubuilder
sed -i 's/winemenubuilder.exe -a -r/winemenubuilder.exe -r/g' share/wine/wine.inf

# Disable FileOpenAssociations
sed -i 's|    LicenseInformation|    LicenseInformation,\\\n    FileOpenAssociations|g;$a \\n[FileOpenAssociations]\nHKCU,Software\\Wine\\FileOpenAssociations,"Enable",,"N"' share/wine/wine.inf

#===========================================================================================
# appimage
cd ..

wget -nv -c "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage" -O  appimagetool.AppImage
chmod +x appimagetool.AppImage

chmod +x AppRun

cp src/{libhookexecv.so,wine-preloader_hook} $wineworkdir/bin
rm src/{libhookexecv.so,wine-preloader_hook}

cp AppRun $wineworkdir
cp resource/* $wineworkdir

./appimagetool.AppImage --appimage-extract

export ARCH=x86_64; squashfs-root/AppRun -v $wineworkdir -u 'gh-releases-zsync|ferion11|Wine_Appimage|continuous|wine-i386*arch*.AppImage.zsync' wine-i386_${ARCH}-archlinux.AppImage
