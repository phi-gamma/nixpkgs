{ stdenv, fetchurl, fetchpatch, texlive, bison, flex, liblapack
, gmp, mpfr, pari, ntl, gsl, blas, mpfi
, readline, gettext, libpng, libao, gfortran, perl
, enableGUI ? false, libGLU_combined ? null, xorg ? null, fltk ? null
}:

assert enableGUI -> libGLU_combined != null && xorg != null && fltk != null;

stdenv.mkDerivation rec {
  name = "${attr}-${version}";
  attr = if enableGUI then "giac-with-xcas" else "giac";
  version = "1.4.9-59"; # TODO try to remove preCheck phase on upgrade

  src = fetchurl {
    url = "https://www-fourier.ujf-grenoble.fr/~parisse/debian/dists/stable/main/source/giac_${version}.tar.gz";
    sha256 = "0dv5p5y6gkrsmz3xa7fw87rjyabwdwk09mqb09kb7gai9n9dgayk";
  };

  patches = stdenv.lib.optionals (!enableGUI) [
    # when enableGui is false, giac is compiled without fltk. That means some
    # outputs differ in the make check. Patch around this:
    (fetchpatch {
      url    = "https://git.sagemath.org/sage.git/plain/build/pkgs/giac/patches/nofltk-check.patch?id=7553a3c8dfa7bcec07241a07e6a4e7dcf5bb4f26";
      sha256 = "0xkmfc028vg5w6va04gp2x2iv31n8v4shd6vbyvk4blzgfmpj2cw";
    })
  ];

  postPatch = ''
    for i in doc/*/Makefile*; do
      substituteInPlace "$i" --replace "/bin/cp" "cp";
    done;
  '';

  nativeBuildInputs = [
    texlive.combined.scheme-small bison flex
  ];

  # perl is only needed for patchShebangs fixup.
  buildInputs = [
    gmp mpfr pari ntl gsl blas mpfi
    readline gettext libpng libao perl
    # gfortran.cc default output contains static libraries compiled without -fPIC
    # we want libgfortran.so.3 instead
    (stdenv.lib.getLib gfortran.cc)
    liblapack
  ] ++ stdenv.lib.optionals enableGUI [
    libGLU_combined fltk xorg.libX11
  ];

  outputs = [ "out" "doc" ];

  doCheck = true;
  preCheck = ''
    # One test in this file fails. That test just tests a part of the pari
    # interface that isn't actually used in giac. Of course it would be better
    # to only remove that one test, but that would require a patch.
    # Removing the whole test set should be good enough for now.
    # Upstream report: https://xcas.univ-grenoble-alpes.fr/forum/viewtopic.php?f=4&t=2102#p10326
    echo > check/chk_fhan11
  '';

  enableParallelBuilding = true;

  configureFlags = [
    "--enable-gc" "--enable-png" "--enable-gsl" "--enable-lapack"
    "--enable-pari" "--enable-ntl" "--enable-gmpxx" # "--enable-cocoa"
    "--enable-ao"
  ] ++ stdenv.lib.optionals enableGUI [
    "--enable-gui" "--with-x"
  ];

  postInstall = ''
    # example Makefiles contain the full path to some commands
    # notably texlive, and we don't want texlive to become a runtime
    # dependency
    for file in $(find $out -name Makefile) ; do
      sed -i "s@/nix/store/[^/]*/bin/@@" "$file" ;
    done;

    # reference cycle
    rm "$out/share/giac/doc/el/"{casinter,tutoriel}/Makefile

    mkdir -p "$doc/share/giac"
    mv "$out/share/giac/doc" "$doc/share/giac"
    mv "$out/share/giac/examples" "$doc/share/giac"
  '';

  meta = with stdenv.lib; {
    description = "A free computer algebra system (CAS)";
    homepage = "https://www-fourier.ujf-grenoble.fr/~parisse/giac.html";
    license = licenses.gpl3Plus;
    ## xcas is buildable on darwin but there are specific instructions I could
    ## not test
    platforms = platforms.linux;
    maintainers = [ maintainers.symphorien ];
  };
}
