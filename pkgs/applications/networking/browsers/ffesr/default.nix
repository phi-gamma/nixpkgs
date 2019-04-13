{ stdenv
, lib
, fetchurl
, config
, atk
, cairo
, curl
, cups
, dbus-glib
, dbus
, fontconfig
, freetype
, gdk_pixbuf
, glib
, glibc
, gtk2
, xorg
, libX11
, libXScrnSaver
, libxcb
, libXcomposite
, libXcursor
, libXdamage
, libXext
, libXfixes
, libXi
, libXinerama
, libXrender
, libXt
, libnotify
, libGLU_combined
, nspr
, nss
, pango
, libpulseaudio
, systemd
, writeScript
, writeText
, xidel
, coreutils
, autoconf213
, gnused
, gnugrep
, gnupg
, ffmpeg
, which
, pkgconfig
, runtimeShell
, python2
, perl
, yasm
, zip
, unzip
, systemLocale ? config.i18n.defaultLocale or "en-US"
}:

assert stdenv.cc.libc or null != null;

let
  libs = [
    gtk2
    perl
    zip
    unzip
    #libjpeg
    #zlib
    #bzip2
    dbus dbus-glib pango freetype fontconfig
    xorg.libXi xorg.libXcursor
    xorg.libX11 xorg.libXrender xorg.libXft xorg.libXt
    #file
    nspr libnotify xorg.pixman
    yasm
    libGLU_combined
    xorg.libXScrnSaver 
    xorg.libXdamage
    xorg.libXext
    #sqlite
    #makeWrapper
    #libevent
    #libvpx
    #cairo
    #icu
    #libpng
    #jemalloc
    glib
    libpulseaudio
  ];

  nlibs = [
    autoconf213 which gnused pkgconfig
    #perl
    python2
  ];
in

stdenv.mkDerivation rec {
  version = "52.9.0esr";
  name = "firefox-phg-${version}";
  src = fetchurl {
    url = "http://ftp.mozilla.org/pub/firefox/releases/${version}/source/firefox-${version}.source.tar.xz";
    sha512 = "bfca42668ca78a12a9fb56368f4aae5334b1f7a71966fbba4c32b9c5e6597aac79a6e340ac3966779d2d5563eb47c054ab33cc40bfb7306172138ccbd3adb2b9";
  };

  dontStrip = true;
  dontPatchELF = true;

  buildInputs = libs;
  nativeBuildInputs = nlibs;

  configureFlags = [
    "--enable-pulseaudio"
    "--disable-skia"
    "--disable-system-cairo"
    "--enable-application=browser"
    "--disable-system-ffi"
    "--disable-system-pixman"
    "--disable-system-sqlite"
    "--disable-startup-notification"
    "--disable-tests"
    "--disable-necko-wifi"
    "--disable-updater"
    "--enable-jemalloc"
    "--disable-maintenance-service"
    "--disable-gconf"
    "--enable-default-toolkit=cairo-gtk2"
   #"--enable-optimize"
    "--enable-strip"
  ];

  enableParallelBuilding = true;
  doCheck = false; # "--disable-tests" above

  preConfigure = ''
    rm -f configure
    rm -f js/src/configure
    rm -f .mozconfig*
    make -f client.mk configure-files
    configureScript="$(realpath ./configure)"
    cd obj-*
  '';

  postInstall = lib.optionalString stdenv.isLinux ''
    # Remove SDK cruft. FIXME: move to a separate output?
    rm -rf $out/share/idl $out/include $out/lib/firefox-devel-*
  '';

  postFixup = lib.optionalString stdenv.isLinux ''
    # Fix notifications. LibXUL uses dlopen for this, unfortunately; see #18712.
    patchelf --set-rpath "${lib.getLib libnotify
      }/lib:$(patchelf --print-rpath "$out"/lib/firefox*/libxul.so)" \
        "$out"/lib/firefox*/libxul.so
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    # Some basic testing
    "$out/bin/firefox" --version
  '';

  meta = with stdenv.lib; {
    homepage = https://mozilla.org;
    description = "gecko 4 life";
    license = {
      free = false;
      url = http://www.mozilla.org/en-US/foundation/trademarks/policy/;
    };
    platforms = platforms.linux;
    maintainers = [ phg ];
  };
}
