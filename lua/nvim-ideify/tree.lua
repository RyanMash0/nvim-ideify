local M = {}
local config = require('nvim-ideify.config')
local state = require('nvim-ideify.state')
local utils = require('nvim-ideify.utils')
local bufferbar = require('nvim-ideify.bufferbar')

local function generate_tree_action(buf_id, ex_table, line, func)
	vim.bo[buf_id].modifiable = true
	vim.b[buf_id].explorer_indent = func(buf_id, ex_table, line)
	vim.bo[buf_id].modifiable = false
end

local function get_cached(buf_id, ex_table, line)
	local parent = ex_table[line]
	for i = 1, #parent.cached_entries do
		table.insert(ex_table, line + i, parent.cached_entries[i])
	end
	vim.api.nvim_buf_set_lines(buf_id, line, line, true, parent.cached_lines)
	parent.cached = false
	parent.cached_lines = {}
	parent.cached_entries = {}
	return ex_table
end

local function print_paths(buf_id, ex_table, start_line)
	local parent = ex_table[start_line]
	local depth = parent.depth + 1
	local path = parent.path
	local dir_iterator = vim.fs.dir(path)
	local prefix = ''
	for _ = 1, depth do
		prefix = prefix .. '| '
	end

	local indicator
	if depth < 0 then
		indicator = {directory = '', other = ''}
	else
		indicator = {directory = '> ', other = '+ '}
	end

	local directories = 0
	local other = 0
	local line
	local entry
	for name, type in dir_iterator do
		entry = {
			depth = depth,
			path = path .. '/' .. name,
			type = type,
			expanded = false,
			cached = false,
			cached_lines = {},
			cached_entries = {},
		}

		if type == 'directory' then
			line = start_line + directories
			directories = directories + 1
			name = indicator.directory .. name .. '/'
		else
			line = start_line + directories + other
			other = other + 1
			name = indicator.other .. name
		end

		table.insert(ex_table, line + 1, entry)
		vim.api.nvim_buf_set_lines(buf_id, line, line, true, {prefix..name})
	end

	return ex_table
end

local function expand(buf_id, ex_table, line)
	local parent = ex_table[line]
	parent.expanded = true
	local name = vim.api.nvim_buf_get_lines(buf_id, line - 1, line, true)[1]
	name = name:gsub('>', 'v', 1)
	vim.api.nvim_buf_set_lines(buf_id, line - 1, line, true, {name})
	if parent.cached and config.options.file_tree.cache then
		return get_cached(buf_id, ex_table, line)
	else
		return print_paths(buf_id, ex_table, line)
	end
end

local function close(buf_id, ex_table, line)
	local parent = ex_table[line]
	parent.expanded = false
	parent.cached = true

	local name = vim.api.nvim_buf_get_lines(buf_id, line - 1, line, true)[1]
	name = name:gsub('v', '>', 1)
	vim.api.nvim_buf_set_lines(buf_id, line - 1, line, true, {name})

	local sub_items = 0
	while #ex_table > line and ex_table[line + 1].depth > parent.depth do
		sub_items = sub_items + 1
		table.insert(parent.cached_entries, ex_table[line + 1])
		table.remove(ex_table, line + 1)
	end
	if config.options.file_tree.cache then
		parent.cached_lines =
			vim.api.nvim_buf_get_lines(buf_id, line, line + sub_items, true)
	end

	vim.api.nvim_buf_set_lines(buf_id, line, line + sub_items, true, {})
	return ex_table
end

function M.change_dir(path)
	utils.check_or_make_main_win()
	vim.schedule(function ()
		for _, win in ipairs(vim.api.nvim_list_wins()) do
			vim.api.nvim_win_call(win, function () vim.cmd.lcd(path) end)
		end
		M.render()
		vim.api.nvim_set_current_win(state.wins.file_tree)
		bufferbar.render()
	end)
end

function M.ascend()
	vim.schedule(function ()
		local new_path = vim.fs.abspath('.'):gsub('/[^/]+$', '')
		if new_path == '' then new_path = '/' end
		M.change_dir(new_path)
	end)
end

function M.descend()
	local line = vim.fn.line('.')
	local buf_id = state.bufs.file_tree
	if vim.b[buf_id].explorer_indent[line].type ~= 'directory' then return end
	local path = vim.b[buf_id].explorer_indent[line].path
	M.change_dir(path)
end

function M.action()
	local buf_id = state.bufs.file_tree
	local line = vim.fn.line('.')
	local header_height = state.tree.header_height

	if line <= header_height then
		return
	elseif line == header_height + 1 then
		M.ascend()
		return
	end

	local line_str = vim.api.nvim_buf_get_lines(buf_id, line - 1, line, true)[1]
	line_str = line_str:gsub('| ', ''):gsub('/', ''):gsub('[>v+] ', '')

	local ex_table = vim.b[buf_id].explorer_indent
	local parent = ex_table[line]
	if parent.type == 'file' then
		utils.check_or_make_main_win()
		local main_win = state.wins.main
		vim.api.nvim_set_current_win(main_win)
		vim.cmd('edit ' .. parent.path)
		vim.api.nvim_set_current_win(state.wins.file_tree)
		return
	end

	if parent.type == 'directory' and parent.expanded then
		generate_tree_action(buf_id, ex_table, line, close)
	elseif parent.type == 'directory' and not parent.expanded then
		generate_tree_action(buf_id, ex_table, line, expand)
	end

	M.highlight()
	return ''
end

function M.highlight()
	local buf_id = state.bufs.file_tree
	local ns_id = state.namespaces.file_tree
	vim.api.nvim_buf_clear_namespace(buf_id, ns_id, 0, -1)
	local ex_table = vim.b[buf_id].explorer_indent
	local dir_hl = vim.api.nvim_get_hl_id_by_name('netrwDir')
	local bar_hl = vim.api.nvim_get_hl_id_by_name('Special')
	local plain_hl = vim.api.nvim_get_hl_id_by_name('netrwPlain')
	local header_hl = vim.api.nvim_get_hl_id_by_name('netrwComment')
	local name_start
	local line_len
	local hl_group
	for i, entry in ipairs(ex_table) do
		name_start = entry.depth > 0 and entry.depth * 2 or 0
		line_len = #vim.api.nvim_buf_get_lines(buf_id, i - 1, i, true)[1]
		vim.api.nvim_buf_set_extmark(buf_id, ns_id, i - 1, 0, {end_col = name_start, hl_group = bar_hl})

		if entry.type == 'Header' then
			hl_group = header_hl
		elseif entry.type == 'directory' then
			hl_group = dir_hl
		else
			hl_group = plain_hl
		end

		vim.api.nvim_buf_set_extmark(buf_id, ns_id, i - 1, name_start, {end_col = line_len, hl_group = hl_group})
	end
end

function M.render()
	local buf_id = state.bufs.file_tree
	local win_id = state.wins.file_tree
	local path = vim.fs.abspath('.')
	local header_entry = {
		depth = -1,
		path = path,
		type = 'Header',
		expanded = false,
		cached = false,
		cached_lines = {},
		cached_entries = {},
	}
	local parent_dir_entry = {
		depth = -1,
		path = path,
		type = 'directory',
		expanded = false,
		cached = false,
		cached_lines = {},
		cached_entries = {},
	}

	local border = '=========================================='
	local title_line = ' File Tree'
	local home_dir = tostring(os.getenv('HOME') or os.getenv('USERPROFILE'))
	local path_line = path:gsub(home_dir, '~')
	if path_line ~= '/' then path_line = path_line .. '/' end
	path_line = ' Path: ' .. path_line

	local user_header = config.options.file_tree.header
	local header_lines = user_header or {border, title_line, path_line, border}
	state.tree.header_height = #header_lines
	local header_height = state.tree.header_height
	table.insert(header_lines, '../')

	local starting_array = {}
	for _ = 1, header_height do
		table.insert(starting_array, header_entry)
	end
	table.insert(starting_array, parent_dir_entry)

	vim.b[buf_id].explorer_indent = starting_array

	vim.bo[buf_id].modifiable = true
	vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, {})
	vim.api.nvim_buf_set_lines(buf_id, 0, 1, true, header_lines)
	vim.api.nvim_win_set_cursor(win_id, {header_height + 1, 0})
	vim.b[buf_id].explorer_indent =
		print_paths(buf_id, starting_array, header_height + 1)
	vim.bo[buf_id].modifiable = false
	M.highlight()
end

return M
