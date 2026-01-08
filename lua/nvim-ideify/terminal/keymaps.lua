local M = {}
local state = require('nvim-ideify.terminal.state')

function M.setup()
	local opts = { buffer = state.buffer, remap = false }
	vim.keymap.set('t', '<Esc>', '<C-\\><C-n>', opts)
end

return M
