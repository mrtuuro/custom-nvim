-- Keymaps applied when an LSP attaches
local lsp_attach = function(_, bufnr)

  vim.keymap.set("n", "gd", vim.lsp.buf.definition, { buffer = bufnr, desc = "Go to definition" })
  vim.keymap.set("n", "gD", vim.lsp.buf.implementation, { buffer = bufnr, desc = "Go to implementation" })
  vim.keymap.set("n", "K", vim.lsp.buf.hover, { buffer = bufnr, desc = "Hover info" })
  vim.keymap.set("n", "<leader>vws", vim.lsp.buf.workspace_symbol, { buffer = bufnr, desc = "Workspace symbol search" })
  vim.keymap.set("n", "<leader>vd", vim.diagnostic.open_float, { buffer = bufnr, desc = "Open diagnostic float" })
  vim.keymap.set("n", "]d", function() vim.diagnostic.jump({ count = 1, float = true }) end, { buffer = bufnr, desc = "Next diagnostic" })
  vim.keymap.set("n", "[d", function() vim.diagnostic.jump({ count = -1, float = true }) end, { buffer = bufnr, desc = "Previous diagnostic" })

  vim.keymap.set("n", "<leader>vca", vim.lsp.buf.code_action, { buffer = bufnr, desc = "Code actions" })
  vim.keymap.set("n", "<leader>vrr", vim.lsp.buf.references, { buffer = bufnr, desc = "Show references" })

  vim.keymap.set("n", "<leader>vrn", vim.lsp.buf.rename, { buffer = bufnr, desc = "Rename symbol" })
  vim.keymap.set("i", "<C-h>", vim.lsp.buf.signature_help, { buffer = bufnr, desc = "Signature help" })
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
local luasnip = require('luasnip')
cmp.setup({
  sources = {
    { name = 'nvim_lsp' },
    { name = 'luasnip' },
    { name = 'buffer' },
    { name = 'path' },
  },
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },
  mapping = cmp.mapping.preset.insert({
    ['<C-p>'] = cmp.mapping.select_prev_item(),
    ['<C-n>'] = cmp.mapping.select_next_item(),
    ['<C-y>'] = cmp.mapping.confirm({ select = true }),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<Tab>'] = cmp.mapping(function(fallback)
      if luasnip.expand_or_locally_jumpable() then
        luasnip.expand_or_jump()
      else
        fallback()
      end
    end, { 'i', 's' }),
    ['<S-Tab>'] = cmp.mapping(function(fallback)
      if luasnip.locally_jumpable(-1) then
        luasnip.jump(-1)
      else
        fallback()
      end
    end, { 'i', 's' }),
  }),
})
