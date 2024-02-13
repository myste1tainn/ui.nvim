require('utils')
local Rx = require("rx")

-- A subclass of `Window` that is readonly, and
-- have the ability to callback with a data option
-- selected by the user
---@class SelectionWindow:Window
---@field private selectionChange Rx.Subject
---@field private options table
---@field private optionName function
SelectionWindow = Window:new()
SelectionWindow._windows = {}

---@class SelectionWindowOptions
---@field options? table
---@field optionName function A function which translate `options` table into table of string, which will then be displayed as options for the user
SelectionWindowOptions = {}


---@param o SelectionWindowOptions
function SelectionWindow:new(o)
  o = o or {}
  Window.new(self, o)
  self.__index = self
  self.selectionChange = Rx.Subject.create()
  table.insert(SelectionWindow._windows, o)
  return o
end

function SelectionWindow:afterRender()
  self:setup()
end

-- Unlike other window type the SelectionWindow needs a setup
-- before it can be used, this is to overrid the behavior
---@private
function SelectionWindow:setup()
  local buff = vim.api.nvim_win_get_buf(self.handle)
  if buff == nil then
    error("SelectionWindow: unexpected nil buffer/handle")
  end

  self:runCommand('map <buffer> <CR> :SelectionWindowSelectLine ' .. self.handle .. '<CR>')
end

function SelectionWindow:setOptions(data)
  self.options = data
  self:deselect()
  local names = {}
  for _, v in ipairs(data) do
    table.insert(names, self.optionName(v))
  end
  self:overwrites(names)
end

-- Programmatically selects a line, this will also triggers the call to the listener
function SelectionWindow:selectLine(line)
  self:setOptions(self.options)
  local names = {}
  for i, v in ipairs(self.options) do
    if i == line then
      table.insert(names, "* " .. self.optionName(v))
    else
      table.insert(names, self.optionName(v))
    end
  end
  print('line before overwrites =', line)
  self.selectionChange:onNext(line)
  self:overwrites(names)
  print('line after overwrites =', line)
end

function SelectionWindow:deselect()
end

function SelectionWindow:onSelectionChange()
  return self.selectionChange:map(function(line)
    if line == nil then
      self:deselect()
    end
    if self.options[line] == nil then
      print("WARN: seletion happened outside the range of available data length =", #self.options)
    end
    return self.options[line]
  end)
end

local function getWindow(winId)
  winId = tonumber(winId)
  for _, v in ipairs(SelectionWindow._windows) do
    if v.handle == winId then
      return v
    end
  end
end

function SelectionWindowSelectLine(opts)
  local win = getWindow(opts.args)
  local line = vim.api.nvim_win_get_cursor(0)[1]
  win:selectLine(line)
end

vim.api.nvim_create_user_command(
  "SelectionWindowSelectLine",
  SelectionWindowSelectLine,
  { nargs = '?' }
)

return SelectionWindow
