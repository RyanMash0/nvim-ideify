local M = {}

M.active = false
M.equalalways = vim.o.equalalways

M.wins = {
	main = -1,
	last = -1,
}

return M
