local function ColorMyPencils(color)

    vim.cmd('colorscheme tokyonight-night') -- terafox, carbonfox, duskfox, nightfox
    -- vim.cmd('colorscheme tokyonight') -- day, moon, night storm 
    -- vim.cmd('colorscheme catppuccin') -- frappe, latte, macchiato, mocha
    -- kanagawa dragon, lotus, wave
    -- rose-pine main, moon

    vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
    vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })


end

vim.api.nvim_create_autocmd("User", {
    pattern = "LazyDone",
    callback = function()
        ColorMyPencils()
    end,
})

