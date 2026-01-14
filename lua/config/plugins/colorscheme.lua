return {
  {
    'folke/tokyonight.nvim',
    config = function()
      require('tokyonight').setup({
        style = 'night', -- Options: night, storm, day
        transparent = false,
        terminal_colors = true,
      })
      vim.cmd('colorscheme tokyonight')
    end,
  },
}
