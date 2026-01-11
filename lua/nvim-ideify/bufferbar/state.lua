local M = {}

M.buffer = -1
M.window = -1
M.win_config = {}

M.namespace = vim.api.nvim_create_namespace('IDEifyBufferBar')
M.buffer_info = {}
M.on_click = nil

function M:set_buffer(buf_id)
	self.buffer = buf_id
end

function M:get_buffer()
	return self.buffer
end

function M:set_window(win_id)
	self.window = win_id
end

function M:get_window()
	return self.window
end

function M:set_win_config(config)
	self.win_config = config
end

function M:get_win_config()
	return self.win_config
end

function M:get_namespace()
	return self.namespace
end

function M:set_buffer_info(buffer_info)
	self.buffer_info = buffer_info
end

function M:get_buffer_info()
	return self.buffer_info
end

function M:set_on_click(on_click)
	self.on_click = on_click
end

function M:get_on_click()
	return self.on_click
end

return M
