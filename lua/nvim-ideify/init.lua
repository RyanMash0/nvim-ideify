local M = {}
local config = require('nvim-ideify.config')
local ui = require('nvim-ideify.ui')
local filetree = require('nvim-ideify.filetree')
local bufferbar = require('nvim-ideify.bufferbar')

M.open = ui.open
M.close = ui.close
M.hide = ui.hide
M.show = ui.show
M.toggle = function()
	local state = require('nvim-ideify.state')
	if state.active then
		ui.hide()
	elseif not state.active and state.opened then
		ui.show()
	elseif not state.active and not state.opened then
		ui.open()
	end
end
M.reset = ui.reset

M.refresh_tree = filetree:get_ui().render
M.refresh_bufferbar = bufferbar:get_ui().render

function M.setup(opts)
	config.setup(opts)
	require('nvim-ideify.state').wins.main = vim.api.nvim_get_current_win()

end

vim.api.nvim_create_augroup('IDEify', { clear = true })
vim.api.nvim_create_autocmd('WinEnter', {
	group = 'IDEify',
	callback = function()
		local state = require('nvim-ideify.state')

		local win = vim.api.nvim_get_current_win()
		local left = config.options.layout.left.module()
		local right = config.options.layout.right.module()
		local top = config.options.layout.top.module()
		local bottom = config.options.layout.bottom.module()

		local l_win = left and left:get_state():get_window() or -1
		local r_win = right and right:get_state():get_window() or -1
		local t_win = top and top:get_state():get_window() or -1
		local b_win = bottom and bottom:get_state():get_window() or -1
		if win ~= l_win and win ~= r_win and win ~= t_win and win ~= b_win then
			state.wins.last = win
		end
	end
})

vim.api.nvim_create_autocmd('WinClosed', {
	group = 'IDEify',
	callback = function()
		local state = require('nvim-ideify.state')
		if state.opened and state.active then
			ui.show()
		end
	end
})

return M
