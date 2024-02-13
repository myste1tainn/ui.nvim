require('utils')

---@class TermWindowOptions:WindowOptions
---@field cmd string? Optional command, if specified it will be run upfront
TermWindowOptions = {}

---@class TermWindow:Window
TermWindow = Window:new()

---@param o TermWindowOptions
function TermWindow:new(o)
  o = o or {}
  o.opts = o.opts or {}
  o.opts.type = 'term'
  o.opts.command = o.cmd
  Window.new(self, o)
  self.__index = self
  return o
end

function TermWindow:run(cmd)
  if self.termJobId == nil then
    error("expecting Terminal Job ID to be able to run command in the TermWindow, found nil")
  end

  vim.cmd("call chansend(" .. self.termJobId .. ", ['" .. cmd .. "', ''])")
end
