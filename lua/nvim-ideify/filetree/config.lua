local M = {}

M.defaults = {
	cache = true,
	header = nil,
	window = {
		start_opts = {},
		opts = {
			wrap = false,
			number = false,
			winfixbuf = true,
		},
	},
	buffer = {
		listed = false,
		scratch = true,
		opts = {
			modifiable = false,
		},
	},
}

M.options = vim.deepcopy(M.defaults)

function M.setup(opts)
	M.options = vim.tbl_deep_extend('force', M.defaults, opts or {})
end

return M

