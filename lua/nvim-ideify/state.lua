local M = {}

M.active = false
M.equalalways = vim.o.equalalways

M.wins = {
	main = -1,
	file_tree = -1,
	buffer_bar = -1,
	terminal = -1,
}

M.bufs = {
	file_tree = -1,
	buffer_bar = -1,
	terminal = -1,
}

M.namespaces = {
	file_tree = vim.api.nvim_create_namespace('IDEifyFileTree'),
	buffer_bar = vim.api.nvim_create_namespace('IDEifyBufferBar'),
}

M.tree = {
	header_height = 0,
}

return M
