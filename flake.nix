{
  description = "";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = {
    self,
    nixpkgs,
  }: let
    systems = builtins.attrNames nixpkgs.legacyPackages;
    supportedSystems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];
    pkgsBySystem = nixpkgs.lib.getAttrs supportedSystems nixpkgs.legacyPackages;
    forAllSystems = fn: nixpkgs.lib.mapAttrs (system: pkgs: (fn pkgs)) pkgsBySystem;
    pythonEnv = pkgs:
      pkgs.python3.withPackages (ps:
        with ps; [
          requests
          pyyaml
        ]);
  in {
    formatter = forAllSystems (pkgs: pkgs.alejandra);
    packages = forAllSystems (pkgs: {
      default = pkgs.stdenv.mkDerivation {
        name = "openaudible_to_ab.py";
        # src = ./.;
        src = pkgs.fetchFromGitHub {
          owner = "stratus-ss";
          repo = "OpenAudible-To-AudibleBookShelf";
          rev = "d31ff5e90171f12b32cc80b1444eea29a47a7cf1";
          hash = "sha256-g06VGWu8ZO1XBPQJs/GyIzDYWwJ8XDEt82Hx9uyKYOk=";
        };
        nativeBuildInputs = [pkgs.makeBinaryWrapper];
        installPhase = ''
          mkdir -p $out/bin $out/lib
          cp config.py openaudible_to_ab.py $out/lib
          makeBinaryWrapper ${(pythonEnv pkgs)}/bin/python3 $out/bin/openaudible_to_ab.py \
            --add-flags "$out/lib/openaudible_to_ab.py"
        '';
      };
    });
    devShells = forAllSystems (pkgs: {
      default = pkgs.mkShell {
        buildInputs = [
          (pythonEnv pkgs)
          pkgs.ruff
        ];
        shellHook = ''
          echo "Python development environment activated!"
          echo "Python: $(which python3)"
        '';
      };
    });
  };
}
