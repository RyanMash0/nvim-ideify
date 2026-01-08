local M = {}
local state = require('nvim-ideify.terminal.state')

function M.render()
	-- vim.api.nvim_open_term(term_buf, {})
	vim.api.nvim_buf_call(state.buffer, function () vim.cmd.terminal() end)
end

return M
