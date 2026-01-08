local M = {}
local state = require('nvim-ideify.filetree.state')
local ui = require('nvim-ideify.filetree.ui')

function M.setup()
	local opts = { buffer = state.buffer, expr = true, remap = false }
	local action = vim.schedule_wrap(ui.action)
	local make = vim.schedule_wrap(ui.render)
	local descend = vim.schedule_wrap(ui.descend)
	local ascend = vim.schedule_wrap(ui.ascend)

	vim.keymap.set('n', 'r', make, opts)
	vim.keymap.set('n', '-', ascend, opts)
	vim.keymap.set('n', '<CR>', action, opts)
	vim.keymap.set('n', '<S-CR>', descend, opts)
	vim.keymap.set('n', '<C-M>', action, opts)
	vim.keymap.set('n', '<S-C-M>', descend, opts)
	vim.keymap.set('n', '<LeftMouse>', function ()
		if vim.fn.getmousepos().winid ~= state.window then
			return '<LeftMouse>' end
		action()
		return '<LeftMouse>'
	end, opts)
end

return M
