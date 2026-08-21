{
  description = "Nixos config flake";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    nixpkgs-latest.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    quickshell = {
      url = "github:quickshell-mirror/quickshell";
      inputs.nixpkgs.follows = "nixpkgs-latest";
    };
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs-latest";
    };
    ignis = {
      url = "github:ignis-sh/ignis";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zig-overlay = {
      url = "github:mitchellh/zig-overlay";
      inputs.nixpkgs.follows = "nixpkgs-latest";
    };
    vicinae.url = "github:vicinaehq/vicinae";
    zed-editor.url = "github:zed-industries/zed";
    ghostty.url = "github:ghostty-org/ghostty";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-latest,
      home-manager,
      quickshell,
      ignis,
      zig-overlay,
      vicinae,
      zed-editor,
      ghostty,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      lib = nixpkgs.lib;
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      pkgs-latest = import nixpkgs-latest {
        inherit system;
        config.allowUnfree = true;
      };
      extraSpecialArgs = {
        inherit
          system
          inputs
          pkgs-latest
          vicinae
          zed-editor
          ghostty
          ;
      };
      specialArgs = {
        inherit
          system
          inputs
          pkgs-latest
          vicinae
          zed-editor
          ghostty
          ;
      };
    in
    {
      homeConfigurations.ewan = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.${system};
        modules = [ vicinae.homeManagerModules.default ];
      };
      nixosConfigurations.nixos = lib.nixosSystem {
        inherit specialArgs;
        inherit system;
        modules = [
          ./configuration.nix
          home-manager.nixosModules.home-manager
          {
            nix.settings = {
              auto-optimise-store = true;
              substituters = [
                "https://cache.nixos.org"
                "https://nix-community.cachix.org"
              ];
              extra-substituters = [
                "https://vicinae.cachix.org"
                "https://zed.cachix.org"
                "https://ghostty.cachix.org"
              ];
              extra-trusted-public-keys = [
                "vicinae.cachix.org-1:1kDrfienkGHPYbkpNj1mWTr7Fm1+zcenzgTizIcI3oc="
                "zed.cachix.org-1:/pHQ6dpMsAZk2DiP4WCL0p9YDNKWj2Q5FL20bNmw1cU="
                "ghostty.cachix.org-1:QB389yTa6gTyneehvqG58y0WnHjQOqgnA+wBnpWWxns="
              ];
              trusted-public-keys = [
                "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
                "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
              ];
              accept-flake-config = true;
              extra-experimental-features = [
                "flakes"
                "nix-command"
                "ca-derivations"
              ];
            };
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              sharedModules = [ vicinae.homeManagerModules.default ];
              users.ewan = import ./home.nix;
            };
          }
        ];
      };
      devShells.${system} = {
        quickshell =
          let
            qs = quickshell.packages.${system}.default.override {
              withJemalloc = true;
              withQtSvg = true;
              withWayland = true;
              withX11 = false;
              withPipewire = true;
              withPam = true;
              withHyprland = true;
              withI3 = false;
            };
            qtDeps = [
              qs
              pkgs.qt6.qtbase
              pkgs.qt6.qtdeclarative
            ];
          in
          pkgs.mkShell {
            name = "quickshell-dev";
            nativeBuildInputs = qtDeps;
            shellHook =
              let
                qmlPath = pkgs.lib.makeSearchPath "lib/qt-6/qml" qtDeps;
              in
              ''
                export QML2_IMPORT_PATH="$QML2_IMPORT_PATH:${qmlPath}"
              '';
          };

        rust = pkgs.mkShell {
          name = "rust-dev";

          buildInputs = [
            pkgs.rustc
            pkgs.cargo
            pkgs.openssl
            pkgs.pkg-config
            pkgs.llvmPackages.clang
            pkgs.llvmPackages.libclang
            pkgs.llvmPackages.llvm
          ];

          shellHook = ''
            export OPENSSL_DIR=${pkgs.openssl.dev}
            export OPENSSL_LIB_DIR=${pkgs.openssl.out}/lib
            export OPENSSL_INCLUDE_DIR=${pkgs.openssl.dev}/include
            export PKG_CONFIG_PATH=${pkgs.openssl.dev}/lib/pkgconfig

            export LIBCLANG_PATH=${pkgs.llvmPackages.libclang.lib}/lib
            export CLANG_PATH=${pkgs.llvmPackages.clang}/bin/clang
            export BINDGEN_EXTRA_CLANG_ARGS="--target=x86_64 -isystem ${pkgs.glibc.dev}/include";
          '';
        };
      };
    };
}
