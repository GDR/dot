{ ... }: {
  config.programs.nixvim = {
    opts = {
      shiftwidth = 2;

      number = true;
      relativenumber = true;
    };
  };
}
