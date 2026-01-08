local M = {}
local state = require('nvim-ideify.terminal.state')

function M.render()
	-- vim.api.nvim_open_term(term_buf, {})
	if vim.bo[state.buffer].buftype ~= 'terminal' then
		vim.api.nvim_buf_call(state.buffer, function () vim.cmd.terminal() end)
	end
end

return M
