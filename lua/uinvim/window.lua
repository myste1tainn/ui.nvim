local rx = require("rx")
require("uinvim.split-direction")

---@class Window
Window = {
  name = nil,
  opts = {
    direction = SplitDirection.BOTTOM,
  },
  body = {},
  text = rx.Subject,
  texts = rx.Subject,
}

---@class WindowOptionsOptions
---@field direction integer?
---@field readonly boolean?
---@field modifiable boolean?
---@field type string?
---@field command string?
---@field shortcutKey string? A shortcutKey to map to this window, triggering the key will results in toggling this window focus/show/hide
WindowOptionsOptions = {}

---@class WindowOptions
---@field name string
---@field opts WindowOptionsOptions
---@field body table Table of Windows which is to be rendered as a child window(s) to this one
---@field text rx.Subject Topic to put a text in which will be appended to this window display
---@field texts rx.Subject Topic to put text(s) in which will be rendered to this window, all previous will be overwrites
WindowOptions = {}

function Window:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  o:_setup()
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

  if parent == MainWindow then
    if MainWindow.body == nil then
      MainWindow.body = {}
    end
    table.insert(parent.body, self)
  end

  self.parent = parent

  local renderCommand, optionsCommand = self:getCmd()
  vim.api.nvim_set_current_win(parent.handle)
  vim.cmd(renderCommand)
  self.handle = vim.api.nvim_get_current_win()
  if self.opts.type == "term" then
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

  self.isRendered = true

  return self
end

function Window:afterRender() end

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

  if opts.type == "term" then
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
  self:runInBuffer(function()
    vim.cmd(command)
  end)
end

function Window:runInBuffer(fn)
  local prevWin = vim.api.nvim_get_current_win()
  vim.api.nvim_set_current_win(self.handle)
  fn()
  if prevWin == self.handle then
    vim.api.nvim_set_current_win(MainWindow.handle)
  else
    vim.api.nvim_set_current_win(prevWin)
  end
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
  self:modifyInBuffer(function()
    vim.cmd("normal ggdG")
  end)
end

---@private
function Window:_setup()
  self.text = rx.Subject.create()
  self.texts = rx.Subject.create()
  self.isRendered = false
  self:bindKey()
end

function Window:bindKey()
  if self.opts.shortcutKey == nil then
    return
  end

  -- if the key is set here then the key will be mapped
  vim.keymap.set({ "n", "i", "v" }, self.opts.shortcutKey, ":UinvimToggleWindow " .. self.name .. "<CR>")
end

function Window:getFirstParentThatIsStillRendered()
  if self.parent.isRendered then
    return self.parent
  else
    print("self.parent.name =", self.parent.name)
    print("self.parent.isRendered =", self.parent.isRendered)
    print("self.parent.parent =", self.parent.parent)
    return self.parent.parent:getFirstParentThatIsStillRendered()
  end
end

function Window:toggle()
  if self:isFocused() then
    self:hide()
  elseif self.isRendered then
    self:focus()
  else
    self:render(self:getFirstParentThatIsStillRendered())
    self:focus()
  end
end

function Window:hide()
  self:runCommand("quit")
  self.isRendered = false
  MainWindow:focus()
end

function Window:focus()
  vim.api.nvim_set_current_win(self.handle)
end

function Window:isFocused()
  return self.handle == vim.api.nvim_get_current_win()
end

---@param win Window
---@param id string
local function getWindows(win, id)
  for _, v in pairs(win.body) do
    if v.name == id then
      return v
    end
    return getWindows(v, id)
  end
end

function UinvimToggleWindow(opts)
  local id = opts.args
  local window = getWindows(MainWindow, id)
  if window == nil then
    error("Cannot find window with identifier '" .. id .. "'")
  end
  window:toggle()
end

vim.api.nvim_create_user_command("UinvimToggleWindow", UinvimToggleWindow, { nargs = "?" })
