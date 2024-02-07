local dump = require('utils').dump
require('uide.windows.window-type')

local fn = require('uide.windows.functions')

-- class Window
-- Reprsent basic window type, all window type have to be coming from this type
Window = {}

function Window:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  o.name = o.name or ''
  o.type = o.type or WindowType.split(nil)
  return o
end

function Window:main(opts)
  opts = opts or {}
  opts.name = opts.name or ''
  local win = Window:new(opts)
  win.handle = vim.api.nvim_get_current_win()
  return win
end

function Window:size(width, height)
  self.width = width
  self.height = height
  return self
end

-- Split per specify direction, returning new Window object that is created
function Window:split(opts)
  opts = opts or {}
  opts.name = opts.name or ''
  opts.direction = opts.direction or SplitDirection.BOTTOM
  opts.class = opts.class or Window

  local win = opts.class:new({
    name = opts.name,
    type = WindowType.split({ direction = opts.direction })
  })

  win.handle = fn.win_split(self, opts)

  return win
end

function Window:runCommand(command)
  local prevWin = vim.api.nvim_get_current_win()
  vim.api.nvim_set_current_win(self.handle)
  vim.cmd(command)
  vim.api.nvim_set_current_win(prevWin)
end

function Window:log(data)
  local buffer_number = vim.api.nvim_win_get_buf(self.handle)
  -- Get total line number of the current window's buffer
  if data then
    -- Make it temporarily writable so we don't have warnings.
    vim.api.nvim_buf_set_option(buffer_number, "readonly", false)
    vim.api.nvim_buf_set_option(buffer_number, "modifiable", true)
    -- Append the data.
    vim.api.nvim_buf_set_lines(buffer_number, -1, -1, true, data)
    -- Make readonly again.
    vim.api.nvim_buf_set_option(buffer_number, "readonly", true)
    vim.api.nvim_buf_set_option(buffer_number, "modifiable", false)
    -- Mark as not modified, otherwise you'll get an error when
    -- attempting to exit vim.
    vim.api.nvim_buf_set_option(buffer_number, "modified", false)
    -- Get the window the buffer is in and set the cursor position to the bottom.
    local buffer_window = vim.api.nvim_call_function("bufwinid", { buffer_number })
    local buffer_line_count = vim.api.nvim_buf_line_count(buffer_number)
    vim.api.nvim_win_set_cursor(buffer_window, { buffer_line_count, 0 })
    return buffer_line_count
  else
    local lineCount = vim.api.nvim_buf_line_count(buffer_number)
    return lineCount
  end
end

return Window
