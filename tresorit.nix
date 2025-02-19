{ autoPatchelfHook
, fetchurl
, fuse
, gcc-unwrapped
, lib
, makeWrapper
, stdenv
}:

stdenv.mkDerivation rec {

  version = "3.5.1244.4360";
  name = "tresorit-${version}";

  src = fetchurl {
    url = "https://installerstorage.blob.core.windows.net/public/install/tresorit_installer.run";
    hash = "sha256-hlvy5UeRVG6WN4I2ccpUdQkbb4olmcZoBA0/7tCStu4=";
  };

  nativeBuildInputs = [ autoPatchelfHook makeWrapper ];
  buildInputs = [ gcc-unwrapped.libgcc fuse ];

  unpackPhase = ''
    # head -n92 $src
    tail -n+93 $src | tar xz -C $TMP
  '';

  installPhase = ''
    mkdir -p $out/bin $out/share
    install -m 755 $TMP/tresorit_x64/tresorit-cli $out/share/
    install -m 755 $TMP/tresorit_x64/tresorit-daemon $out/share/
    install -m 644 $TMP/tresorit_x64/tresorit.config $out/share/
  '';

  meta = with lib; {
    description = "Tresorit is the ultra-secure place in the cloud to store, sync and share files easily from anywhere, anytime.";
    homepage = "https://tresorit.com";
    license = licenses.unfree;
    platforms = platforms.linux;
    maintainers = with maintainers; [ apeyroux twesterhout ];
  };
}
