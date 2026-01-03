local M = {}
local config = require('nvim-ideify.config')
local state = require('nvim-ideify.state')
local utils = require('nvim-ideify.utils')

local function truncate_end(str, num)
	if #str <= num then return str end
	return str:sub(num - 3) .. '...'
end

local function truncate_middle(str, num)
	if #str <= num then return str end
	if str:match('^%.//?[^/]+/$') then return str:gsub('%.//', '/') end
	if str:match('^%.//?[^/]+/[^/]+/$') then return str:gsub('%.//', '/') end
	local prefix = str:match('^%./[^/]+/') or ''
	if str:match('^%.//[^/]') then prefix = '/' end
	local suffix = str:match('/[^/]+/$') or ''
	return prefix .. '...' .. suffix
end

local function extend_length(str, num)
	if #str == num then return str end
	for _ = 1, num - #str do
		str = str .. ' '
	end
	return str
end

function M.switch_buffer()
	local buf_id = state.bufs.buffer_bar
	local win_id = state.wins.buffer_bar
	local cur_col = vim.api.nvim_win_get_cursor(win_id)[2]
	local buffer_info = vim.b[buf_id].buffer_info
	local switch_buf
	for key, val in pairs(buffer_info) do
		if val ~= vim.NIL and cur_col >= val.first and cur_col <= val.last then
			switch_buf = key
			break
		end
	end
	utils.check_or_make_main_win()
	vim.api.nvim_win_set_buf(state.wins.main, switch_buf)
end

function M.highlight()
	local buf_id = state.bufs.buffer_bar
	local ns = state.namespaces.buffer_bar
	vim.api.nvim_buf_clear_namespace(buf_id, ns, 0, -1)
	utils.check_or_make_main_win()
	local main_win = state.wins.main
	local cur_buf = vim.api.nvim_win_get_buf(main_win)
	local hl_region = vim.b[buf_id].buffer_info[cur_buf]
	local hl_group = vim.api.nvim_get_hl_id_by_name('TabLineSel')
	if not hl_region then return end
	vim.api.nvim_buf_set_extmark(buf_id, ns, 0, hl_region.first, {
		end_col = hl_region.last,
		hl_group = hl_group
	})
	vim.api.nvim_buf_set_extmark(buf_id, ns, 1, hl_region.first, {
		end_col = hl_region.last,
		hl_group = hl_group
	})
end

function M.render()
	local buf_id = state.bufs.buffer_bar
	if not buf_id or not vim.api.nvim_buf_is_valid(buf_id) then return end
	local buffers = vim.api.nvim_list_bufs()
	local normal_buffers = {}
	local term_buffers = {}
	for _, buf in ipairs(buffers) do
		if vim.bo[buf].buflisted then
			table.insert(normal_buffers, buf)
		end

		if vim.bo[buf].buftype == 'terminal' then
			table.insert(term_buffers, buf)
		end
	end

	local buffer_info = {}
	local buf_name
	local file_name
	local dir_name
	local file_str = ''
	local dir_str = ''
	local truncate_len = config.options.buffer_bar.name_max_length
	local max_len
	for _, buf in ipairs(normal_buffers) do
		buf_name = vim.api.nvim_buf_get_name(buf)

		file_name = buf_name:match('[^/]+$') or ''
		file_name = truncate_end(file_name, truncate_len)

		dir_name = buf_name:gsub(vim.fs.abspath('.') .. '/', '')
		dir_name = './' .. dir_name:gsub('[^/]+$', '')
		dir_name = truncate_middle(dir_name, #file_name)

		max_len = math.max(#dir_name, #file_name)

		file_name = extend_length(file_name, max_len)
		dir_name = extend_length(dir_name, max_len)

		buffer_info[buf] = { first = #file_str, last = #file_str + max_len + 2 }
		file_str = file_str .. ' ' .. file_name .. ' \u{2502}'
		dir_str = dir_str .. ' ' .. dir_name .. ' \u{2502}'
	end

	vim.b[buf_id].buffer_info = buffer_info
	vim.bo[buf_id].modifiable = true
	vim.api.nvim_buf_set_lines(buf_id, 0, -1, true, {dir_str, file_str})
	vim.bo[buf_id].modifiable = false
	M.highlight()
end

return M
