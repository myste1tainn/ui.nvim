local rx = require("rx")
require("uinvim.split-direction")

---@class Window
Window = {
  name = nil,
  opts = {
    direction = SplitDirection.BOTTOM,
  },
  body = nil,
  text = rx.Subject,
  texts = rx.Subject,
}

---@class WindowOptionsOptions
---@field direction integer?
---@field readonly boolean?
---@field modifiable boolean?
---@field type string?
---@field command string?
WindowOptionsOptions = {}

---@class WindowOptions
---@field name string
---@field opts WindowOptionsOptions
WindowOptions = {}

function Window:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  o.text = rx.Subject.create()
  o.texts = rx.Subject.create()
  return o
end

---comment
---@param parent Window
---@return Window
function Window:render(parent)
  parent = parent or MainWindow
  if parent == nil then
    error(
      string.format([[
    Error: MainWindow haven\'t been setup yet, please do so.
    Or you can pass parent instance when calling render of the
    window %s
    ]]),
      self.name
    )
  end

  local renderCommand, optionsCommand = self:getCmd()
  vim.api.nvim_set_current_win(parent.handle)
  vim.cmd(renderCommand)
  self.handle = vim.api.nvim_get_current_win()
  if self.opts.type == 'term' then
    self.termJobId = vim.o.channel
    print("termJobId =", self.termJobId)
  end
  vim.cmd(optionsCommand)
  self:afterRender()
  vim.api.nvim_set_current_win(parent.handle)

  self:renderBody()

  self.text:subscribe(function(_, x)
    self:log({ x })
  end)

  self.texts:subscribe(function(_, x)
    self:overwrites(x)
  end)

  return self
end

function Window:afterRender()
end

function Window:renderBody()
  if self.body == nil then
    return
  end
  for _, v in ipairs(self.body) do
    v:render(self)
  end
end

function Window:getCmd()
  local opts = self.opts or {}

  local command = Switch(opts.direction)({
    [SplitDirection.BOTTOM] = "bot 10 new",
    [SplitDirection.LEFT] = "leftabove 32 vnew",
    [SplitDirection.TOP] = "leftabove 20 new",
    [SplitDirection.RIGHT] = "belowright 32 vnew",
    default = "bot 10 new",
  })

  local options = "set winfixwidth|set winfixheight"

  opts.modifable = opts.modifiable or false
  if not opts.modifiable then
    options = options .. "|set nomodifiable"
  end

  if opts.type == 'term' then
    command = command .. "|term"
    if opts.command ~= nil then
      command = command .. " " .. opts.command
    end
  else
    opts.readonly = opts.readonly or true
    if opts.readonly then
      options = options .. "|view " .. self.name
    else
      options = options .. "|edit " .. self.name
    end
  end

  if not opts.ruler then
    options = options .. "|set nonu|set nornu"
  end

  return command, options
end

function Window:size(width, height)
  self.width = width
  self.height = height
  return self
end

function Window:runCommand(command)
  self:runInBuffer(function() vim.cmd(command) end)
end

function Window:runInBuffer(fn)
  local prevWin = vim.api.nvim_get_current_win()
  vim.api.nvim_set_current_win(self.handle)
  fn()
  vim.api.nvim_set_current_win(prevWin)
end

function Window:modifyInBuffer(fn)
  self:runInBuffer(function()
    local buffer_number = vim.api.nvim_win_get_buf(self.handle)
    vim.api.nvim_buf_set_option(buffer_number, "readonly", false)
    vim.api.nvim_buf_set_option(buffer_number, "modifiable", true)
    -- Append the data.
    fn()
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
  end)
end

-- Log / write line(s) into the buffer, by appending onto
-- the last line in the buffer
---@param data table
---@return integer The last line being written
function Window:log(data)
  local buffer_number = vim.api.nvim_win_get_buf(self.handle)
  -- Get total line number of the current window's buffer
  if data then
    local buffer_line_count = vim.api.nvim_buf_line_count(buffer_number)
    self:modifyInBuffer(function()
      if buffer_line_count == 1 then
        vim.api.nvim_buf_set_lines(buffer_number, 0, 0, true, data)
      else
        vim.api.nvim_buf_set_lines(buffer_number, -1, -1, true, data)
      end
    end)
    local buffer_window = vim.api.nvim_call_function("bufwinid", { buffer_number })
    buffer_line_count = vim.api.nvim_buf_line_count(buffer_number)
    vim.api.nvim_win_set_cursor(buffer_window, { buffer_line_count, 0 })
    return buffer_line_count
  else
    local lineCount = vim.api.nvim_buf_line_count(buffer_number)
    return lineCount
  end
end

function Window:overwrites(data)
  self:clear()
  self:log(data)
end

-- Clear the window buffer, deleting all lines
function Window:clear()
  self:modifyInBuffer(function() vim.cmd('normal ggdG') end)
end
