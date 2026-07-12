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
  ];

  home.activation.cloneDotfiles =
    lib.hm.dag.entryAfter ["writeBoundary" ] ''
      if [ ! -d "$HOME/dotfiles/.git" ]; then 
        rm -rf "$HOME/dotfiles"
        ${pkgs.git}/bin/git clone https://github.com/nickzou/dotfiles.git "$HOME/dotfiles"
      fi
    '';

  home.activation.stowDotiles =
    lib.hm.dag.entryAfter ["cloneDotfiles" ] ''
      cd "$HOME/dotfiles" && ${pkgs.stow}/bin/stow ghostty hypr lazygit lsd nvim starship tmux yazi zsh
    '';

  home.activation.installTpm =
    lib.hm.dag.entryAfter ["writeBoundary" ] ''
      if [ ! -f "$HOME/.tmux/plugins/tpm/tpm" ]; then
        rm -rf "$HOME/.tmux/plugins/tpm"
        ${pkgs.git}/bin/git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
      fi
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
