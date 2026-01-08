local M = {}
local config = require('nvim-ideify.config')
local ui = require('nvim-ideify.ui')
local filetree = require('nvim-ideify.filetree')
local bufferbar = require('nvim-ideify.bufferbar')

M.open = ui.open
M.close = ui.close
M.toggle = function()
	local state = require('nvim-ideify.state')
	if state.active then
		ui.close()
	else
		ui.open()
	end
end

M.refresh_tree = filetree.ui.render
M.refresh_bufferbar = bufferbar.ui.render

function M.setup(opts)
	config.setup(opts)
	require('nvim-ideify.state').wins.main = vim.api.nvim_get_current_win()
end

return M
