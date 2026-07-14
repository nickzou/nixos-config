{ config, pkgs, lib, inputs, ... }:
{
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
    hyprpaper
    inputs.zen-browser.packages.${pkgs.system}.default
    discord
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
  # --- NixOS-native user settings (NOT files — stow can't manage these) ---
  # This is the stuff that legitimately belongs in home-manager even in a
  # stow setup, because it's dconf/gsettings state, not dotfiles.
  dconf.settings = {
    "org/gnome/desktop/interface".color-scheme = "prefer-dark";
    "org/gnome/desktop/peripherals/touchpad".natural-scroll = true;
  };

  # Let home-manager manage itself.
  programs.home-manager.enable = true;
}
