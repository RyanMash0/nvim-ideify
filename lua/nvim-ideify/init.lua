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
		local utils = require('nvim-ideify.utils')

		local win = vim.api.nvim_get_current_win()

		if not utils.is_plugin_win(win) then
			state.wins.last = win
		end
	end
})

vim.api.nvim_create_autocmd('WinClosed', {
	group = 'IDEify',
	callback = function()
		local utils = require('nvim-ideify.utils')
		local state = require('nvim-ideify.state')

		local win = vim.api.nvim_get_current_win()

		if state.opened and state.active and utils.is_plugin_win(win) then
			ui.show()
		end
	end
})

return M
