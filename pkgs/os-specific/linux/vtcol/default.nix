{ stdenv, fetchFromGitHub, rustPlatform, cargo, }:

rustPlatform.buildRustPackage rec {
  name = "vtcol-v0.42.2-2";
  src = fetchFromGitHub {
    owner = "phi-gamma";
    repo = "vtcol";
    rev = "19d6b81b879ab63140eb6941113e016e13149982";
    sha256 = "03wsalji7p3smvdf0hby9xnspswqdhzx5yw65z5b507fvafx2289";
  };

  cargoSha256 = "1zpf9fv0r5r970q80v70izly7maqjv7kz5gyq22kc40wf50jpp0s";

  preInstall = ''
    cargo update
  '';

  meta = with stdenv.lib; {
    broken = false;
    description = "Set Linux console color scheme";
    homepage = https://github.com/phi-gamma/vtcol;
    license = stdenv.lib.licenses.gpl3;
  };
}
