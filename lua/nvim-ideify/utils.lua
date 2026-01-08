local M = {}
local state = require('nvim-ideify.state')
local pos = require('nvim-ideify.position')

local function get_modules()
	local config = require('nvim-ideify.config')
	return {
		left = config.options.layout.left.module,
		right = config.options.layout.right.module,
		top = config.options.layout.top.module,
		bottom = config.options.layout.bottom.module,
	}
end

local function get_split_opts(plugin_wins)
	local mods = get_modules()

	if plugin_wins[mods.bottom and mods.bottom.state.window or -1] then
		vim.api.nvim_set_current_win(mods.bottom.state.window)
		return { split = pos.top }
	elseif plugin_wins[mods.top and mods.top.state.window or -1] then
		vim.api.nvim_set_current_win(mods.top.state.window)
		return { split = pos.bottom}
	elseif plugin_wins[mods.right and mods.right.state.window or -1] then
		vim.api.nvim_set_current_win(mods.right.state.window)
		return { split = pos.left }
	elseif plugin_wins[mods.left and mods.left.state.window or -1] then
		vim.api.nvim_set_current_win(mods.left.state.window)
		return { split = pos.right }
	end
end

function M.is_valid(variable, check_type)
	if type(variable) ~= 'number' then return false end
	if check_type == 'window' and not vim.api.nvim_win_is_valid(variable) then
		return false
	end
	if check_type == 'buffer' and not vim.api.nvim_buf_is_valid(variable) then
		return false
	end
	return true
end

local function check_or_make_main_buf()
	local mods = get_modules()
	local left = mods.left
	local right = mods.right
	local top = mods.top
	local bottom = mods.bottom

	local bufs = vim.api.nvim_list_bufs()
	local l_buf_id = left and left.state.buffer or -1
	local r_buf_id = right and right.state.buffer or -1
	local t_buf_id = top and top.state.buffer or -1
	local b_buf_id = bottom and bottom.state.buffer or -1
	local l_buf_exists = M.is_valid(l_buf_id, 'buffer')
	local r_buf_exists = M.is_valid(r_buf_id, 'buffer')
	local t_buf_exists = M.is_valid(t_buf_id, 'buffer')
	local b_buf_exists = M.is_valid(b_buf_id, 'buffer')

	local exclude_bufs = {
		[l_buf_id] = l_buf_exists,
		[r_buf_id] = r_buf_exists,
		[t_buf_id] = t_buf_exists,
		[b_buf_id] = b_buf_exists,
	}

	local check
	for _, buf in ipairs(bufs) do
		check = true
		for key, val in pairs(exclude_bufs) do
			if buf == key and val then
				check = false
				break
			end
		end
		if check then
			return buf
		end
	end
	if not check then
		return vim.api.nvim_create_buf(true, false)
	end
end

function M.check_or_make_main_win()
	if vim.api.nvim_win_is_valid(state.wins.main) then return end

	local mods = get_modules()
	local left = mods.left
	local right = mods.right
	local top = mods.top
	local bottom = mods.bottom

	local wins = vim.api.nvim_tabpage_list_wins(0)
	local l_win_id = left and left.state.window or -1
	local r_win_id = right and right.state.window or -1
	local t_win_id = top and top.state.window or -1
	local b_win_id = bottom and bottom.state.window or -1
	local l_win_exists = M.is_valid(l_win_id, 'window')
	local r_win_exists = M.is_valid(r_win_id, 'window')
	local t_win_exists = M.is_valid(t_win_id, 'window')
	local b_win_exists = M.is_valid(b_win_id, 'window')

	local exclude_wins = {
		[l_win_id] = l_win_exists,
		[r_win_id] = r_win_exists,
		[t_win_id] = t_win_exists,
		[b_win_id] = b_win_exists,
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
		local buf_id = check_or_make_main_buf()
		local win_opts = get_split_opts(exclude_wins)
		state.wins.main = vim.api.nvim_open_win(buf_id, true, win_opts)
		require('nvim-ideify.ui').open()
	end
end

function M.delete_buf(id)
	if id and vim.api.nvim_buf_is_valid(id) then
		vim.api.nvim_buf_delete(id, { force = true, })
	end
end

function M.close_win(id)
	if id and vim.api.nvim_win_is_valid(id) then
		vim.api.nvim_win_close(id, true)
	end
end

return M
