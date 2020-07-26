#!/bin/bash
P_URL="https://www.playonlinux.com/wine/binaries/phoenicis/staging-linux-x86/PlayOnLinux-wine-5.13-staging-linux-x86.tar.gz"
P_NAME=$(echo $P_URL | cut -d/ -f4)
P_MVERSION=$(echo $P_URL | cut -d/ -f7)
P_FILENAME=$(echo $P_URL | cut -d/ -f8)
P_CSOURCE=$(echo $P_FILENAME | cut -d- -f1)
P_VERSION=$(echo $P_FILENAME | cut -d- -f3)
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
	rm -rf tmp_pentium4_extra_html
	rm -rf tmp_pentium4_community_html
	wget -nv -c https://mirror.datacenter.by/pub/archlinux32/pentium4/core/ -O tmp_pentium4_core_html
	wget -nv -c https://mirror.datacenter.by/pub/archlinux32/pentium4/extra/ -O tmp_pentium4_extra_html
	wget -nv -c https://mirror.datacenter.by/pub/archlinux32/pentium4/community/ -O tmp_pentium4_community_html
	
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
				PKG_NAME_COMMUNITY=$(grep "$current_pkg-[0-9]" tmp_pentium4_community_html | grep --invert-match ".sig" | sed -n 's/.*href="\([^"]*\).*/\1/p' | grep "^$current_pkg")
				
				if [ -n "$PKG_NAME_COMMUNITY" ]; then
					#echo "COMMUNITY: Downloading $current_pkg in $1 : $PKG_NAME_COMMUNITY"
					#echo "http://pool.mirror.archlinux32.org/pentium4/community/$PKG_NAME_COMMUNITY"
					get_archlinux32_pkg "http://pool.mirror.archlinux32.org/pentium4/community/$PKG_NAME_COMMUNITY" $1
				else
					die "ERROR get_archlinux32_pkgs: Package don't found: $current_pkg"
				fi
			fi
		fi
	done
	
	rm -rf tmp_pentium4_core_html
	rm -rf tmp_pentium4_extra_html
	rm -rf tmp_pentium4_community_html
}
#=========================

#Initializing the keyring requires entropy
pacman-key --init

# Enable Multilib
sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf

# Configure for compilation:
#sed -i '/^BUILDENV/s/\!ccache/ccache/' /etc/makepkg.conf
sed -i '/#MAKEFLAGS=/c MAKEFLAGS="-j2"' /etc/makepkg.conf
#sed -i '/^COMPRESSXZ/s/\xz/xz -T 2/' /etc/makepkg.conf
#sed -i "s/^PKGEXT='.pkg.tar.gz'/PKGEXT='.pkg.tar.xz'/" /etc/makepkg.conf
#sed -i '$a   CFLAGS="$CFLAGS -w"'   /etc/makepkg.conf
#sed -i '$a CXXFLAGS="$CXXFLAGS -w"' /etc/makepkg.conf
sed -i 's/^CFLAGS\s*=.*/CFLAGS="-mtune=nehalem -O2 -pipe -ftree-vectorize -fno-stack-protector"/' /etc/makepkg.conf
sed -i 's/^CXXFLAGS\s*=.*/CXXFLAGS="-mtune=nehalem -O2 -pipe -ftree-vectorize -fno-stack-protector"/' /etc/makepkg.conf
#sed -i 's/^LDFLAGS\s*=.*/LDFLAGS="-Wl,-O1,--sort-common,--as-needed,-z,relro,-z,now"/' /etc/makepkg.conf
sed -i 's/^#PACKAGER\s*=.*/PACKAGER="DanielDevBR"/' /etc/makepkg.conf
sed -i 's/^PKGEXT\s*=.*/PKGEXT=".pkg.tar"/' /etc/makepkg.conf
sed -i 's/^SRCEXT\s*=.*/SRCEXT=".src.tar"/' /etc/makepkg.conf

# Add more repo:
echo "" >> /etc/pacman.conf

# https://github.com/archlinuxcn/repo
echo "[archlinuxcn]" >> /etc/pacman.conf
#echo "SigLevel = Optional TrustAll" >> /etc/pacman.conf
echo "SigLevel = Never" >> /etc/pacman.conf
echo "Server = https://repo.archlinuxcn.org/\$arch" >> /etc/pacman.conf
echo "" >> /etc/pacman.conf

# https://lonewolf.pedrohlc.com/chaotic-aur/
echo "[chaotic-aur]" >> /etc/pacman.conf
#echo "SigLevel = Optional TrustAll" >> /etc/pacman.conf
echo "SigLevel = Never" >> /etc/pacman.conf
echo "Server = http://lonewolf-builder.duckdns.org/\$repo/x86_64" >> /etc/pacman.conf
echo "Server = http://chaotic.bangl.de/\$repo/x86_64" >> /etc/pacman.conf
echo "Server = https://repo.kitsuna.net/x86_64" >> /etc/pacman.conf
echo "" >> /etc/pacman.conf
#pacman-key --keyserver keys.mozilla.org -r 3056513887B78AEB
#pacman-key --lsign-key 3056513887B78AEB
#sudo pacman-key --keyserver hkp://p80.pool.sks-keyservers.net:80 -r 3056513887B78AEB
#sudo pacman-key --lsign-key 3056513887B78AEB

# workaround one bug: https://bugzilla.redhat.com/show_bug.cgi?id=1773148
echo "Set disable_coredump false" >> /etc/sudo.conf

echo "DEBUG: updating pacmam keys"
pacman -Syy --noconfirm && pacman --noconfirm -S archlinuxcn-keyring

echo "DEBUG: pacmam sync"
pacman -Syy --noconfirm

echo "DEBUG: pacmam updating system"
pacman -Syu --noconfirm

#Add "base-devel multilib-devel" for compile in the list:
pacman -S --noconfirm wget base-devel multilib-devel pacman-contrib git tar grep sed zstd xz bzip2
#===========================================================================================

mkdir "$WINE_WORKDIR"
mkdir "$PKG_WORKDIR"

#----------- AUR ----------------
##Delete a nobody's password (make it empty):
#passwd -d nobody

## Allow the nobody passwordless sudo:
#printf 'nobody ALL=(ALL) ALL\n' | tee -a /etc/sudoers

## change workind dir to nobody own:
#chown nobody.nobody "$PKG_WORKDIR"

#alias makepkg="sudo -u nobody makepkg"

# pacthing makepkg instead of using nobody user (root error will be on the EUID=9875):
#sed -i 's/EUID == 0/EUID == 9875/g' /usr/bin/makepkg
#------------

#FIXME: HAVE_SECURE_MKSTEMP on fakeroot
#chmod 777 /tmp

# INFO: https://wiki.archlinux.org/index.php/Makepkg
cd "$PKG_WORKDIR" || die "ERROR: Directory don't exist: $PKG_WORKDIR"
#------------

## lib32-gst-libav https://aur.archlinux.org/packages/lib32-gst-libav/
#git clone https://aur.archlinux.org/lib32-gst-libav.git
#cd lib32-gst-libav
#makepkg --syncdeps --noconfirm
#pacman --noconfirm -U ./*.pkg.tar*
#echo "* All files HERE: $(ls ./)"
#mv *.pkg.tar* ../ || die "ERROR: Can't create the lib32-gst-libav package"
#cd ..
#------------

#mv *.pkg.tar* ../"$WINE_WORKDIR" || die "ERROR: None package builded from AUR"
mv *.pkg.tar* ../"$WINE_WORKDIR" || echo "INFO: None package builded from AUR"

cd ..
rm -rf "$PKG_WORKDIR"
#-----------------------------------

# Get Wine
wget -nv -c $P_URL
tar xf $P_FILENAME -C "$WINE_WORKDIR"/

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
#mv *.pkg.tar* ./cache/ || die "ERROR: None package builded from AUR"
mv *.pkg.tar* ./cache/ || echo "INFO: None package builded from AUR"

pacman -Scc --noconfirm
pacman -Syw --noconfirm --cachedir cache lib32-alsa-lib lib32-alsa-plugins lib32-speex lib32-speexdsp lib32-faudio lib32-fontconfig lib32-freetype2 lib32-gcc-libs lib32-gettext lib32-giflib lib32-glu lib32-gnutls lib32-gst-plugins-base lib32-lcms2 lib32-libjpeg-turbo lib32-libjpeg6-turbo lib32-libldap lib32-libpcap lib32-libpng lib32-libpng12 lib32-libsm lib32-libxcomposite lib32-libxcursor lib32-libxdamage lib32-libxi lib32-libxml2 lib32-libxmu lib32-libxrandr lib32-libxslt lib32-libxxf86vm lib32-mesa lib32-mesa-libgl lib32-mpg123 lib32-ncurses lib32-openal lib32-sdl2 lib32-v4l-utils lib32-libdrm lib32-libva lib32-krb5 lib32-flac lib32-gst-plugins-good lib32-libcups lib32-libwebp lib32-libvpx lib32-libvpx1.3 lib32-portaudio lib32-sdl lib32-sdl2_image lib32-sdl2_mixer lib32-sdl2_ttf lib32-sdl_image lib32-sdl_mixer lib32-sdl_ttf lib32-smpeg lib32-speex lib32-speexdsp lib32-twolame lib32-ladspa lib32-libao lib32-libvdpau lib32-libpulse lib32-libcanberra-pulse lib32-libcanberra-gstreamer lib32-glew lib32-mesa-demos lib32-jansson lib32-libxinerama lib32-atk lib32-vulkan-icd-loader lib32-vulkan-intel lib32-vulkan-radeon lib32-vkd3d lib32-aom lib32-gsm lib32-lame lib32-libass lib32-libbluray lib32-dav1d lib32-libomxil-bellagio lib32-x264 lib32-x265 lib32-xvidcore lib32-opencore-amr lib32-openjpeg2 lib32-ncurses5-compat-libs lib32-ffmpeg $dependencys || die "ERROR: Some packages not found!!!"

# Remove non lib32 pkgs before extracting
#echo "All files in ./cache: $(ls ./cache)"
find ./cache -type f ! -name "lib32*" -exec rm {} \; -exec echo "Removing: {}" \;
#find ./cache -type f -name "*x86_64*" -exec rm {} \; -exec echo "Removing: {}" \; #don't work because the name of lib32 multilib packages have the x86_64 too
echo "DEBUG: clean some packages"
rm -rf ./cache/lib32-clang*
rm -rf ./cache/lib32-nvidia-cg-toolkit*
rm -rf ./cache/lib32-ocl-icd*
rm -rf ./cache/lib32-opencl-mesa*
echo "All files in ./cache: $(ls ./cache)"

# Add the archlinux32 pentium4 libwbclient and deps:
#ORIGINAL: get_archlinux32_pkgs ./cache/ gst-libav ffmpeg aom gsm lame libass libbluray dav1d libomxil-bellagio libsoxr libssh vid.stab l-smash x264 x265 xvidcore opencore-amr openjpeg2 libwbclient libtirpc tevent talloc ldb libbsd avahi libarchive smbclient
# Can't get from arch64_lib32_plus_user_repo: lib32-ffmpeg lib32-gst-libav lib32-libwbclient lib32-tevent lib32-talloc lib32-ldb lib32-libbsd lib32-avahi lib32-libarchive lib32-smbclient
# removed smbclient and libwbclient smbclient (the .so file isn't loading on wine)
#get_archlinux32_pkgs ./cache/ ffmpeg gst-libav tevent talloc ldb libbsd avahi libarchive libsoxr libssh vid.stab l-smash libtirpc
#get_archlinux32_pkgs ./cache/ tevent talloc ldb libbsd avahi libarchive libsoxr libssh vid.stab l-smash libtirpc

# FIXME: "wine --check-libs" have:
#libcapi20.so.3: missing (from isdn4k-utils trying now from aur)
#libodbc.so.2: missing (removed because, if the lib is there, in unixodbc, then missing!?)
#libsane.so.1: missing (from sane: bigger package just for scanning paper)
#libnetapi.so: missing (removed because, if the lib is there, in smbclient, then missing!?)

# extracting *tar.xz...
find ./cache -name '*tar.xz' -exec tar --warning=no-unknown-keyword -xJf {} \;

# extracting *tar.zst...
find ./cache -name '*tar.zst' -exec tar --warning=no-unknown-keyword --zstd -xf {} \;

# extracting *tar...
find ./cache -name '*tar' -exec tar --warning=no-unknown-keyword -xf {} \;

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
#--------

rm usr/lib32/libkeyutils.so
ln -s libkeyutils.so.1 libkeyutils.so
mv -n libkeyutils.so usr/lib32
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

## gst-libav link
#ln -s ../../lib/gstreamer-1.0/libgstlibav.so libgstlibav.so
#mv libgstlibav.so usr/lib32/gstreamer-1.0/

## temp workaroud to gst-libav load x264. TODO: recompile package and avoid archlinux32 (or use all codecs tree from it)
#ln -s libx264.so libx264.so.157
#mv -n libx264.so.157 usr/lib32
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
#-----------------------------

##test for others AppImage variations (have to change .travis.yml too):
#cp -rp $WINE_WORKDIR test2
#mkdir test2/mark_test2
#-----------------------------

./appimagetool.AppImage --appimage-extract

export ARCH=x86_64; squashfs-root/AppRun -v $WINE_WORKDIR -u 'gh-releases-zsync|ferion11|Wine_Appimage|continuous|wine-i386*arch*.AppImage.zsync' wine-i386_${ARCH}-archlinux.AppImage
export ARCH=x86_64; squashfs-root/AppRun -v $WINE_WORKDIR -u 'gh-releases-zsync|ferion11|Wine_Appimage|continuous|${P_NAME}-${P_MVERSION}-v${P_VERSION}-${P_CSOURCE}-*arch*.AppImage.zsync' ${P_NAME}-${P_MVERSION}-v${P_VERSION}-${P_CSOURCE}-${ARCH}.AppImage

echo "Packing tar result file..."
rm -rf appimagetool.AppImage
tar cvf result.tar *.AppImage *.zsync
echo "* result.tar size: $(du -hs result.tar)"
