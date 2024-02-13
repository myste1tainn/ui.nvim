require('uinvim.window')
require('uinvim.utils')

---@class MainWindow:Window
MainWindow = Window:new()


function MainWindow:new(o)
  Window.new(self, o)
  self.handle = vim.api.nvim_get_current_win()
  return o
end

function MainWindow:render()
  if self == nil then
    error('Error: MainWindow\'s self is unexpectedly nil while trying to render()')
  end

  Window.renderBody(self)

  vim.cmd('set modifiable')
end
