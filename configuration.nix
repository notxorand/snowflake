{
  config,
  pkgs,
  pkgs-latest,
  lib,
  inputs,
  system,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "nixos";

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  documentation.enable = false;
  documentation.nixos.enable = false;

  networking.networkmanager.enable = true;

  networking.firewall = {
    allowedTCPPorts = [
      53317
    ];
    allowedUDPPorts = [
      53317
    ];
  };

  time.timeZone = "Africa/Lagos";

  i18n.defaultLocale = "en_GB.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_NG";
    LC_IDENTIFICATION = "en_NG";
    LC_MEASUREMENT = "en_NG";
    LC_MONETARY = "en_NG";
    LC_NAME = "en_NG";
    LC_NUMERIC = "en_NG";
    LC_PAPER = "en_NG";
    LC_TELEPHONE = "en_NG";
    LC_TIME = "en_NG";
  };

  virtualisation.docker = {
    enable = true;
  };

  services.xserver.enable = true;

  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  services.printing.enable = true;

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  security.pam.services.login.fprintAuth = lib.mkForce true;
  security.pam.services.sudo.fprintAuth = true;
  security.pam.services.gdm-password.fprintAuth = true;
  security.pam.services.polkit-1.fprintAuth = true;
  security.pam.services.hyprlock = {
    fprintAuth = lib.mkForce true;
  };
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  fonts.packages = with pkgs; [
    nerd-fonts.geist-mono
    nerd-fonts.space-mono
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono
    nerd-fonts.hack
    nerd-fonts.inconsolata
    nerd-fonts.zed-mono
  ];

  users.users.ewan = {
    isNormalUser = true;
    description = "ewan";
    shell = pkgs.fish;
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
    ];
    packages = with pkgs; [
    ];
  };

  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "ewan";

  # Workaround for GNOME autologin: https://github.com/NixOS/nixpkgs/issues/103746#issuecomment-945091229
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

  services.fprintd.enable = true;
  services.fprintd.tod.enable = true;
  services.fprintd.tod.driver = pkgs.libfprint-2-tod1-goodix;

  systemd.packages = [
    pkgs.cloudflare-warp
    pkgs.wayland-pipewire-idle-inhibit
  ];
  systemd.targets.multi-user.wants = [
    "warp-svc.service"
    "wayland-pipewire-idle-inhibit.service"
  ];
  services.cloudflare-warp.enable = true;
  systemd.user.services.warp-taskbar.wantedBy = [ "graphical.target" ];

  programs.firefox.enable = true;
  programs.niri.enable = true;
  programs.fish.enable = true;

  nixpkgs.config.allowUnfree = true;

  environment.variables.PATH = [
    "$HOME/.cargo/bin"
    "$HOME/.local/bin"
  ];

  environment.variables = {
    PENSSL_DIR = "${pkgs.openssl.dev}";
    PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig";
    LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";
    CLANG_PATH = "${pkgs.llvmPackages.clang}/bin/clang";
    BINDGEN_EXTRA_CLANG_ARGS = "--target=x86_64 -isystem ${pkgs.glibc.dev}/include";
    QML2_IMPORT_PATH =
      with pkgs;
      lib.concatStringsSep ":" [
        "${libsForQt5.qt5.qtgraphicaleffects}/lib/qt-5/qml"
        "${kdePackages.qt5compat}/lib/qt-6/qml"
        "${kdePackages.qtbase}/lib/qt-6/qml"
        "${kdePackages.qtdeclarative}/lib/qt-6/qml"
      ];
  };

  environment.systemPackages =
    with pkgs;
    with pkgs-latest;
    import ./packages.nix {
      inherit pkgs;
      inherit inputs;
      inherit system;
      inherit pkgs-latest;
    };

  services.openssh.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?

}
