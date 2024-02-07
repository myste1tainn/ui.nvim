local dump = require('utils').dump
require('uide.class')

-- A subclass of `Window` that is readonly, and
-- have the ability to callback with a data option
-- selected by the user
SelectionWindow = Window:new()

-- Unlike other window type the SelectionWindow needs a setup
-- before it can be used, this is to overrid the behavior
function SelectionWindow:setup()
  local buff = vim.api.nvim_win_get_buf(self.handle)
  if buff == nil then
    error("SelectionWindow: unexpected nil buffer/handle")
  end

  self:runCommand('map <buffer> <CR> :SelectionWindowSelectLine ' .. self.handle .. '<CR>')
end

function SelectionWindow:setOptions(data)
  self.options = data
end

function SelectionWindow:log(data)
  Window.log(self, data)
end

-- Programmatically selects a line, this will also triggers the call to the listener
function SelectionWindow:selectLine(line)

end

function SelectionWindow:notifyListeners()
end

function SelectionWindowSelectLine(opts)
  print(dump(opts.args))
  local win = Windows.get(opts.args)
  local line = vim.api.nvim_win_get_cursor(0)[1]
  win:log({ 'success, selected line is = ' .. line })
  win:selectLine(line)
end

vim.api.nvim_create_user_command(
  "SelectionWindowSelectLine",
  SelectionWindowSelectLine,
  { nargs = '?' }
)

return SelectionWindow
