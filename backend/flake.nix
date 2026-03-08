{
  description = "Arduino Security System Backend";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
  };

    outputs = { self, nixpkgs, rust-overlay, ... }:
      let
        system = "x86_64-linux";
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ (import rust-overlay) ];
        };
      in
      {
        apps.${system}.default = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/security-system";
        };

        packages.${system}.default = pkgs.rustPlatform.buildRustPackage {
          pname = "security-system";
          version = "0.1.0";
          src = ./.;
          cargoLock.lockFile = ./Cargo.lock;
          
          nativeBuildInputs = [ pkgs.pkg-config ];
          buildInputs = [ pkgs.systemd ];
          
          PKG_CONFIG_PATH = "${pkgs.systemd.dev}/lib/pkgconfig";
        };

        devShells.${system}.default = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [ pkg-config cargo rustc ];
          buildInputs = with pkgs; [ systemd ];
          shellHook = ''
            export PKG_CONFIG_PATH="${pkgs.systemd.dev}/lib/pkgconfig"
            zsh
          '';
        };
      };
}
