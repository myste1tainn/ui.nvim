require('uinvim.utils')

return {
  win_split = function(fromWin, opts)
    local command = Switch(opts.direction) {
      [SplitDirection.BOTTOM] = 'bot 10 new',
      [SplitDirection.LEFT] = 'leftabove 32 vnew',
      [SplitDirection.TOP] = 'leftabove 20 new',
      [SplitDirection.RIGHT] = 'belowright 32 vnew',
    }
    print('command =', command)
    local currentWinHandle = vim.api.nvim_get_current_win()
    if fromWin ~= nil then
      print('comes from fromWin', fromWin.name)
      currentWinHandle = fromWin.handle
    end
    vim.api.nvim_set_current_win(currentWinHandle)
    local fixSize = 'set winfixwidth|set winfixheight'
    local readonly = 'set nomodifiable|view ' .. opts.name
    local ruler = 'set nonu|set nornu'
    vim.cmd(command .. '|' .. fixSize .. '|' .. readonly .. '|' .. ruler)
    local newWinHandle = vim.api.nvim_get_current_win()

    -- Set the window back to the previous one, so that next time we can split off from it correctly
    print('currentWinHandle =', currentWinHandle)
    vim.api.nvim_set_current_win(currentWinHandle)
    --local b = vim.api.nvim_create_buf(false, false)
    --local r = vim.api.nvim_open_win(b, false, {
    --  split = 'left',
    --  win = b,
    --  --row = 3,
    --  --col = 3,
    --  --width = 10,
    --  --height = 20,
    --})
    return newWinHandle
  end
}
