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

vim.api.nvim_create_augroup('IDEify', { clear = true })
vim.api.nvim_create_autocmd('WinEnter', {
	group = 'IDEify',
	callback = vim.schedule_wrap(function()
		local state = require('nvim-ideify.state')

		local win = vim.api.nvim_get_current_win()
		local left = config.options.layout.left.module
		local right = config.options.layout.right.module
		local top = config.options.layout.top.module
		local bottom = config.options.layout.bottom.module

		local l_win = left and left.state.window or -1
		local r_win = right and right.state.window or -1
		local t_win = top and top.state.window or -1
		local b_win = bottom and bottom.state.window or -1
		if win ~= l_win and win ~= r_win and win ~= t_win and win ~= b_win then
			state.wins.last = win
		end
	end)
})

return M
