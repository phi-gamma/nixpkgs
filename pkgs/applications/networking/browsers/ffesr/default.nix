{ stdenv
, lib
, fetchurl
, config
, alsaLib
, atk
, cairo
, curl
, cups
, dbus-glib
, dbus
, fontconfig
, freetype
#, gconf
, gdk_pixbuf
, glib
, glibc
#, gtk2
, gtk3
, kerberos
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
#, libcanberra-gtk2
#, libgnome
#, libgnomeui
, libnotify
, gnome3
, libGLU_combined
, nspr
, nss
, pango
, libheimdal
, libpulseaudio
, systemd
#, channel
#, generated
, writeScript
, writeText
, xidel
, coreutils
, gnused
, gnugrep
, gnupg
, ffmpeg
, runtimeShell
, systemLocale ? config.i18n.defaultLocale or "en-US"
}:

#let
  #policies = {
    #DisableAppUpdate = true;
  #};

  #policiesJson =
    #writeText "no-update-firefox-policy.json" (builtins.toJSON { inherit policies; });
#in

stdenv.mkDerivation rec {
  name = "firefox-phg-${version}";
  version = "52.0.9";

  dontStrip = true;
  dontPatchELF = true;

  src = fetchurl {
    url = "http://archive.mozilla.org/pub/firefox/releases/52.0esr/linux-x86_64/en-US/firefox-52.0esr.tar.bz2";
    sha512 = "0rsvkmqjgv81iljqw7qbml2wf47h4v33i6knalc227dbs993ck2jg11a5kk007hmcqlnfi4ij39mzvpqwfa0v6mwc42r3ja0k69w5z7";
  };

  #inherit gtk3;

  unpackCmd = ''
    tar xjf "$src"
  '';

  patchPhase = ''
    echo 'pref("app.update.auto", "false");' >> defaults/pref/channel-prefs.js
  '';

  buildPhase = ":";   # nothing to build

  installPhase = let
    libPath = lib.makeLibraryPath [
      stdenv.cc.cc
      alsaLib
      (lib.getDev alsaLib)
      atk
      cairo
      curl
      cups
      dbus-glib
      dbus
      fontconfig
      freetype
      gdk_pixbuf
      glib
      glibc
      gtk3
      kerberos
      libX11
      libXScrnSaver
      libXcomposite
      libXcursor
      libxcb
      libXdamage
      libXext
      libXfixes
      libXi
      libXinerama
      libXrender
      libXt
      libnotify
      libGLU_combined
      nspr
      nss
      pango
      libheimdal
      libpulseaudio
      (lib.getDev libpulseaudio)
      systemd
      ffmpeg
    ];
  in ''
    rm -f -- ./run-mozilla.sh

    mkdir -p $prefix/lib/firefox
    cp -R * $prefix/lib/firefox

    mkdir -p "$out/bin"
    ln -s $prefix/lib/firefox/firefox $out/bin/

    for executable in \
      firefox firefox-bin plugin-container \
      updater crashreporter webapprt-stub
    do
      if [ -e "$out/lib/firefox/$executable" ]; then
        patchelf \
          --interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
          "$out/lib/firefox/$executable"
      fi
    done

    find $out/lib/firefox/ -executable -type f -exec \
      patchelf --set-rpath "${libPath}" \
        {} \;
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

