vim.o.timeout = true
vim.o.timeoutlen = 1000

require "user.keymaps"

if vim.g.vscode then
  -- VSCode Neovim
  require "user.vscode_keymaps"
else
  -- Ordinary Neovim
end

require "config.lazy"