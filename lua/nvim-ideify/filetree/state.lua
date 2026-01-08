local M = {}

M.buffer = -1
M.window = -1

M.namespace = vim.api.nvim_create_namespace('IDEifyFileTree')
M.header_height = 0

return M
