-- Keymaps applied when an LSP attaches
local lsp_attach = function(_, bufnr)
  local opts = { buffer = bufnr }

  vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
  vim.keymap.set("n", "gD", vim.lsp.buf.implementation, opts)
  vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
  vim.keymap.set("n", "<leader>vws", vim.lsp.buf.workspace_symbol, opts)
  vim.keymap.set("n", "<leader>vd", vim.diagnostic.open_float, opts)
  vim.keymap.set("n", "[d", vim.diagnostic.goto_next, opts)
  vim.keymap.set("n", "]d", vim.diagnostic.goto_prev, opts)

  vim.keymap.set("n", "<leader>vca", vim.lsp.buf.code_action, { buffer = bufnr, desc = "Code actions" })
  vim.keymap.set("n", "<leader>vrr", vim.lsp.buf.references, { buffer = bufnr, desc = "Show references" })

  vim.keymap.set("n", "<leader>vrn", vim.lsp.buf.rename, opts)
  vim.keymap.set("i", "<C-h>", vim.lsp.buf.signature_help, opts)
end

local capabilities = require('cmp_nvim_lsp').default_capabilities()

vim.lsp.config('gopls', {
  cmd = { vim.fn.exepath("gopls") },
  on_attach = lsp_attach,
  capabilities = capabilities,
  cmd_env = {
    GOFLAGS = "-mod=mod",
  },
  settings = {
    gopls = {
      buildFlags = { "-tags=integration" },
      analyses = {
        unusedparams = true,
        unreachable = true,
        nilness = true,
        shadow = true,
      },
      staticcheck = true,
      usePlaceholders = false,
      gofumpt = true,
    },
  },
})

vim.lsp.config('lua_ls', {
  on_attach = lsp_attach,
  capabilities = capabilities,
})

vim.lsp.config('vtsls', {
  on_attach = lsp_attach,
  capabilities = capabilities,
})

vim.lsp.enable({ 'gopls', 'lua_ls', 'vtsls', 'jdtls', 'clangd' })

local cmp = require('cmp')
cmp.setup({
  sources = {
    { name = 'nvim_lsp' },
    { name = 'buffer' },
  },
  snippet = {
    expand = function(args)
      vim.snippet.expand(args.body)
    end,
  },
  mapping = cmp.mapping.preset.insert({
    ['<C-p>'] = cmp.mapping.select_prev_item(),
    ['<C-n>'] = cmp.mapping.select_next_item(),
    ['<C-y>'] = cmp.mapping.confirm({ select = true }),
    ['<C-Space>'] = cmp.mapping.complete(),
  }),
})
