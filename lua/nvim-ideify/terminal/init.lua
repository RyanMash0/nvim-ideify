local M = {}

function M:get_ui()
	return require('nvim-ideify.terminal.ui')
end

function M:get_config()
	return require('nvim-ideify.terminal.config')
end

function M:get_state()
	return require('nvim-ideify.terminal.state')
end

function M:get_keymaps()
	return require('nvim-ideify.terminal.keymaps')
end

return M
