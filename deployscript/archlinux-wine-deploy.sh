#!/bin/bash
# Enable Multilib
sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf

pacman -Syy
#pacman -S --noconfirm wget file pacman-contrib tar grep gcc lib32-gcc-libs
pacman -S --noconfirm wget file pacman-contrib tar grep

#===========================================================================================
# Get Wine
#wget -nv -c https://www.playonlinux.com/wine/binaries/phoenicis/upstream-linux-x86/PlayOnLinux-wine-4.10-upstream-linux-x86.tar.gz
#wget -nv -c https://www.playonlinux.com/wine/binaries/phoenicis/upstream-linux-x86/PlayOnLinux-wine-4.21-upstream-linux-x86.tar.gz
wget -nv -c https://www.playonlinux.com/wine/binaries/phoenicis/staging-linux-x86/PlayOnLinux-wine-4.21-staging-linux-x86.tar.gz
mkdir wineversion
tar xf PlayOnLinux-wine-* -C wineversion/

wget -nv -c https://github.com/Hackerl/Wine_Appimage/releases/download/v0.9/libhookexecv.so
wget -nv -c https://github.com/Hackerl/Wine_Appimage/releases/download/v0.9/wine-preloader_hook
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
pacman -Syw --noconfirm --cachedir cache lib32-alsa-lib lib32-alsa-plugins lib32-faudio lib32-fontconfig lib32-freetype2 lib32-gcc-libs lib32-gettext lib32-giflib lib32-glu lib32-gnutls lib32-gst-plugins-base lib32-lcms2 lib32-libjpeg-turbo lib32-libjpeg6-turbo lib32-libldap lib32-libpcap lib32-libpng lib32-libpng12 lib32-libsm lib32-libxcomposite lib32-libxcursor lib32-libxdamage lib32-libxi lib32-libxml2 lib32-libxmu lib32-libxrandr lib32-libxslt lib32-libxxf86vm lib32-mesa lib32-mesa-libgl lib32-mpg123 lib32-ncurses lib32-openal lib32-sdl2 lib32-v4l-utils lib32-libdrm lib32-libva lib32-krb5 lib32-flac lib32-gst-plugins-good lib32-libcups lib32-libwebp lib32-libvpx lib32-libvpx1.3 lib32-portaudio lib32-sdl lib32-sdl2_image lib32-sdl2_mixer lib32-sdl2_ttf lib32-sdl_image lib32-sdl_mixer lib32-sdl_ttf lib32-smpeg lib32-speex lib32-speexdsp lib32-twolame lib32-virtualgl lib32-ladspa lib32-libao lib32-soundtouch lib32-libxvmc lib32-vulkan-icd-loader lib32-vulkan-intel lib32-libvdpau $dependencys
#*don't have package (using the archlinux32 packages below): lib32-ffmpeg lib32-gst-libav

# Remove non lib32 pkgs before extracting
find ./cache -type f ! -name "lib32*" -exec rm {} \;

# Add the archlinux32 pentium4 packages (lib32-ffmpeg lib32-gst-libav and deps):
wget -c http://pool.mirror.archlinux32.org/pentium4/extra/gst-libav-1.16.2-1.0-pentium4.pkg.tar.xz -P ./cache/
wget -c http://pool.mirror.archlinux32.org/pentium4/staging/ffmpeg-1:4.2.1-4.5-pentium4.pkg.tar.xz -P ./cache/
wget -c http://pool.mirror.archlinux32.org/pentium4/extra/aom-1.0.0.errata1-1.2-pentium4.pkg.tar.xz -P ./cache/
wget -c http://pool.mirror.archlinux32.org/pentium4/extra/gsm-1.0.18-1.4-pentium4.pkg.tar.xz -P ./cache/
wget -c http://pool.mirror.archlinux32.org/pentium4/extra/lame-3.100-2.1-pentium4.pkg.tar.xz -P ./cache/
wget -c http://pool.mirror.archlinux32.org/pentium4/staging/libass-0.14.0-1.10-pentium4.pkg.tar.xz -P ./cache/
wget -c http://pool.mirror.archlinux32.org/pentium4/staging/libbluray-1.1.2-1.7-pentium4.pkg.tar.xz -P ./cache/
wget -c http://pool.mirror.archlinux32.org/pentium4/extra/dav1d-0.5.2-1.0-pentium4.pkg.tar.xz -P ./cache/
wget -c http://pool.mirror.archlinux32.org/pentium4/extra/libomxil-bellagio-0.9.3-2.4-pentium4.pkg.tar.xz -P ./cache/
wget -c http://pool.mirror.archlinux32.org/pentium4/extra/libsoxr-0.1.3-1.1-pentium4.pkg.tar.xz -P ./cache/
wget -c http://pool.mirror.archlinux32.org/pentium4/extra/libssh-0.9.3-1.0-pentium4.pkg.tar.xz -P ./cache/
wget -c http://pool.mirror.archlinux32.org/pentium4/extra/vid.stab-1.1-2.4-pentium4.pkg.tar.xz -P ./cache/
wget -c http://pool.mirror.archlinux32.org/pentium4/extra/l-smash-2.14.5-1.4-pentium4.pkg.tar.xz -P ./cache/
wget -c http://pool.mirror.archlinux32.org/pentium4/staging/x264-3:0.157.r2980.34c06d1-2.2-pentium4.pkg.tar.xz -P ./cache/
wget -c http://pool.mirror.archlinux32.org/pentium4/extra/x265-3.2.1-1.0-pentium4.pkg.tar.xz -P ./cache/
wget -c http://pool.mirror.archlinux32.org/pentium4/extra/xvidcore-1.3.6-1.0-pentium4.pkg.tar.xz -P ./cache/
wget -c http://pool.mirror.archlinux32.org/pentium4/extra/opencore-amr-0.1.5-3.0-pentium4.pkg.tar.xz -P ./cache/
wget -c http://pool.mirror.archlinux32.org/pentium4/extra/openjpeg2-2.3.1-1.0-pentium4.pkg.tar.xz -P ./cache/

# extracting...
find ./cache -name '*tar.xz' -exec tar --warning=no-unknown-keyword -xJf {} \;


# wineworkdir cleanup
rm -rf cache; rm -rf include; rm usr/lib32/{*.a,*.o}; rm -rf usr/lib32/pkgconfig; rm -rf share/man; rm -rf usr/include; rm -rf usr/share/{applications,doc,emacs,gtk-doc,java,licenses,man,info,pkgconfig}; rm usr/lib32/locale
rm -rf boot; rm -rf dev; rm -rf home; rm -rf mnt; rm -rf opt; rm -rf proc; rm -rf root; rm sbin; rm -rf srv; rm -rf sys; rm -rf tmp; rm -rf var
rm -rf usr/src; rm -rf usr/share; rm usr/sbin; rm -rf usr/local; rm usr/lib/{*.a,*.o}

#===========================================================================================
# fix broken link libglx_indirect and others
rm usr/lib32/libGLX_indirect.so.0
ln -s libGLX_mesa.so.0 libGLX_indirect.so.0
mv libGLX_indirect.so.0 usr/lib32

rm usr/lib/libGLX_indirect.so.0
ln -s libGLX_mesa.so.0 libGLX_indirect.so.0
mv libGLX_indirect.so.0 usr/lib

rm usr/lib/libkeyutils.so
ln -s libkeyutils.so.1 libkeyutils.so
mv libkeyutils.so usr/lib

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
