require("uinvim.window")
require("uinvim.main-window")
require("uinvim.selection-window")
require("uinvim.term-window")
require("uinvim.split-direction")

-- BEGIN TESTING SCRIPT
function run()
  Window:new({
    name = "Testing Window",
    opts = {
      shortcutKey = "<A-1>",
      direction = SplitDirection.RIGHT,
    },
  }):render()
end

local p = require("plenary.scandir")
function SourceAllFiles()
  SourceAllFilesInDir("uinvim")
  --SourceAllFilesInDir("ide")
end

---@param dir string
function SourceAllFilesInDir(dir)
  local base = "/Users/arnon.keereena/Sources/neovim-plugins"
  local pluginDir = base .. "/" .. dir .. ".nvim"
  vim.cmd("so " .. pluginDir .. "/lua/" .. dir .. "/init.lua")
  local dirs = p.scan_dir(pluginDir .. "/lua/" .. dir, { hidden = true, depth = 2 })
  for _, f in ipairs(dirs) do
    if string.match(f, ".lua") then
      if string.match(f, dir .. "/init.lua") then
        goto continue
      end
      -- Source only the lua files
      print("Sourcing file =", f)
      local command = "so " .. f
      vim.cmd(command)
    end
    ::continue::
  end
  run()
end

vim.api.nvim_create_user_command("SourceAllFiles", SourceAllFiles, {})
vim.keymap.set("n", "<leader>t", ":SourceAllFiles<CR>")

-- END TESTING SCRIPT
