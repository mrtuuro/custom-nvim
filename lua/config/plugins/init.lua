return {

  {
    'windwp/nvim-autopairs',
    event = "InsertEnter",
    config = true
  },

  -- Available alternative theme. Active colorscheme is set once in
  -- after/plugin/colors.lua (kanagawa). To switch, change that file.
  {
    'folke/tokyonight.nvim',
    config = function()
      require('tokyonight').setup({
        style = 'night', -- Options: night, storm, day
        transparent = false,
        terminal_colors = true,
      })
    end,
  },

  { "rebelot/kanagawa.nvim", name = "kanagawa" },

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

  -- LSP server installer. Just ensures servers are installed; enabling +
  -- config stays explicit in after/plugin/lsp.lua (automatic_enable = false).
  {
    "williamboman/mason.nvim",
    config = true,
  },
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim", "neovim/nvim-lspconfig" },
    opts = {
      ensure_installed = { "gopls", "lua_ls", "vtsls", "jdtls", "clangd" },
      automatic_enable = false,
    },
  },

  { 'hrsh7th/cmp-nvim-lsp' },
  { 'hrsh7th/cmp-buffer' },
  { 'hrsh7th/cmp-path' },
  { 'hrsh7th/nvim-cmp' },

  -- Snippet engine + source + a community snippet collection.
  {
    "L3MON4D3/LuaSnip",
    dependencies = { "rafamadriz/friendly-snippets" },
    config = function()
      require("luasnip.loaders.from_vscode").lazy_load()
    end,
  },
  { "saadparwaiz1/cmp_luasnip" },

  {
    'echasnovski/mini.nvim',
    config = function()
      require('mini.statusline').setup { use_icons = true }
      -- Add/delete/replace surroundings: sa, sd, sr (+ sf/sF/sh/sn).
      -- Note: this takes over the bare `s` prefix (substitute char).
      require('mini.surround').setup()
      -- Smarter a/i textobjects (brackets, quotes, args, etc.).
      require('mini.ai').setup()
    end
  },

  {
    'nvim-telescope/telescope.nvim',
    dependencies = {
      'nvim-lua/plenary.nvim',
      { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' }
    }
  },

  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'master',
    build = ':TSUpdate',
    dependencies = {
      "nvim-treesitter/nvim-treesitter-textobjects",
    },
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = { "lua", "c", "go" },
        auto_install = false,
        highlight = {
          enable = true,
        },
      })

      -- Textobjects config
      require("nvim-treesitter-textobjects").setup({
        select = {
          lookahead = true,
        },
        move = {
          set_jumps = true,
        },
      })

      local select = require("nvim-treesitter-textobjects.select")
      local move = require("nvim-treesitter-textobjects.move")
      local swap = require("nvim-treesitter-textobjects.swap")

      -- Select textobjects
      local select_maps = {
        { "af", "@function.outer",    "Select around function" },
        { "if", "@function.inner",    "Select inside function" },
        { "ac", "@class.outer",       "Select around class/struct" },
        { "ic", "@class.inner",       "Select inside class/struct" },
        { "aa", "@parameter.outer",   "Select around parameter" },
        { "ia", "@parameter.inner",   "Select inside parameter" },
        { "ai", "@conditional.outer", "Select around conditional" },
        { "ii", "@conditional.inner", "Select inside conditional" },
        { "al", "@loop.outer",        "Select around loop" },
        { "il", "@loop.inner",        "Select inside loop" },
      }
      for _, map in ipairs(select_maps) do
        vim.keymap.set({ "x", "o" }, map[1], function()
          select.select_textobject(map[2])
        end, { desc = map[3] })
      end

      -- Move: goto next/prev
      local move_maps = {
        { "]f", "goto_next_start",     "@function.outer",  "Next function start" },
        { "]c", "goto_next_start",     "@class.outer",     "Next class/struct start" },
        { "]a", "goto_next_start",     "@parameter.inner", "Next parameter" },
        { "]F", "goto_next_end",       "@function.outer",  "Next function end" },
        { "]C", "goto_next_end",       "@class.outer",     "Next class/struct end" },
        { "[f", "goto_previous_start", "@function.outer",  "Previous function start" },
        { "[c", "goto_previous_start", "@class.outer",     "Previous class/struct start" },
        { "[a", "goto_previous_start", "@parameter.inner", "Previous parameter" },
        { "[F", "goto_previous_end",   "@function.outer",  "Previous function end" },
        { "[C", "goto_previous_end",   "@class.outer",     "Previous class/struct end" },
      }
      for _, map in ipairs(move_maps) do
        vim.keymap.set({ "n", "x", "o" }, map[1], function()
          move[map[2]](map[3])
        end, { desc = map[4] })
      end

      -- Swap
      vim.keymap.set("n", "<leader>sn", function()
        swap.swap_next("@parameter.inner")
      end, { desc = "Swap parameter with next" })
      vim.keymap.set("n", "<leader>sp", function()
        swap.swap_previous("@parameter.inner")
      end, { desc = "Swap parameter with previous" })
    end,
  },

  {
    "maxandron/goplements.nvim",
    ft = "go",
    opts = {
      prefix = {
        interface = "implemented by: ",
        struct = "implements: ",
      },
    },
  },

  {
    "stevearc/oil.nvim",
    config = function()
      require("oil").setup({
        default_file_explorer = true,
        columns = { "icon" },
        view_options = {
          show_hidden = true,
        },
        float = {
          padding = 2,
          max_width = 50,
          max_height = 0,
          border = "rounded",
          win_options = {
            winblend = 0,
          },
          override = function(conf)
            -- Sag tarafa yasla
            conf.anchor = "NE"
            conf.col = vim.o.columns
            conf.row = 0
            conf.width = 50
            conf.height = vim.o.lines - 4
            return conf
          end,
        },
        keymaps = {
          ["g?"] = "actions.show_help",
          ["<CR>"] = "actions.select",
          ["<C-v>"] = "actions.select_vsplit",
          ["<C-x>"] = "actions.select_split",
          ["<C-t>"] = "actions.select_tab",
          ["<C-p>"] = "actions.preview",
          ["q"] = "actions.close",
          ["-"] = "actions.parent",
          ["_"] = "actions.open_cwd",
          ["`"] = "actions.cd",
          ["gs"] = "actions.change_sort",
          ["gx"] = "actions.open_external",
          ["g."] = "actions.toggle_hidden",
        },
        use_default_keymaps = false,
      })
    end,
  },

  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      signs = {
        add          = { text = "+" },
        change       = { text = "~" },
        delete       = { text = "_" },
        topdelete    = { text = "‾" },
        changedelete = { text = "~" },
      },
      on_attach = function(bufnr)
        local gs = package.loaded.gitsigns
        local opts = function(desc)
          return { buffer = bufnr, desc = desc }
        end

        vim.keymap.set("n", "]h", gs.next_hunk, opts("Next git hunk"))
        vim.keymap.set("n", "[h", gs.prev_hunk, opts("Previous git hunk"))
        vim.keymap.set("n", "<leader>hs", gs.stage_hunk, opts("Stage hunk"))
        vim.keymap.set("n", "<leader>hr", gs.reset_hunk, opts("Reset hunk"))
        vim.keymap.set("v", "<leader>hs", function()
          gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
        end, opts("Stage hunk (visual)"))
        vim.keymap.set("v", "<leader>hr", function()
          gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
        end, opts("Reset hunk (visual)"))
        vim.keymap.set("n", "<leader>hS", gs.stage_buffer, opts("Stage buffer"))
        vim.keymap.set("n", "<leader>hu", gs.undo_stage_hunk, opts("Undo stage hunk"))
        vim.keymap.set("n", "<leader>hR", gs.reset_buffer, opts("Reset buffer"))
        vim.keymap.set("n", "<leader>hp", gs.preview_hunk, opts("Preview hunk"))
        vim.keymap.set("n", "<leader>hb", function()
          gs.blame_line({ full = true })
        end, opts("Blame line"))
        vim.keymap.set("n", "<leader>hd", gs.diffthis, opts("Diff this"))
        vim.keymap.set("n", "<leader>hD", function()
          gs.diffthis("~")
        end, opts("Diff this (~)"))
        vim.keymap.set("n", "<leader>htb", gs.toggle_current_line_blame, opts("Toggle line blame"))
        vim.keymap.set("n", "<leader>htd", gs.toggle_deleted, opts("Toggle deleted"))
      end,
    },
  },


  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    config = function()
      require("conform").setup({
        formatters_by_ft = {
          go = { "goimports", "gofumpt" },
          lua = { "stylua" },
          javascript = { "prettier" },
          typescript = { "prettier" },
          javascriptreact = { "prettier" },
          typescriptreact = { "prettier" },
          json = { "prettier" },
          yaml = { "prettier" },
          html = { "prettier" },
          css = { "prettier" },
          c = { "clang-format" },
          cpp = { "clang-format" },
          java = { "google-java-format" },
        },
        format_on_save = {
          timeout_ms = 3000,
          lsp_format = "fallback",
        },
      })
    end,
  },

  -- Go tooling: :GoIfErr, :GoFillStruct, :GoAddTag, :GoTestFunc, etc.
  -- lsp_cfg=false because gopls is configured in after/plugin/lsp.lua.
  {
    "ray-x/go.nvim",
    dependencies = { "ray-x/guihua.lua", "neovim/nvim-lspconfig", "nvim-treesitter/nvim-treesitter" },
    ft = { "go", "gomod" },
    config = function()
      require("go").setup({
        lsp_cfg = false,
        lsp_keymaps = false,
        lsp_inlay_hints = { enable = false },
        trouble = true,
        luasnip = true,
      })
    end,
  },

  -- Debugger (DAP) with Go adapter (delve) + auto-opening UI.
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "leoluz/nvim-dap-go",
      { "rcarriga/nvim-dap-ui", dependencies = { "nvim-neotest/nvim-nio" } },
    },
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")
      require("dap-go").setup()
      dapui.setup()

      -- Auto open/close the UI with the debug session
      dap.listeners.before.attach.dapui_config = function() dapui.open() end
      dap.listeners.before.launch.dapui_config = function() dapui.open() end
      dap.listeners.before.event_terminated.dapui_config = function() dapui.close() end
      dap.listeners.before.event_exited.dapui_config = function() dapui.close() end

      vim.keymap.set("n", "<leader>b", dap.toggle_breakpoint, { desc = "DAP: toggle breakpoint" })
      vim.keymap.set("n", "<leader>B", function()
        dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
      end, { desc = "DAP: conditional breakpoint" })
      vim.keymap.set("n", "<F5>", dap.continue, { desc = "DAP: continue/start" })
      vim.keymap.set("n", "<F10>", dap.step_over, { desc = "DAP: step over" })
      vim.keymap.set("n", "<F11>", dap.step_into, { desc = "DAP: step into" })
      vim.keymap.set("n", "<S-F11>", dap.step_out, { desc = "DAP: step out" })
      vim.keymap.set("n", "<F4>", function() require("dap-go").debug_test() end, { desc = "DAP: debug nearest Go test" })
      vim.keymap.set("n", "<F6>", dapui.toggle, { desc = "DAP: toggle UI" })
    end,
  },

  -- Pretty list for diagnostics / references / quickfix.
  {
    "folke/trouble.nvim",
    cmd = "Trouble",
    keys = {
      { "<leader>xx", "<cmd>Trouble diagnostics toggle<CR>", desc = "Trouble: workspace diagnostics" },
      { "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<CR>", desc = "Trouble: buffer diagnostics" },
      { "<leader>xs", "<cmd>Trouble symbols toggle focus=false<CR>", desc = "Trouble: symbols" },
      { "<leader>xr", "<cmd>Trouble lsp toggle focus=false win.position=right<CR>", desc = "Trouble: LSP references/defs" },
      { "<leader>xl", "<cmd>Trouble loclist toggle<CR>", desc = "Trouble: location list" },
      { "<leader>xq", "<cmd>Trouble qflist toggle<CR>", desc = "Trouble: quickfix" },
    },
    opts = {},
  },

  -- Highlight + search TODO/FIXME/HACK/NOTE comments.
  {
    "folke/todo-comments.nvim",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local todo = require("todo-comments")
      todo.setup()
      vim.keymap.set("n", "]t", function() todo.jump_next() end, { desc = "Next todo comment" })
      vim.keymap.set("n", "[t", function() todo.jump_prev() end, { desc = "Previous todo comment" })
      vim.keymap.set("n", "<leader>pt", "<cmd>TodoTelescope<CR>", { desc = "Search todos (Telescope)" })
    end,
  },

  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    config = function()
      local wk = require("which-key")
      wk.setup({
        delay = 300,
        icons = {
          mappings = false,
        },
      })
      wk.add({
        { "<leader>h",  group = "Git hunks" },
        { "<leader>ht", group = "Toggle" },
        { "<leader>g",  group = "Git" },
        { "<leader>l",  group = "Lint" },
        { "<leader>p",  group = "Project/Files" },
        { "<leader>s",  group = "Search/Replace" },
        { "<leader>t",  group = "Terminal" },
        { "<leader>x",  group = "Trouble/Diagnostics" },
        { "<leader>v",  group = "LSP" },
        { "<leader>vc", group = "Code actions" },
        { "<leader>vr", group = "Refactor" },
      })
    end,
  },
}
