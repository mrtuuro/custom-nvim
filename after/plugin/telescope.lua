local ok, builtin = pcall(require, 'telescope.builtin')
if not ok then return end
vim.keymap.set('n', '<leader>pf', builtin.find_files, { desc = "Find files" })
vim.keymap.set('n', '<C-p>', builtin.git_files, { desc = "Find git files" })
vim.keymap.set('n', '<leader>ps', function()
	builtin.grep_string({ search = vim.fn.input("Grep > ") })
end, { desc = "Grep string (prompted)" })
vim.keymap.set('n', '<leader>pg', builtin.live_grep, { desc = "Live grep" })
vim.keymap.set('n', '<leader>pb', builtin.buffers, { desc = "Find buffers" })
vim.keymap.set('n', '<leader>pr', builtin.resume, { desc = "Resume last picker" })
vim.keymap.set('n', '<leader>pd', builtin.diagnostics, { desc = "Diagnostics list" })
vim.keymap.set('n', '<leader>vh', builtin.help_tags, { desc = "Search help tags" })

