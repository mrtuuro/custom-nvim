-- Keymaps applied when an LSP attaches
local lsp_attach = function(_, bufnr)
  -- Prefer Telescope pickers (preview + <leader>pr resume); fall back to raw
  -- vim.lsp.buf.* if Telescope isn't available. Single results still jump
  -- straight through; multiple results open a previewable list.
  local tb_ok, tb = pcall(require, "telescope.builtin")
  local function map(lhs, fn, desc)
    vim.keymap.set("n", lhs, fn, { buffer = bufnr, desc = desc })
  end

  -- Navigation: jump out with these, jump BACK with <C-o>, forward with <C-i>
  map("gd", tb_ok and tb.lsp_definitions or vim.lsp.buf.definition, "Go to definition")
  map("gD", tb_ok and tb.lsp_implementations or vim.lsp.buf.implementation, "Go to implementation")
  map("gy", tb_ok and tb.lsp_type_definitions or vim.lsp.buf.type_definition, "Go to type definition")
  map("<leader>vrr", tb_ok and tb.lsp_references or vim.lsp.buf.references, "References (who uses this)")
  map("<leader>vi", tb_ok and tb.lsp_incoming_calls or vim.lsp.buf.incoming_calls, "Incoming calls (who calls this)")
  map("<leader>vws", tb_ok and tb.lsp_dynamic_workspace_symbols or vim.lsp.buf.workspace_symbol, "Workspace symbol search")
  if tb_ok then
    map("<leader>vs", tb.lsp_document_symbols, "Document symbols (jump in file)")
  end

  map("K", vim.lsp.buf.hover, "Hover info")
  map("<leader>vd", vim.diagnostic.open_float, "Open diagnostic float")
  map("]d", function() vim.diagnostic.jump({ count = 1, float = true }) end, "Next diagnostic")
  map("[d", function() vim.diagnostic.jump({ count = -1, float = true }) end, "Previous diagnostic")
  map("<leader>vca", vim.lsp.buf.code_action, "Code actions")
  map("<leader>vrn", vim.lsp.buf.rename, "Rename symbol")
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
