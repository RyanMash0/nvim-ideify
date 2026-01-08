local M = {}

M.defaults = {
	window = {
		start_opts = {},
		opts = {
			winfixbuf = true,
		},
	},
	buffer = {
		listed = false,
		scratch = true,
		opts = {
			buflisted = false,
		},
	},
}

M.options = vim.deepcopy(M.defaults)

function M.setup(opts)
	M.options = vim.tbl_deep_extend('force', M.defaults, opts or {})
end

return M

