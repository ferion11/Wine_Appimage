#!/bin/bash
WINE_WORKDIR="wineversion"
PKG_WORKDIR="pkg_work"

#=========================
die() { echo >&2 "$*"; exit 1; };

 get_archlinux32_pkg() {
	#WARNING: Only work on well formatted html
	#usage:  get_archlinux32_pkg [link] [dest]
	# get_archlinux32_pkg http://pool.mirror.archlinux32.org/pentium4/extra/aom-1.0.0.errata1-1.2-pentium4.pkg.tar.xz ./cache/
	# get_archlinux32_pkg https://www.archlinux32.org/packages/pentium4/extra/xvidcore/ ./cache/
	
	REAL_LINK=""
	PAR_PKG_LINK=$(echo $1 | grep "pkg.tar")
	
	if [ -n "$PAR_PKG_LINK" ]; then
		REAL_LINK="$PAR_PKG_LINK"
	else
		rm -rf tmp_file_html
		wget -nv -c $1 -O tmp_file_html
		REAL_LINK=$(grep "pkg.tar" tmp_file_html | grep --invert-match ".sig" | sed -n 's/.*href="\([^"]*\).*/\1/p')
		rm -rf tmp_file_html
		
		if [ -z "$REAL_LINK" ]; then
			die "* ERROR get_archlinux32_pkg: Fail to download: $1"
		fi
	fi
	
	wget -nv -c $REAL_LINK -P $2
}

get_archlinux32_pkgs() {
	#Usage: get_archlinux32_pkgs [dest] pack1 pack2...
	#https://mirror.datacenter.by/pub/archlinux32/$arch/$repo/"
	
	rm -rf tmp_pentium4_core_html
	rm -rf tmp_pentium4_core_html
	wget -nv -c https://mirror.datacenter.by/pub/archlinux32/pentium4/core/ -O tmp_pentium4_core_html
	wget -nv -c https://mirror.datacenter.by/pub/archlinux32/pentium4/extra/ -O tmp_pentium4_extra_html
	
	for current_pkg in "${@:2}"
	do
		PKG_NAME_CORE=$(grep "$current_pkg-[0-9]" tmp_pentium4_core_html | grep --invert-match ".sig" | sed -n 's/.*href="\([^"]*\).*/\1/p' | grep "^$current_pkg")
		
		if [ -n "$PKG_NAME_CORE" ]; then
			#echo "CORE: Downloading $current_pkg in $1 : $PKG_NAME_CORE"
			#echo "http://pool.mirror.archlinux32.org/pentium4/core/$PKG_NAME_CORE"
			get_archlinux32_pkg "http://pool.mirror.archlinux32.org/pentium4/core/$PKG_NAME_CORE" $1
		else
			PKG_NAME_EXTRA=$(grep "$current_pkg-[0-9]" tmp_pentium4_extra_html | grep --invert-match ".sig" | sed -n 's/.*href="\([^"]*\).*/\1/p' | grep "^$current_pkg")
			
			if [ -n "$PKG_NAME_EXTRA" ]; then
				#echo "EXTRA: Downloading $current_pkg in $1 : $PKG_NAME_EXTRA"
				#echo "http://pool.mirror.archlinux32.org/pentium4/extra/$PKG_NAME_EXTRA"
				get_archlinux32_pkg "http://pool.mirror.archlinux32.org/pentium4/extra/$PKG_NAME_EXTRA" $1
			else
				die "ERROR get_archlinux32_pkgs: Package don't found: $current_pkg"
			fi
		fi
	done
	
	rm -rf tmp_pentium4_core_html
	rm -rf tmp_pentium4_extra_html
}
#=========================

#Initializing the keyring requires entropy
pacman-key --init

# Enable Multilib
sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf

# Add more repo:
echo "" >> /etc/pacman.conf

# https://github.com/archlinuxcn/repo
echo "[archlinuxcn]" >> /etc/pacman.conf
echo "SigLevel = Optional TrustAll" >> /etc/pacman.conf
echo "Server = https://repo.archlinuxcn.org/\$arch" >> /etc/pacman.conf
echo "" >> /etc/pacman.conf

# https://lonewolf.pedrohlc.com/chaotic-aur/
echo "[chaotic-aur]" >> /etc/pacman.conf
echo "SigLevel = Optional TrustAll" >> /etc/pacman.conf
echo "Server = http://lonewolf-builder.duckdns.org/\$repo/x86_64" >> /etc/pacman.conf
echo "Server = http://chaotic.bangl.de/\$repo/x86_64" >> /etc/pacman.conf
echo "Server = https://repo.kitsuna.net/x86_64" >> /etc/pacman.conf
echo "" >> /etc/pacman.conf
#pacman-key --keyserver keys.mozilla.org -r 3056513887B78AEB
#pacman-key --lsign-key 3056513887B78AEB

pacman -Syy && pacman -S archlinuxcn-keyring

pacman -Syy
#Add "base-devel multilib-devel" for compile in the list:
pacman -S --noconfirm wget base-devel multilib-devel pacman-contrib git tar grep sed zstd xz
#===========================================================================================

mkdir "$WINE_WORKDIR"
mkdir "$PKG_WORKDIR"

#----------- AUR ----------------
#Delete a nobody's password (make it empty):
passwd -d nobody

# Allow the nobody passwordless sudo:
printf 'nobody ALL=(ALL) ALL\n' | tee -a /etc/sudoers

# change workind dir to nobody own:
chown nobody.nobody "$PKG_WORKDIR"
#------------

# INFO: https://wiki.archlinux.org/index.php/Makepkg
cd "$PKG_WORKDIR" || die "ERROR: Directory don't exist: $PKG_WORKDIR"
#------------

## lib32-isdn4k-utils  https://aur.archlinux.org/packages/lib32-isdn4k-utils
#sudo -u nobody git clone https://aur.archlinux.org/lib32-isdn4k-utils.git
#cd lib32-isdn4k-utils
#sudo -u nobody makepkg --syncdeps --noconfirm
#echo "* All files HERE: $(ls ./)"
#mv *.pkg.tar* ../ || die "ERROR: Can't create the lib32-isdn4k-utils package"
#cd ..
#------------

mv *.pkg.tar* ../"$WINE_WORKDIR" || echo "ERROR: None package builded from AUR"

cd ..
rm -rf "$PKG_WORKDIR"
#-----------------------------------

# Get Wine
#wget -nv -c https://www.playonlinux.com/wine/binaries/phoenicis/upstream-linux-x86/PlayOnLinux-wine-4.10-upstream-linux-x86.tar.gz
#wget -nv -c https://www.playonlinux.com/wine/binaries/phoenicis/upstream-linux-x86/PlayOnLinux-wine-4.21-upstream-linux-x86.tar.gz
wget -nv -c https://www.playonlinux.com/wine/binaries/phoenicis/staging-linux-x86/PlayOnLinux-wine-4.21-staging-linux-x86.tar.gz
tar xf PlayOnLinux-wine-* -C "$WINE_WORKDIR"/

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

cd "$WINE_WORKDIR" || die "ERROR: Directory don't exist: $WINE_WORKDIR"

# Add a dependency library, such as freetype font library
dependencys=$(pactree -s -u wine |grep lib32 | xargs)

mkdir cache
mv *.pkg.tar* ./cache/ || echo "ERROR: None package builded from AUR"

pacman -Scc --noconfirm
pacman -Syw --noconfirm --cachedir cache lib32-alsa-lib lib32-alsa-plugins lib32-faudio lib32-fontconfig lib32-freetype2 lib32-gcc-libs lib32-gettext lib32-giflib lib32-glu lib32-gnutls lib32-gst-plugins-base lib32-lcms2 lib32-libjpeg-turbo lib32-libjpeg6-turbo lib32-libldap lib32-libpcap lib32-libpng lib32-libpng12 lib32-libsm lib32-libxcomposite lib32-libxcursor lib32-libxdamage lib32-libxi lib32-libxml2 lib32-libxmu lib32-libxrandr lib32-libxslt lib32-libxxf86vm lib32-mesa lib32-mesa-libgl lib32-mpg123 lib32-ncurses lib32-openal lib32-sdl2 lib32-v4l-utils lib32-libdrm lib32-libva lib32-krb5 lib32-flac lib32-gst-plugins-good lib32-libcups lib32-libwebp lib32-libvpx lib32-libvpx1.3 lib32-portaudio lib32-sdl lib32-sdl2_image lib32-sdl2_mixer lib32-sdl2_ttf lib32-sdl_image lib32-sdl_mixer lib32-sdl_ttf lib32-smpeg lib32-speex lib32-speexdsp lib32-twolame lib32-virtualgl lib32-ladspa lib32-libao lib32-soundtouch lib32-libxvmc lib32-libvdpau lib32-libpulse lib32-libcanberra-pulse lib32-libcanberra-gstreamer lib32-glew lib32-mesa-demos lib32-jansson lib32-libxinerama lib32-atk lib32-at-spi2-atk lib32-colord lib32-json-glib lib32-libepoxy lib32-librsvg lib32-libxkbcommon lib32-rest lib32-gtk3 lib32-vulkan-icd-loader lib32-vulkan-intel lib32-vulkan-radeon lib32-vkd3d lib32-aom lib32-gsm lib32-lame lib32-libass lib32-libbluray lib32-dav1d lib32-libomxil-bellagio lib32-x264 lib32-x265 lib32-xvidcore lib32-opencore-amr lib32-openjpeg2 lib32-ncurses5-compat-libs $dependencys || die "ERROR: Some packages not found!!!"
#*don't have package (using the archlinux32 packages below): lib32-ffmpeg lib32-gst-libav (smbclient and deps too)
# removed for smaller size because wine don't need: lib32-gtk2 lib32-wxgtk2

# Remove non lib32 pkgs before extracting
#echo "All files in ./cache: $(ls ./cache)"
find ./cache -type f ! -name "lib32*" -exec rm {} \; -exec echo "Removing: {}" \;
#find ./cache -type f -name "*x86_64*" -exec rm {} \; -exec echo "Removing: {}" \; #don't work because the name of lib32 multilib packages have the x86_64 too
echo "All files in ./cache: $(ls ./cache)"

# Add the archlinux32 pentium4 packages (lib32-ffmpeg lib32-gst-libav and deps):
# Add the archlinux32 pentium4 packages (smbclient and deps):
# FIXME: tevent have incomplete python deps
# FIXME: talloc have incomplete python deps
# FIXME: ldb incomplete deps
# FIXME: avahi incomplete deps
#ORIGINAL: get_archlinux32_pkgs ./cache/ gst-libav ffmpeg aom gsm lame libass libbluray dav1d libomxil-bellagio libsoxr libssh vid.stab l-smash x264 x265 xvidcore opencore-amr openjpeg2 libwbclient libtirpc tevent talloc ldb libbsd avahi libarchive smbclient
# Can't get from arch64_lib32_plus_user_repo: lib32-ffmpeg lib32-gst-libav lib32-libwbclient lib32-tevent lib32-talloc lib32-ldb lib32-libbsd lib32-avahi lib32-libarchive lib32-smbclient
# removed smbclient and libwbclient smbclient (the .so file isn't loading on wine)
get_archlinux32_pkgs ./cache/ ffmpeg gst-libav tevent talloc ldb libbsd avahi libarchive libsoxr libssh vid.stab l-smash libtirpc

# FIXME: "wine --check-libs" have:
#libcapi20.so.3: missing (from isdn4k-utils trying now from aur)
#libodbc.so.2: missing (removed because, if the lib is there, in unixodbc, then missing!?)
#libsane.so.1: missing (from sane: bigger package just for scanning paper)
#libnetapi.so: missing (removed because, if the lib is there, in smbclient, then missing!?)

# extracting *tar.xz...
find ./cache -name '*tar.xz' -exec tar --warning=no-unknown-keyword -xJf {} \;

# extracting *tar.zst...
find ./cache -name '*tar.zst' -exec tar --warning=no-unknown-keyword --zstd -xf {} \;

# Install vulkan tools:
wget -nv -c https://github.com/ferion11/libsutil/releases/download/vulkan32_tools_v1.0/vkcube32
wget -nv -c https://github.com/ferion11/libsutil/releases/download/vulkan32_tools_v1.0/vkcubepp32
wget -nv -c https://github.com/ferion11/libsutil/releases/download/vulkan32_tools_v1.0/vulkaninfo32
chmod +x vkcube32 vkcubepp32 vulkaninfo32
mv -n vkcube32 usr/bin
mv -n vkcubepp32 usr/bin
mv -n vulkaninfo32 usr/bin
#----------------------------------------------

# WINE_WORKDIR cleanup
rm -rf cache; rm -rf include; rm usr/lib32/{*.a,*.o}; rm -rf usr/lib32/pkgconfig; rm -rf share/man; rm -rf usr/include; rm -rf usr/share/{applications,doc,emacs,gtk-doc,java,licenses,man,info,pkgconfig}; rm usr/lib32/locale
rm -rf boot; rm -rf dev; rm -rf home; rm -rf mnt; rm -rf opt; rm -rf proc; rm -rf root; rm sbin; rm -rf srv; rm -rf sys; rm -rf tmp; rm -rf var
rm -rf usr/src; rm -rf usr/share; rm usr/sbin; rm -rf usr/local; rm usr/lib/{*.a,*.o}
#===========================================================================================

# fix broken link libglx_indirect and others
rm usr/lib32/libGLX_indirect.so.0
ln -s libGLX_mesa.so.0 libGLX_indirect.so.0
mv -n libGLX_indirect.so.0 usr/lib32

rm usr/lib/libGLX_indirect.so.0
ln -s ../lib32/libGLX_mesa.so.0 libGLX_indirect.so.0
mv -n libGLX_indirect.so.0 usr/lib
#--------

rm usr/lib32/libkeyutils.so
ln -s libkeyutils.so.1 libkeyutils.so
mv -n libkeyutils.so usr/lib32

rm usr/lib/libkeyutils.so
ln -s ../lib32/libkeyutils.so.1 libkeyutils.so
mv -n libkeyutils.so usr/lib
#--------

# workaround some of "wine --check-libs" wrong versions
ln -s libpcap.so libpcap.so.0.8
mv -n libpcap.so.0.8 usr/lib32

ln -s libva.so libva.so.1
ln -s libva-drm.so libva-drm.so.1
ln -s libva-x11.so libva-x11.so.1
mv -n libva.so.1 usr/lib32
mv -n libva-drm.so.1 usr/lib32
mv -n libva-x11.so.1 usr/lib32

# gst-libav link
ln -s ../../lib/gstreamer-1.0/libgstlibav.so libgstlibav.so
mv libgstlibav.so usr/lib32/gstreamer-1.0/
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

cp src/{libhookexecv.so,wine-preloader_hook} $WINE_WORKDIR/bin
rm src/{libhookexecv.so,wine-preloader_hook}

cp AppRun $WINE_WORKDIR
cp resource/* $WINE_WORKDIR

./appimagetool.AppImage --appimage-extract

export ARCH=x86_64; squashfs-root/AppRun -v $WINE_WORKDIR -u 'gh-releases-zsync|ferion11|Wine_Appimage|continuous|wine-i386*arch*.AppImage.zsync' wine-i386_${ARCH}-archlinux.AppImage
