-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Enter between {} () [] puts the closing bracket on its own dedented line
vim.keymap.set("i", "<CR>", function()
    local line = vim.api.nvim_get_current_line()
    local col = vim.api.nvim_win_get_cursor(0)[2]
    local pair = line:sub(col, col + 1)
    if pair == "{}" or pair == "()" or pair == "[]" then
        return "<CR><C-d><Esc>O"
    end
    return "<CR>"
end, { expr = true, desc = "Smart bracket newline" })
