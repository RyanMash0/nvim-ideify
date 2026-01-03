local M = {}
local state = require('nvim-ideify.state')

local function get_split_opts(plugin_wins)
	if plugin_wins[state.wins.terminal] then
		vim.api.nvim_set_current_win(state.wins.terminal)
		return { split = 'above' }
	elseif plugin_wins[state.wins.file_tree] then
		vim.api.nvim_set_current_win(state.wins.file_tree)
		return { split = 'right' }
	elseif plugin_wins[state.wins.buffer_bar] then
		vim.api.nvim_set_current_win(state.wins.buffer_bar)
		return { split = 'below' }
	end
end

local function is_valid(variable, check_type)
	if type(variable) ~= 'number' then return false end
	if check_type == 'window' and not vim.api.nvim_win_is_valid(variable) then
		return false
	end
	if check_type == 'buffer' and not vim.api.nvim_buf_is_valid(variable) then
		return false
	end
	return true
end

function M.check_or_make_main_win()
	if vim.api.nvim_win_is_valid(state.wins.main) then return end

	local wins = vim.api.nvim_tabpage_list_wins(0)
	local ex_win_id = state.wins.file_tree
	local term_win_id = state.wins.terminal
	local buf_bar_win_id = state.wins.buffer_bar
	local ex_win_exists = is_valid(ex_win_id, 'window')
	local term_win_exists = is_valid(term_win_id, 'window')
	local buf_bar_win_exists = is_valid(buf_bar_win_id, 'window')

	local exclude_wins = {
		[ex_win_id] = ex_win_exists,
		[term_win_id] = term_win_exists,
		[buf_bar_win_id] = buf_bar_win_exists,
	}

	local check
	for _, win in ipairs(wins) do
		check = true
		for key, val in pairs(exclude_wins) do
			if win == key and val then
				check = false
				break
			end
		end
		if check then
			state.wins.main = win
			break
		end
	end
	if not check then
		local bufId = vim.api.nvim_create_buf(true, false)
		local win_opts = get_split_opts(exclude_wins)
		state.wins.main = vim.api.nvim_open_win(bufId, true, win_opts)
	end
end

return M
