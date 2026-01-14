return {
  {
    'nvim-treesitter/nvim-treesitter',
    lazy = false,
    build = ':TSUpdate',
    config = function() 
      require("nvim-treesitter.config").setup({
        ensure_installed = {"lua", "c", "go"},
        auto_install = false,
        highlight = { enable = true },
      })
    end,
  },
}
