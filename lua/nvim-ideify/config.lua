local M = {}
local pos = require('nvim-ideify.position')

M.defaults = {
	layout = {
		left = {
			module = function ()
				return require('nvim-ideify.filetree')
			end,
			width = 30,
		},
		right = {
			module = function ()
				return nil
			end,
			width = 0,
		},
		top = {
			module = function ()
				return require('nvim-ideify.bufferbar')
			end,
			height = 2,
		},
		bottom = {
			module = function ()
				return require('nvim-ideify.terminal')
			end,
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
	require('nvim-ideify.filetree'):get_config().setup(opts.filetree)
	require('nvim-ideify.bufferbar'):get_config().setup(opts.bufferbar)
	require('nvim-ideify.terminal'):get_config().setup(opts.terminal)

	M.options = vim.tbl_deep_extend('force', M.defaults, opts or {})
end

return M
