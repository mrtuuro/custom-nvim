return {

  {
    'windwp/nvim-autopairs',
    event = "InsertEnter",
    config = true
  },

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

  "tpope/vim-fugitive",

  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" }
  },

  {
    "neovim/nvim-lspconfig",
    dependencies = {
      {
        "folke/lazydev.nvim",
        ft = "lua",
        opts = {
          library = {
            {
              path = "${3rd}/luv/library", words = { "vim%.uv" }
            },
          },
        },
      },
    },
  },

  { 'neovim/nvim-lspconfig' },
  { 'hrsh7th/cmp-nvim-lsp' },
  { 'hrsh7th/nvim-cmp' },

  {
    'echasnovski/mini.nvim',
    config = function()
      local statusline = require 'mini.statusline'
      statusline.setup { use_icons = true }
    end
  },

  {
    'nvim-telescope/telescope.nvim',
    tag = '0.1.8',
    dependencies = {
      'nvim-lua/plenary.nvim',
      { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' }
    }
  },

  {
    'nvim-treesitter/nvim-treesitter',
    lazy = false,
    build = ':TSUpdate',
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = { "lua", "c", "go" },
        auto_install = false,
        highlight = {
          enable = true,
        },
      })
    end,
  },

}
