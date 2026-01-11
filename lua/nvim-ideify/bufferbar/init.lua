local M = {}

function M:get_ui()
	return require('nvim-ideify.bufferbar.ui')
end

function M:get_config()
	return require('nvim-ideify.bufferbar.config')
end

function M:get_state()
	return require('nvim-ideify.bufferbar.state')
end

function M:get_keymaps()
	return require('nvim-ideify.bufferbar.keymaps')
end

vim.api.nvim_create_augroup('IDEifyBufferBar', { clear = true })
vim.api.nvim_create_autocmd('BufEnter', {
	group = 'IDEifyBufferBar',
	callback = function()
		vim.defer_fn(M:get_ui().render, 10)
	end
})

return M
