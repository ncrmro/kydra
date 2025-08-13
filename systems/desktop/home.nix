# Home Manager configuration for desktop user
{ config, pkgs, ... }:

{
  # Home Manager settings
  home.username = "kydra";
  home.homeDirectory = "/home/kydra";
  home.stateVersion = "23.11";

  # User packages
  home.packages = with pkgs; [
    # Development tools
    git
    gh
    nodejs
    python3
    rustc
    cargo
    go
    
    # Terminal utilities
    alacritty
    tmux
    fzf
    ripgrep
    fd
    bat
    exa
    delta
    
    # System utilities
    htop
    btop
    neofetch
    tree
    wget
    curl
    jq
    
    # Media and graphics
    feh
    mpv
    imagemagick
    
    # Communication
    element-desktop
    telegram-desktop
  ];

  # Git configuration
  programs.git = {
    enable = true;
    userName = "Kydra User";
    userEmail = "user@kydra.local";
    extraConfig = {
      init.defaultBranch = "main";
      core.editor = "vim";
      pull.rebase = false;
    };
  };

  # Shell configuration
  programs.bash = {
    enable = true;
    bashrcExtra = ''
      # Kydra OS aliases
      alias ll='ls -alF'
      alias la='ls -A'
      alias l='ls -CF'
      alias ..='cd ..'
      alias ...='cd ../..'
      alias grep='grep --color=auto'
      
      # Kydra-specific commands
      alias kstatus='kydra-status'
      alias kupdate='kydra-update'
      alias kbackup='kydra-backup-check'
      alias klogs='kydra-logs'
    '';
  };

  # Vim configuration
  programs.vim = {
    enable = true;
    settings = {
      number = true;
      relativenumber = true;
      tabstop = 2;
      shiftwidth = 2;
      expandtab = true;
    };
    extraConfig = ''
      syntax on
      set autoindent
      set smartindent
      set hlsearch
      set incsearch
    '';
  };

  # Terminal emulator
  programs.alacritty = {
    enable = true;
    settings = {
      font = {
        normal.family = "FiraCode Nerd Font";
        size = 12;
      };
      colors = {
        primary = {
          background = "0x1e1e1e";
          foreground = "0xd4d4d4";
        };
      };
    };
  };

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;
}