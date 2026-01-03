local M = {}
local config = require('nvim-ideify.config')
local ui = require('nvim-ideify.ui')
local tree = require('nvim-ideify.tree')
local bufferbar = require('nvim-ideify.bufferbar')

M.open = ui.make_layout
M.close = ui.close_layout

M.refresh_tree = tree.render
M.refresh_bufferbar = bufferbar.render

function M.setup(opts)
	config.setup(opts)
	require('nvim-ideify.state').wins.main = vim.api.nvim_get_current_win()
end

return M
