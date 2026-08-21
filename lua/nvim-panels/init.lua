local M = {}

local config = require('nvim-panels.config')
local constants = require('nvim-panels.constants')
local state = require('nvim-panels.state')
local ui = require('nvim-panels.ui')

local bufferbar = require('nvim-panels.bufferbar')

local nvim_version = vim.version()

M.open = ui.open
M.close = ui.close
M.hide = ui.hide
M.show = ui.show
M.toggle = ui.toggle
M.reset = ui.reset
M.hard_reset = ui.hard_reset

M.bufferbar_next = bufferbar.buffer_next
M.bufferbar_previous = bufferbar.buffer_previous

---
---@param position nvim-panels.position
function M.panel_toggle(position)
	local panel_confs = config.options.layout
	if not panel_confs[position] then return end

	panel_confs[position].hidden = not panel_confs[position].hidden

	M.reset()
end

---
---@param position1 nvim-panels.position
---@param position2 nvim-panels.position
function M.panel_swap(position1, position2)
	local panel_confs = config.options.layout
	if not panel_confs[position1] or not panel_confs[position2] then return end

	local tmp_module1 = panel_confs[position1].module
	local tmp_module2 = panel_confs[position2].module

	panel_confs[position1].module = tmp_module2
	panel_confs[position2].module = tmp_module1

	M.reset()
end

---
---@param position nvim-panels.position
---@param size integer
function M.panel_resize(position, size)
	local panel_confs = config.options.layout
	if not panel_confs[position] then return end

	if panel_confs[position].width then
		panel_confs[position].width = size
	elseif panel_confs[position].height then
		panel_confs[position].height = size
	end

	M.reset()
end

---
---@param opts nvim-panels.options
function M.setup(opts)
	config.setup(opts)
	require('nvim-panels.state').wins.main = vim.api.nvim_get_current_win()
end

vim.api.nvim_create_augroup('Panels', { clear = true })
vim.api.nvim_create_autocmd('WinEnter', {
	group = 'Panels',
	callback = function(args)
		local utils = require('nvim-panels.utils')
		local win = vim.api.nvim_get_current_win()
		local buf = args.buf
		local check_id = not constants.ui2_buffers[buf]
		local check_type = utils.check_buf_type(buf)
		if not utils.is_plugin_win(win) and check_id and check_type then
			state.wins.last = win
		end
	end,
})

vim.api.nvim_create_autocmd('TextChanged', {
	group = 'Panels',
	callback = function(args)
		if vim.bo[args.buf].filetype ~= 'netrw' or not state.active then
			return
		end
		local utils = require('nvim-panels.utils')
		local win = vim.api.nvim_get_current_win()
		if utils.is_plugin_win(win) then
			local win_to_pos = utils.get_win_to_position()
			ui.module_buf_reload(win_to_pos[win])
		end
	end
})

vim.api.nvim_create_autocmd('WinResized', {
	group = 'Panels',
	callback = function(args)
		if not state.active then return end
		local utils = require('nvim-panels.utils')
		local win = tonumber(args.match) or constants.NOID
		if utils.is_plugin_win(win) then
			local win_to_pos = utils.get_win_to_position()
			local pos = win_to_pos[win]
			local module = config.options.layout[pos].module()
			module.get_ui().render()
		end
	end
})

if nvim_version.major == 0 and nvim_version.minor < 13 then return M end

vim.api.nvim_create_autocmd('SessionWritePre', {
	group = 'Panels',
	callback = function()
		ui.close()
	end,
})

return M
