local M = {}

M.defaults = {
	name_pref_length = 20,
	window = {
		start_opts = {
			style = 'minimal'
		},
		opts = {
			wrap = false,
			winfixbuf = true
		},
	},
	buffer = {
		listed = false,
		scratch = true,
		opts = {
			modifiable = false,
			buflisted = false,
		},
	},
}

M.options = vim.deepcopy(M.defaults)

function M.setup(opts)
	M.options = vim.tbl_deep_extend('force', M.defaults, opts or {})
end

return M
