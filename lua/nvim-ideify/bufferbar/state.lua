local M = {}

M.buffer = -1
M.window = -1
M.namespace = vim.api.nvim_create_namespace('IDEifyBufferBar')
M.on_click = nil

return M
