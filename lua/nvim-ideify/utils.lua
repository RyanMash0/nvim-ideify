local M = {}
local state = require('nvim-ideify.state')
local pos = require('nvim-ideify.position')

local function get_split_opts(plugin_wins)
	local mods = M.get_modules()

	if plugin_wins[
		mods.bottom and mods.bottom:get_state():get_window() or -1
		] then
		vim.api.nvim_set_current_win(mods.bottom:get_state():get_window())
		return { split = pos.top }
	elseif plugin_wins[
		mods.top and mods.top:get_state():get_window() or -1
		] then
		vim.api.nvim_set_current_win(mods.top:get_state():get_window())
		return { split = pos.bottom}
	elseif plugin_wins[
		mods.right and mods.right:get_state():get_window() or -1
		] then
		vim.api.nvim_set_current_win(mods.right:get_state():get_window())
		return { split = pos.left }
	elseif plugin_wins[
		mods.left and mods.left:get_state():get_window() or -1
		] then
		vim.api.nvim_set_current_win(mods.left:get_state():get_window())
		return { split = pos.right }
	end
end

local function check_or_make_main_buf()
	local mods = M.get_modules()
	local left = mods.left
	local right = mods.right
	local top = mods.top
	local bottom = mods.bottom

	local bufs = vim.api.nvim_list_bufs()
	local l_buf_id = left and left:get_state():get_buffer() or -1
	local r_buf_id = right and right:get_state():get_buffer() or -1
	local t_buf_id = top and top:get_state():get_buffer() or -1
	local b_buf_id = bottom and bottom:get_state():get_buffer() or -1
	local l_buf_exists = M.buf_valid(l_buf_id)
	local r_buf_exists = M.buf_valid(r_buf_id)
	local t_buf_exists = M.buf_valid(t_buf_id)
	local b_buf_exists = M.buf_valid(b_buf_id)

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

function M.win_valid(id)
	if type(id) ~= 'number' then return false end
	if not vim.api.nvim_win_is_valid(id) then
		return false
	end
	return true
end

function M.buf_valid(id)
	if type(id) ~= 'number' then return false end
	if not vim.api.nvim_buf_is_valid(id) then
		return false
	end
	return true
end

function M.get_modules()
	local config = require('nvim-ideify.config')
	return {
		left = config.options.layout.left.module(),
		right = config.options.layout.right.module(),
		top = config.options.layout.top.module(),
		bottom = config.options.layout.bottom.module(),
	}
end

function M.get_plugin_wins()
	local modules = M.get_modules()
	local left = modules.left
	local right = modules.right
	local top = modules.top
	local bottom = modules.bottom
	return {
		left = left and left:get_state():get_window() or -1,
		right = right and right:get_state():get_window() or -1,
		top = top and top:get_state():get_window() or -1,
		bottom = bottom and bottom:get_state():get_window() or -1,
	}
end

function M.is_plugin_win(win)
	local wins = M.get_plugin_wins()
	local l_win = wins.left
	local r_win = wins.right
	local t_win = wins.top
	local b_win = wins.bottom
	if win == l_win or win == r_win or win == t_win or win == b_win then
		return true
	end
	return false
end

function M.check_or_make_main_win()
	if vim.api.nvim_win_is_valid(state.wins.main) then return end

	local mods = M.get_modules()
	local left = mods.left
	local right = mods.right
	local top = mods.top
	local bottom = mods.bottom

	local wins = vim.api.nvim_tabpage_list_wins(0)
	local l_win_id = left and left:get_state():get_window() or -1
	local r_win_id = right and right:get_state():get_window() or -1
	local t_win_id = top and top:get_state():get_window() or -1
	local b_win_id = bottom and bottom:get_state():get_window() or -1
	local l_win_exists = M.win_valid(l_win_id)
	local r_win_exists = M.win_valid(r_win_id)
	local t_win_exists = M.win_valid(t_win_id)
	local b_win_exists = M.win_valid(b_win_id)

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
	if M.buf_valid(id) then
		vim.api.nvim_buf_delete(id, { force = true, })
	end
end

function M.close_win(id)
	if M.win_valid(id) then
		vim.api.nvim_win_close(id, true)
	end
end

return M
