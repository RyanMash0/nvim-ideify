if vim.g.loader_nvim_ideify then
	return
end
vim.g.loaded_nvim_ideify = 1

vim.api.nvim_create_user_command(
	'IDEifyOpen',
	require('nvim-ideify').open,
	{ nargs = 0 }
)

vim.api.nvim_create_user_command(
	'IDEifyClose',
	require('nvim-ideify').close,
	{ nargs = 0 }
)

vim.api.nvim_create_user_command(
	'IDEifyToggle',
	require('nvim-ideify').toggle,
	{ nargs = 0 }
)

vim.api.nvim_create_user_command(
	'IDEifyRefreshFileTree',
	require('nvim-ideify').refresh_tree,
	{ nargs = 0 }
)

vim.api.nvim_create_user_command(
	'IDEifyRefreshBufferBar',
	require('nvim-ideify').refresh_bufferbar,
	{ nargs = 0 }
)
