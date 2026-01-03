local M = {}
local config = require('nvim-ideify.config')
local state = require('nvim-ideify.state')
local utils = require('nvim-ideify.utils')
local tree = require('nvim-ideify.tree')
local bufferbar = require('nvim-ideify.bufferbar')

local function close_buf(id)
	if id and vim.api.nvim_buf_is_valid(id) then
		vim.api.nvim_buf_delete(id, { force = true, })
	end
end

local function close_win(id)
	if id and vim.api.nvim_win_is_valid(id) then
		vim.api.nvim_win_close(id, true)
	end
end

local function setup_tree_keymaps(buf_id)
	local opts = { buffer = buf_id, expr = true, remap = false }
	local update = vim.schedule_wrap(tree.action)
	local make = vim.schedule_wrap(tree.render)
	local descend = vim.schedule_wrap(tree.descend)
	local ascend = vim.schedule_wrap(tree.ascend)

	vim.keymap.set('n', 'r', make, opts)
	vim.keymap.set('n', '-', ascend, opts)
	vim.keymap.set('n', '<CR>', update, opts)
	vim.keymap.set('n', '<S-CR>', descend, opts)
	vim.keymap.set('n', '<C-M>', update, opts)
	vim.keymap.set('n', '<S-C-M>', descend, opts)
	vim.keymap.set('n', '<LeftMouse>', function ()
		if vim.fn.getmousepos().winid ~= state.wins.file_tree then
			return '<LeftMouse>' end
		update()
		return '<LeftMouse>'
	end, opts)
end

local function setup_terminal_keymaps(buf_id)
	local opts = { buffer = buf_id, remap = false }
	vim.keymap.set('t', '<Esc>', '<C-\\><C-n>', opts)
end

local function setup_bufferbar_keymaps(buf_id)
	local opts = { buffer = buf_id, expr = true, remap = false }
	local switch = vim.schedule_wrap(bufferbar.switch_buffer)

	vim.keymap.set('n', '<CR>', switch, opts)
	vim.keymap.set('n', '<C-M>', switch, opts)
	vim.keymap.set('n', '<LeftMouse>', function()
		if vim.fn.getmousepos().winid ~= state.wins.buffer_bar then
			return '<LeftMouse>'
		end
		switch()
		return '<LeftMouse>'
	end, opts)

	local function generate_buf_scroll(flags)
		return function()
			local pos = vim.fn.col('.')
			vim.fn.search('[^ \\u2502]\\+', flags, vim.fn.line('.'))
			local new_pos = vim.fn.col('.')
			if new_pos == pos and new_pos > 3 then
				vim.cmd.normal('$b')
			elseif new_pos == pos then
				vim.cmd.normal('0w')
			end
		end
	end

	vim.keymap.set('n', 'w', generate_buf_scroll('W'), { buffer = buf_id, remap = false })
	vim.keymap.set('n', 'b', generate_buf_scroll('Wb'), { buffer = buf_id, remap = false })
	vim.keymap.set('n', '<S-ScrollWheelUp>', 'w', { buffer = buf_id, remap = true })
	vim.keymap.set('n', '<S-ScrollWheelDown>', 'b', { buffer = buf_id, remap = true })
end

local function setup_keymaps(buf_type, buf_id)
	if buf_type == 'tree' then
		setup_tree_keymaps(buf_id)
	elseif buf_type == 'terminal' then
		setup_terminal_keymaps(buf_id)
	elseif buf_type == 'bufferbar' then
		setup_bufferbar_keymaps(buf_id)
	end
end

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
	local file_tree_width = config.options.file_tree.win_opts.width
	local buffer_bar_height = config.options.buffer_bar.win_opts.height
	local terminal_height = config.options.terminal.win_opts.height
	local height_reduction = buffer_bar_height + terminal_height
	M.width_ratio = (vim.o.columns - file_tree_width) / vim.o.columns
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

function M.close_layout()
	utils.check_or_make_main_win()

	close_win(state.wins.file_tree)
	close_buf(state.bufs.file_tree)
	state.wins.file_tree = -1
	state.bufs.file_tree = -1

	close_win(state.wins.buffer_bar)
	close_buf(state.bufs.buffer_bar)
	state.wins.buffer_bar = -1
	state.bufs.buffer_bar = -1

	close_win(state.wins.terminal)
	close_buf(state.bufs.terminal)
	state.wins.terminal = -1
	state.bufs.terminal = -1

	state.active = false
end

function M.make_layout()
	M.close_layout()
	parse_layout()

	local tree_buf = vim.api.nvim_create_buf(false, true)
	local buf_bar_buf = vim.api.nvim_create_buf(false, true)
	local term_buf = vim.api.nvim_create_buf(true, false)

	state.bufs.file_tree = tree_buf
	state.bufs.buffer_bar = buf_bar_buf
	state.bufs.terminal = term_buf

	local tree_opts = config.options.file_tree.win_opts
	local buf_bar_opts = config.options.buffer_bar.win_opts
	local term_opts = config.options.terminal.win_opts

	state.wins.file_tree = vim.api.nvim_open_win(tree_buf, false, tree_opts)
	state.wins.buffer_bar = vim.api.nvim_open_win(buf_bar_buf, false, buf_bar_opts)
	state.wins.terminal = vim.api.nvim_open_win(term_buf, false, term_opts)

	-- vim.api.nvim_open_term(term_buf, {})
	vim.api.nvim_buf_call(term_buf, function () vim.cmd.terminal() end)

	vim.bo[tree_buf].modifiable = false
	vim.wo[state.wins.file_tree].wrap = false
	vim.wo[state.wins.file_tree].number = false
	vim.wo[state.wins.file_tree].winfixbuf = true
	vim.wo[state.wins.file_tree].statusline = ''

	vim.bo[buf_bar_buf].modifiable = false
	vim.bo[buf_bar_buf].buflisted = false
	vim.wo[state.wins.buffer_bar].wrap = false
	vim.wo[state.wins.buffer_bar].winfixbuf = true
	vim.wo[state.wins.buffer_bar].statusline = ''

	vim.bo[term_buf].buflisted = false
	vim.wo[state.wins.terminal].winfixbuf = true
	vim.wo[state.wins.terminal].statusline = ''

	setup_keymaps('tree', tree_buf)
	setup_keymaps('terminal', term_buf)
	setup_keymaps('bufferbar', buf_bar_buf)

	tree.render()
	bufferbar.render()

	vim.api.nvim_create_augroup('IDEifyBufferBar', { clear = true })
	vim.api.nvim_create_autocmd('BufEnter', {
		group = 'IDEifyBufferBar',
		callback = function()
			vim.defer_fn(bufferbar.render, 10)
		end
	})

	open_wins()
	state.active = true
end

return M
