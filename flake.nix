{
  description = "A secret text generator creating multiple meaningful files and directories using a the wisdom of the ether";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      perSystem =
        {
          self',
          pkgs,
          ...
        }:
        {
          packages = {
            default = self'.packages.secret;
            secret = pkgs.writeShellApplication {
              name = "secret";
              runtimeInputs = [
                pkgs.scowl
              ];
              text = ''
                #!/bin/bash
                set -euo pipefail

                WORDLIST="${pkgs.scowl}/share/dict/words.txt"
                if [[ ! -f "$WORDLIST" ]]; then
                    echo "Wordlist not found at $WORDLIST"
                    exit 1
                fi

                # Load wordlist into an array (filter out words with apostrophes for simplicity)
                mapfile -t WORDS < <(grep -v "'" "$WORDLIST")
                WORD_COUNT=''${#WORDS[@]}

                # Function to pick a random word from array
                rand_word() {
                    echo -n "''${WORDS[RANDOM % WORD_COUNT]}"
                }

                # Random number of files between 5 and 12
                FILES=10

                # Random depth (1–3 levels deep)
                MAX_DEPTH=5

                echo "Generating $FILES secret files with max depth $MAX_DEPTH..."

                random_dir_path() {
                    local depth=$((RANDOM % MAX_DEPTH + 1))
                    local path=""
                    for ((d=0; d<depth; d++)); do
                        path+=$(rand_word)
                        if [[ $d -lt $((depth - 1)) ]]; then
                            path+="/"
                        fi
                    done
                    echo "$path"
                }

                for ((f=1; f<=FILES; f++)); do
                    DIR_PATH=$(random_dir_path)
                    FILE_NAME="$(rand_word)_$(rand_word).txt"

                    mkdir -p "secret/$DIR_PATH"

                    FULL_PATH="secret/$DIR_PATH/$FILE_NAME"
                    echo "Writing $FULL_PATH..."

                    # Build each line entirely in Bash
                    for ((i=0; i<1000; i++)); do
                        LINE=""
                        WORDS_IN_LINE=$((RANDOM % 8 + 5))
                        for ((w=0; w<WORDS_IN_LINE; w++)); do
                            LINE+=$(rand_word)" "
                        done
                        echo "$LINE" >> "$FULL_PATH"
                    done
                done

                echo "Done!"
              '';
            };
          };
        };
    };
}
