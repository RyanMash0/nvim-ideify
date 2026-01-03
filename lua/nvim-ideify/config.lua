local M = {}

M.defaults = {
	file_tree = {
		win_opts = {
			vertical = true,
			width = 30,
			split = 'left',
		},
		cache = true,
		header = nil,
	},
	buffer_bar = {
		win_opts = {
			height = 2,
			split = 'above',
			style = 'minimal',
		},
		name_max_length = 20,
	},
	terminal = {
		win_opts = {
			height = 10,
			split = 'below',
		},
	},
}

M.options = vim.deepcopy(M.defaults)

function M.setup(opts)
	M.options = vim.tbl_deep_extend('force', M.defaults, opts or {})
end

return M
