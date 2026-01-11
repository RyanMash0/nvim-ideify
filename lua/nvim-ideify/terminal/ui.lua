local M = {}
local state = require('nvim-ideify.terminal.state')

function M.render()
	-- vim.api.nvim_open_term(term_buf, {})
	if vim.bo[state:get_buffer()].buftype ~= 'terminal' then
		vim.api.nvim_buf_call(state:get_buffer(), function () vim.cmd.terminal() end)
	end
end

return M
