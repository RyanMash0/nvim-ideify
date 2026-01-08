local M = {}

M.ui = require('nvim-ideify.bufferbar.ui')
M.config = require('nvim-ideify.bufferbar.config')
M.state = require('nvim-ideify.bufferbar.state')
M.keymaps = require('nvim-ideify.bufferbar.keymaps')

vim.api.nvim_create_augroup('IDEifyBufferBar', { clear = true })
vim.api.nvim_create_autocmd('BufEnter', {
	group = 'IDEifyBufferBar',
	callback = function()
		vim.defer_fn(M.ui.render, 10)
	end
})

return M
