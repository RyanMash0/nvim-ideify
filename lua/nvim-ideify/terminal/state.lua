local M = {}

M.buffer = -1
M.window = -1
M.win_config = {}

M.namespace = vim.api.nvim_create_namespace('IDEifyTerminal')

return M
