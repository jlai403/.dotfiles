local keymap = vim.keymap.set
local opts = { noremap = true, silent = true }

-- yank to system clipboard
keymap({"n", "v"}, "<leader>c", '"+y', opts)
-- paste from system clipboard
keymap({"n", "v"}, "<leader>v", '"+p', opts)

-- better indent handling
keymap("v", "<", "<gv", opts)
keymap("v", ">", ">gv", opts)

-- move text up and down
keymap("v", "J", ":m .+1<CR>==", opts)
keymap("v", "K", ":m .-2<CR>==", opts)
keymap("x", "J", ":move '>+1<CR>gv-gv", opts)
keymap("x", "K", ":move '<-2<CR>gv-gv", opts)

-- paste preserves primal yanked piece
keymap("v", "p", '"_dP', opts)

-- removes highlighting after escaping vim search
keymap("n", "<Esc>", "<Esc>:noh<CR>", opts)

-- general keymaps
keymap("n", "gr", "<cmd>lua require('vscode').action('editor.action.referenceSearch.trigger')<CR>")
keymap("n", "gt", "<cmd>lua require('vscode').action('editor.action.goToTypeDefinition')<CR>")
keymap({"n", "v"}, "<leader>t", "<cmd>lua require('vscode').action('workbench.action.terminal.toggleTerminal')<CR>")
keymap({"n", "v"}, "<leader>b", "<cmd>lua require('vscode').action('editor.debug.action.toggleBreakpoint')<CR>")
keymap({"n", "v"}, "<leader>d", "<cmd>lua require('vscode').action('editor.action.showHover')<CR>")
keymap({"n", "v"}, "<leader>a", "<cmd>lua require('vscode').action('editor.action.quickFix')<CR>")
keymap({"n", "v"}, "<leader>sp", "<cmd>lua require('vscode').action('workbench.actions.view.problems')<CR>")
keymap({"n", "v"}, "<leader>cn", "<cmd>lua require('vscode').action('notifications.clearAll')<CR>")
keymap({"n", "v"}, "<leader>ff", "<cmd>lua require('vscode').action('workbench.action.quickOpen')<CR>")
keymap({"n", "v"}, "<leader>cp", "<cmd>lua require('vscode').action('workbench.action.showCommands')<CR>")
keymap({"n", "v"}, "<leader>pr", "<cmd>lua require('vscode').action('code-runner.run')<CR>")
keymap({"n", "v"}, "<leader>fd", "<cmd>lua require('vscode').action('editor.action.formatDocument')<CR>")

-- split tab keymaps
keymap({"n", "v"}, "<leader>svl", "<cmd>lua require('vscode').action('workbench.action.splitEditorRight')<CR>")
keymap({"n", "v"}, "<leader>svj", "<cmd>lua require('vscode').action('workbench.action.splitEditorDown')<CR>")

keymap({"n", "v"}, "<leader>fej", "<cmd>lua require('vscode').action('workbench.action.focusBelowGroup')<CR>")
keymap({"n", "v"}, "<leader>fek", "<cmd>lua require('vscode').action('workbench.action.focusAboveGroup')<CR>")
keymap({"n", "v"}, "<leader>feh", "<cmd>lua require('vscode').action('workbench.action.focusLeftGroup')<CR>")
keymap({"n", "v"}, "<leader>fel", "<cmd>lua require('vscode').action('workbench.action.focusRightGroup')<CR>")

-- project manager keymaps
keymap({"n", "v"}, "<leader>pa", "<cmd>lua require('vscode').action('projectManager.saveProject')<CR>")
keymap({"n", "v"}, "<leader>po", "<cmd>lua require('vscode').action('projectManager.listProjects')<CR>")
keymap({"n", "v"}, "<leader>ve", "<cmd>lua require('vscode').action('projectManager.editProjects')<CR>")

-- keymaps for tests & debugging
keymap({"n", "v"}, "<leader>rt", "<cmd>lua require('vscode').action('testing.runAtCursor')<CR>")
keymap({"n", "v"}, "<leader>ra", "<cmd>lua require('vscode').action('testing.runAll')<CR>")
keymap({"n", "v"}, "<leader>rd", "<cmd>lua require('vscode').action('testing.debugAtCursor')<CR>")
keymap({"n", "v"}, "<leader>tr", "<cmd>lua require('vscode').action('workbench.panel.testResults.view.focus')<CR>")