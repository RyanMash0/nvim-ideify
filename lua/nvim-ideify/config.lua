local M = {}
local pos = require('nvim-ideify.position')

M.defaults = {
	layout = {
		left = {
			module = require('nvim-ideify.filetree'),
			width = 30,
		},
		right = {
			module = nil,
			width = 0,
		},
		top = {
			module = require('nvim-ideify.bufferbar'),
			height = 2,
		},
		bottom = {
			module = require('nvim-ideify.terminal'),
			height = 10,
		},
	},
	split_order = {
		first = pos.left,
		second = pos.right,
		third = pos.top,
		fourth = pos.bottom,
	},
}

M.options = vim.deepcopy(M.defaults)

function M.setup(opts)
	require('nvim-ideify.filetree.config').setup(opts.filetree)
	require('nvim-ideify.bufferbar.config').setup(opts.bufferbar)
	require('nvim-ideify.terminal.config').setup(opts.terminal)

	M.options = vim.tbl_deep_extend('force', M.defaults, opts or {})
end

return M
