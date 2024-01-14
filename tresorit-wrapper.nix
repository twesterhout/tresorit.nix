{ bash
, fuse
, rsync
, tresorit
, stdenv
, writeShellScript
, jq
}:

stdenv.mkDerivation {
  name = "tresorit-wrapper";
  version = tresorit.version;

  dontUnpack = true;
  src = writeShellScript "runner.sh" ''
    set -e

    createAndLink() {
      prefix=$1
      folder=$2
      if [[ -e "$folder" && ! -L "$folder" ]]; then
        rm -r "$folder"
      fi
      if [[ ! -d "$folder" ]]; then
        mkdir -p "$prefix/$folder"
        ln --symbolic "$prefix/$folder" .
      fi
    }

    updateIfNeeded() {
      ${rsync}/bin/rsync --checksum --inplace "$@"
    }

    mkdir -p /tmp/tresorit
    cd /tmp/tresorit
    createAndLink "$HOME/.local/share/Tresorit" "CliDumps"
    createAndLink "$HOME/.local/share/Tresorit" "DaemonDumps"
    createAndLink "$HOME/.local/share/Tresorit" "Logs"
    createAndLink "$HOME/.local/share/Tresorit" "Temp"
    createAndLink "$HOME/.config/Tresorit"      "Profiles"
    if [[ ! -f tresorit-daemon ]]; then
      cat >tresorit-daemon <<-EOF
    #! ${bash}/bin/bash -e
    export LD_LIBRARY_PATH="${fuse}/lib:\$LD_LIBRARY_PATH"
    exec -a "\$0" "\$PWD/.tresorit-daemon-wrapped" "\$@"
    EOF
      chmod 755 tresorit-daemon
    fi

    updateIfNeeded ${tresorit}/share/tresorit-cli    /tmp/tresorit/
    updateIfNeeded ${tresorit}/share/tresorit.config /tmp/tresorit/
    updateIfNeeded ${tresorit}/share/tresorit-daemon /tmp/tresorit/.tresorit-daemon-wrapped
    exec "$PWD/tresorit-cli" "$@"
  '';

  installPhase = ''
    # Determine the Tresorit version
    cp ${tresorit}/share/* .
    ./tresorit-cli status &>/dev/null
    tresorit_version=$(cat Logs/*.log | jq '.[0].Version' | sed -E 's:.*Tresorit/([^ ]+) .*:\1:')
    if [[ $tresorit_version != ${tresorit.version} ]]; then
      echo "Error: wrong tresorit version: ${tresorit.version}; should be $tresorit_version"
      exit 1
    fi

    mkdir -p $out/bin
    install -m 755 $src $out/bin/tresorit-cli
  '';

  nativeBuildInputs = [ jq ];
}
