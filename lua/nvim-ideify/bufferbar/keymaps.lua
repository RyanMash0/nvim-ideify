local M = {}
local state = require('nvim-ideify.bufferbar.state')
local ui = require('nvim-ideify.bufferbar.ui')

function M.setup()
	local opts = { buffer = state:get_buffer(), expr = true, remap = false }
	local switch = vim.schedule_wrap(ui.switch_buffer)

	vim.keymap.set('n', '<CR>', switch, opts)
	vim.keymap.set('n', '<C-M>', switch, opts)

	state:set_on_click(switch)

	local function generate_buf_scroll(flags)
		return function()
			local pos = vim.fn.col('.')
			vim.fn.search('[^ \\u2502]\\+', flags, vim.fn.line('.'))
			local new_pos = vim.fn.col('.')
			if new_pos == pos and new_pos > 3 then
				vim.cmd.normal('$b')
			elseif new_pos == pos then
				vim.cmd.normal('0w')
			end
		end
	end

	opts.expr = nil
	vim.keymap.set('n', 'w', generate_buf_scroll('W'), opts)
	vim.keymap.set('n', 'b', generate_buf_scroll('Wb'), opts)
	vim.keymap.set('n', '<S-ScrollWheelUp>', 'w', opts)
	vim.keymap.set('n', '<S-ScrollWheelDown>', 'b', opts)
end

return M
