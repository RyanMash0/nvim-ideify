local M = {}

M.buffer = -1
M.window = -1
M.win_config = {}

M.namespace = vim.api.nvim_create_namespace('IDEifyBufferBar')
M.on_click = nil

return M
