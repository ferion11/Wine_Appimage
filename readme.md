# Appimage For Wine

Appimage for last Wine 32bits from PlayOnLinux. You can just download the Appimage, put in the directory you like and make symbolic links for it (for wine, wineserver...).

#### 1- Download wine-i386_x86_64-archlinux.AppImage for your AppImage directory
#### 2- Make executable:
- `$ chmod +x wine-i386_x86_64-archlinux.AppImage`
#### 3- Make the wine link in your bin directory:
- `$ ln -s wine-i386_x86_64-archlinux.AppImage wine`
#### 4- Make the wineserver link (for winetricks) in your bin directory:
- `$ ln -s wine-i386_x86_64-archlinux.AppImage wineserver`

## Have set:
- WINEARCH=win32
- WINEPREFIX=~/.wine32

## Usage:
#### For configuration, just run "wine" (it will run the winecfg) or:
- `$ wine winecfg`
#### For regedit:
- `wine regedit.exe`
#### For your Apps:
- `wine xyz.exe`
#### If you use PRIME, you can use something like that too:
- `DRI_PRIME=1 wine xyz.exe`
