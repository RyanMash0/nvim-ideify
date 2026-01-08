local M = {}
local config = require('nvim-ideify.config')
local state = require('nvim-ideify.state')
local utils = require('nvim-ideify.utils')
local pos = require('nvim-ideify.position')

local left = config.options.layout.left.module
local right = config.options.layout.right.module
local top = config.options.layout.top.module
local bottom = config.options.layout.bottom.module

M.win_structure = {}
M.height_ratio = 1
M.width_ratio = 1

local function parse_structure(node, depth, idx)
	local new_depth
	local new_node
	local win_config
	local win_buf

	for i = 1, #node[2] do
		new_depth = depth + 1
		new_node = node[2][i]
		if new_node[1] ~= 'leaf' then
			if not M.win_structure[new_depth] then
				M.win_structure[new_depth] = {}
			end

			table.insert(M.win_structure[new_depth], {
				split_type = new_node[1],
				where_split = { idx, i },
				wins = {}
			})

			parse_structure(new_node, new_depth, #M.win_structure[new_depth])
		end

		while new_node[1] ~= 'leaf' do
			new_node = new_node[2][1]
			new_depth = new_depth + 1
		end

		win_config = vim.api.nvim_win_get_config(new_node[2])
		if M.win_structure[depth][idx].split_type == "row" then
			win_config.split = 'right'
		else
			win_config.split = 'below'
		end

		if win_config.height then
			win_config.height = math.floor(win_config.height * M.height_ratio)
		end
		if win_config.width then
			win_config.width = math.floor(win_config.width * M.width_ratio)
		end

		win_buf = vim.api.nvim_win_get_buf(new_node[2])

		M.win_structure[depth][idx].wins[i] = {
			id = new_node[2],
			config = win_config,
			buffer = win_buf,
		}
	end
end

local function parse_layout()
	local win_layout = vim.fn.winlayout()
	local wins = vim.api.nvim_tabpage_list_wins(0)
	M.win_structure = {}
	if #wins == 1 then return end
	local l_width = config.options.layout.left.width
	local r_width = config.options.layout.right.width
	local t_height = config.options.layout.top.height
	local b_height = config.options.layout.bottom.height

	local width_reduction = l_width + r_width
	local height_reduction = t_height + b_height
	M.width_ratio = (vim.o.columns - width_reduction) / vim.o.columns
	M.height_ratio = (vim.o.lines - height_reduction) / vim.o.lines

	local initial_entry = {
		split_type = win_layout[1],
		where_split = nil,
		wins = {},
	}
	M.win_structure = { { initial_entry } }
	parse_structure(win_layout, 1, 1)
	state.wins.main = M.win_structure[1][1].wins[1].id

	for _, win in ipairs(wins) do
		if win ~= state.wins.main then
			vim.api.nvim_win_hide(win)
		end
	end
end

local function open_wins()
	vim.api.nvim_set_current_win(state.wins.main)
	local win
	local split
	local win_id

	for i = 1, #M.win_structure do
		for j = 1, #M.win_structure[i] do
			split = M.win_structure[i][j].where_split

			if split then
				win_id = M.win_structure[i - 1][split[1]].wins[split[2]].id
				M.win_structure[i][j].wins[1].id = win_id
				vim.api.nvim_set_current_win(win_id)
			end

			for k = 2, #M.win_structure[i][j].wins do
				win = M.win_structure[i][j].wins[k]
				win.id = vim.api.nvim_open_win(win.buffer, true, win.config)
			end
		end
	end
	vim.api.nvim_set_current_win(state.wins.main)
end

local function get_panel_from_direction(direction)
	if direction == pos.left then return config.options.layout.left
	elseif direction == pos.right then return config.options.layout.right
	elseif direction == pos.top then return config.options.layout.top
	elseif direction == pos.bottom then return config.options.layout.bottom end
end

local function close_panel(module)
	if not module then return end

	utils.close_win(module.state.window)
	utils.delete_buf(module.state.buffer)
	module.state.window = -1
	module.state.buffer = -1
end

local function hide_panel(module)
	if not module then return end

	if utils.is_valid(module.state.window, 'window') then
		module.state.win_config = vim.api.nvim_win_get_config(module.state.window)
	end

	utils.close_win(module.state.window)
	module.state.window = -1
end

local function open_panel(direction)
	local panel = get_panel_from_direction(direction)
	if not panel.module then return end

	local listed = panel.module.config.options.buffer.listed
	local scratch = panel.module.config.options.buffer.scratch
	local buf = vim.api.nvim_create_buf(listed, scratch)

	panel.module.state.buffer = buf

	local opts = panel.module.config.options.window.start_opts
	opts.split = direction
	if direction == pos.left or direction == pos.right then
		opts.vertical = true
		opts.width = panel.width
	else
		opts.height = panel.height
	end

	panel.module.state.win_config = opts

	local win = vim.api.nvim_open_win(buf, false, opts)
	panel.module.state.window = win

	panel.module.ui.render()

	panel.module.keymaps.setup()

	local buf_opts = panel.module.config.options.buffer.opts
	for key, val in pairs(buf_opts) do
		vim.api.nvim_set_option_value(key, val, { scope = 'local', buf = buf })
	end

	local win_opts = panel.module.config.options.window.opts
	for key, val in pairs(win_opts) do
		vim.api.nvim_set_option_value(key, val, { scope = 'local', win = win })
	end
end

local function unhide_panel(direction)
	local panel = get_panel_from_direction(direction)
	if not panel.module then return end

	local opts = panel.module.state.win_config
	local win = vim.api.nvim_open_win(panel.module.state.buffer, false, opts)
	panel.module.state.window = win

	local win_opts = panel.module.config.options.window.opts
	for key, val in pairs(win_opts) do
		vim.api.nvim_set_option_value(key, val, { scope = 'local', win = win })
	end
end

function M.close()
	utils.check_or_make_main_win()

	state.active = false
	state.opened = false

	close_panel(left)
	close_panel(right)
	close_panel(top)
	close_panel(bottom)

	if state.equalalways then
		vim.opt.equalalways = true
	end
end

function M.open()
	M.close()
	if state.equalalways then
		vim.opt.equalalways = false
	end
	parse_layout()

	open_panel(config.options.split_order.first)
	open_panel(config.options.split_order.second)
	open_panel(config.options.split_order.third)
	open_panel(config.options.split_order.fourth)

	-- I have to do this to get it to reload for some reason
	left = config.options.layout.left.module
	right = config.options.layout.right.module
	top = config.options.layout.top.module
	bottom = config.options.layout.bottom.module

	vim.keymap.set('n', '<LeftMouse>', function()
		local win = vim.fn.getmousepos().winid
		if left and win == left.state.window and left.state.on_click then
			left.state.on_click()
		elseif right and win == right.state.window and right.state.on_click then
			right.state.on_click()
		elseif top and win == top.state.window and top.state.on_click then
			top.state.on_click()
		elseif bottom and win == bottom.state.window and bottom.state.on_click then
			bottom.state.on_click()
		end
		return '<LeftMouse>'
	end, { expr = true, remap = false })

	open_wins()
	state.active = true
	state.opened = true
end

function M.hide()
	utils.check_or_make_main_win()

	state.active = false

	hide_panel(left)
	hide_panel(right)
	hide_panel(top)
	hide_panel(bottom)

	if state.equalalways then
		vim.opt.equalalways = true
	end
end

function M.show()
	M.hide()
	if state.equalalways then
		vim.opt.equalalways = false
	end
	parse_layout()

	unhide_panel(config.options.split_order.first)
	unhide_panel(config.options.split_order.second)
	unhide_panel(config.options.split_order.third)
	unhide_panel(config.options.split_order.fourth)

	-- I have to do this to get it to reload for some reason
	left = config.options.layout.left.module
	right = config.options.layout.right.module
	top = config.options.layout.top.module
	bottom = config.options.layout.bottom.module

	vim.keymap.set('n', '<LeftMouse>', function()
		local win = vim.fn.getmousepos().winid
		if left and win == left.state.window and left.state.on_click then
			left.state.on_click()
		elseif right and win == right.state.window and right.state.on_click then
			right.state.on_click()
		elseif top and win == top.state.window and top.state.on_click then
			top.state.on_click()
		elseif bottom and win == bottom.state.window and bottom.state.on_click then
			bottom.state.on_click()
		end
		return '<LeftMouse>'
	end, { expr = true, remap = false })

	open_wins()
	state.active = true
end

local function panel_size_reset(direction)
	local panel = get_panel_from_direction(direction)
	if not panel.module then return end

	local opts
	if direction == pos.left or direction == pos.right then
		opts = { width = panel.width }
	else
		opts = { height = panel.height }
	end

	vim.api.nvim_win_set_config(panel.module.state.window, opts)

	panel.module.state.win_config =
		vim.api.nvim_win_get_config(panel.module.state.window)
end

function M.reset()
	M.show()

	panel_size_reset(pos.left)
	panel_size_reset(pos.right)
	panel_size_reset(pos.top)
	panel_size_reset(pos.bottom)
end

return M
