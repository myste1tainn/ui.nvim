require("uinvim.window")
require("uinvim.utils")

---@class MainWindow:Window
MainWindow = Window:new()
Window.new(MainWindow, {})
MainWindow.__index = MainWindow
MainWindow.name = "Main"
MainWindow.isRendered = true
MainWindow.handle = vim.api.nvim_get_current_win()

function MainWindow:render()
  if self == nil then
    error("Error: MainWindow's self is unexpectedly nil while trying to render()")
  end

  self.isRendered = true
  Window.renderBody(self)

  vim.cmd("set modifiable")
end
