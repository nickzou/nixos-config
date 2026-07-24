{ config, pkgs, lib, inputs, ... }:
{
  imports = [ inputs.plasma-manager.homeModules.plasma-manager ];

  home.username = "nickz";
  home.homeDirectory = "/home/nickz";

  # Must match your system's stateVersion. 26.05 matches your flake's nixpkgs.
  # If home-manager errors on first build, use whatever value it names.
  home.stateVersion = "26.05";

  # --- User packages (the binaries; configs stay in stow) ---
  home.packages = with pkgs; [
    ripgrep
    fd
    bat
    jq
    claude-code
    clickup
    discord
    inputs.herdr.packages.${pkgs.system}.default
    hyprnotify
    hyprpaper
    inputs.zen-browser.packages.${pkgs.system}.default
    keepassxc
    rclone
    waybar
    wofi
    signal-desktop
    zapzap
    # rust related
    rustc
    cargo
    rustfmt
    clippy
    rust-analyzer
  ];

  home.activation.cloneDotfiles =
    lib.hm.dag.entryAfter ["writeBoundary" ] ''
      if [ ! -d "$HOME/dotfiles/.git" ]; then 
        rm -rf "$HOME/dotfiles"
        ${pkgs.git}/bin/git clone https://github.com/nickzou/dotfiles.git "$HOME/dotfiles"
      fi
    '';

  home.activation.stowDotfiles =
    lib.hm.dag.entryAfter ["cloneDotfiles" ] ''
      cd "$HOME/dotfiles" && ${pkgs.stow}/bin/stow ghostty fastfetch hypr lazygit lsd nvim starship tmux waybar wofi yazi zsh
    '';

  # Install tpm + the plugins declared in tmux.conf via the repo's bootstrap
  # script (the same one used by hand on macOS/Ubuntu). Runs after stow so
  # ~/.config/tmux/tmux.conf is in place first.
  home.activation.installTmuxPlugins =
    lib.hm.dag.entryAfter ["stowDotfiles" ] ''
      export PATH="${pkgs.git}/bin:${pkgs.tmux}/bin:$PATH"
      ${pkgs.bash}/bin/bash "$HOME/dotfiles/tmux/bootstrap.sh" || true
    '';

  home.activation.createKeepassDir =
    lib.hm.dag.entryAfter ["writeBoundary"] ''
      mkdir -p "$HOME/keepass"
    '';
  # --- NixOS-native user settings (NOT files — stow can't manage these) ---
  # This is the stuff that legitimately belongs in home-manager even in a
  # stow setup, because it's dconf/gsettings state, not dotfiles.
  # Kept for GTK 4 / libadwaita apps — this gsettings key is a cross-desktop
  # standard that GTK apps read directly, even under Plasma.
  dconf.settings = {
    "org/gnome/desktop/interface".color-scheme = "prefer-dark";
  };

  # Default image viewer -> Gwenview (ships with Plasma 6). Makes Dolphin and
  # other apps open images in Gwenview without the "select a program" prompt.
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "image/png"     = "org.kde.gwenview.desktop";
      "image/jpeg"    = "org.kde.gwenview.desktop";
      "image/gif"     = "org.kde.gwenview.desktop";
      "image/webp"    = "org.kde.gwenview.desktop";
      "image/bmp"     = "org.kde.gwenview.desktop";
      "image/tiff"    = "org.kde.gwenview.desktop";
      "image/svg+xml" = "org.kde.gwenview.desktop";
    };
  };

  # --- Plasma (KDE) declarative config via plasma-manager ---
  programs.plasma = {
    enable = true;
    input.touchpads = [
      {
        # Synaptics I2C touchpad, from /proc/bus/input/devices.
        name = "SYNA30B3:00 06CB:CE08";
        vendorId = "06cb";
        productId = "ce08";
        naturalScroll = false;
        scrollSpeed = 0.6;
      }
    ];
  };

  # Let home-manager manage itself.
  programs.home-manager.enable = true;
}
