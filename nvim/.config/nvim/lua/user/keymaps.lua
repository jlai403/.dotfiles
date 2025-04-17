local keymap = vim.keymap.set
local opts = { noremap = true, silent = true }

-- remap leader key
keymap("n", "<Space>", "", opts)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- keymaps for coding
keymap("n", "<leader>cl", "oconsole.log();<Left><Left>")
keymap("n", "<leader>nl", "o<ESC>")
keymap("n", "<leader>nla", "O<ESC>")
