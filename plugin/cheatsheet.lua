-- Quick keymap cheatsheet in a floating window.
-- Open: <leader>?  or  :Cheatsheet   ·   Close: q / <Esc>

local function open_cheatsheet()
  local path = vim.fn.stdpath("config") .. "/CHEATSHEET.md"
  if vim.fn.filereadable(path) == 0 then
    vim.notify("CHEATSHEET.md not found", vim.log.levels.WARN, { title = "Cheatsheet" })
    return
  end

  local lines = vim.fn.readfile(path)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  vim.bo[buf].filetype = "markdown"
  vim.bo[buf].modifiable = false
  vim.bo[buf].buftype = "nofile"

  local width = math.min(86, vim.o.columns - 4)
  local height = math.min(#lines + 1, vim.o.lines - 4)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - height) / 2),
    style = "minimal",
    border = "rounded",
    title = " Cheatsheet ",
    title_pos = "center",
  })
  vim.wo[win].wrap = false
  vim.wo[win].cursorline = true

  for _, key in ipairs({ "q", "<Esc>" }) do
    vim.keymap.set("n", key, "<cmd>close<CR>", { buffer = buf, nowait = true, silent = true })
  end
end

vim.api.nvim_create_user_command("Cheatsheet", open_cheatsheet, {})
vim.keymap.set("n", "<leader>?", open_cheatsheet, { desc = "Open keymap cheatsheet" })
