{ config, pkgs, ... }:
{
  home.username = "ewan";
  home.homeDirectory = "/home/ewan";
  home.stateVersion = "25.05";

  programs.git = {
    enable = true;
    userName = "notxorand";
    userEmail = "ewanretorokugbe@gmail.com";
    extraConfig = {
      init.defaultBranch = "dev";
    };
  };

  services.swayidle =
    let
      lock = "${pkgs.hyprlock}/bin/hyprlock --no-fade-in";
      display = status: "${pkgs.niri}/bin/niri msg action power-${status}-monitors";
    in
    {
      enable = true;
      timeouts = [
        {
          timeout = 1785;
          command = "${pkgs.libnotify}/bin/notify-send 'Locking in 5 seconds' -t 5000";
        }
        {
          timeout = 1800;
          command = lock;
        }
        {
          timeout = 300;
          command = display "off";
          resumeCommand = display "on";
        }
        {
          timeout = 2700;
          command = "${pkgs.systemd}/bin/systemctl suspend";
        }
      ];
      events = [
        {
          event = "before-sleep";
          command = (display "off") + "; " + lock;
        }
        {
          event = "after-resume";
          command = display "on";
        }
        {
          event = "lock";
          command = (display "off") + "; " + lock;
        }
        {
          event = "unlock";
          command = display "on";
        }
      ];
    };

  programs.home-manager.enable = true;

  home.file = {
    ".config/niri/config.kdl".source = ./sources/config.kdl;
    ".config/yazi/yazi.toml".source = ./sources/yazi.toml;
    ".config/starship.toml".source = ./sources/starship.toml;
    ".config/ghostty".source = ./sources/ghostty;
    ".config/ghostty".recursive = true;
    ".config/fastfetch".source = ./sources/fastfetch;
    ".config/fastfetch".recursive = true;
    ".config/quickshell".source = ./sources/quickshell;
    ".config/quickshell".recursive = true;
    ".config/qt5ct".source = ./sources/qt5ct;
    ".config/qt5ct".recursive = true;
    ".config/qt6ct".source = ./sources/qt6ct;
    ".config/qt6ct".recursive = true;
  };

  home.pointerCursor = {
    name = "Bibata-Modern-Classic";
    size = 24;
    gtk.enable = true;
    x11.enable = true;
    package = pkgs.bibata-cursors;
  };

  home.sessionVariables = {
    DISABLE_QT5_COMPAT = "0";
    QT_AUTO_SCREEN_SCALE_FACTOR = "1";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    QT_QPA_PLATFORM = "wayland";
    QT_QPA_PLATFORMTHEME = "qt6ct";
    QT_STYLE_OVERRIDE = "kvantum";
    OPENSSL_DIR = "${pkgs.openssl.dev}";
    OPENSSL_LIB_DIR = "${pkgs.openssl.out}/lib";
    OPENSSL_INCLUDE_DIR = "${pkgs.openssl.dev}/include";
    PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig";
    LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";
    CLANG_PATH = "${pkgs.llvmPackages.clang}/bin/clang";
    BINDGEN_EXTRA_CLANG_ARGS = "--target=x86_64 -isystem ${pkgs.glibc.dev}/include";
  };

  home.sessionPath = [
    "$HOME/.cargo/bin"
  ];
}
