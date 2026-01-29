{ ... }: {
  config = {
    programs.nixvim = {
      colorschemes = {
        catppuccin = {
          enable = true;
        };
      };
    };
  };
}
