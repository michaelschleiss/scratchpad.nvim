local M = {}

local scratchpad_bufnr = nil
local scratchpad_winid = nil

function M.toggle()
  local filepath = vim.fn.expand("~/.scratchpad.md")

  if scratchpad_winid and vim.api.nvim_win_is_valid(scratchpad_winid) then
    vim.api.nvim_win_close(scratchpad_winid, true)
    scratchpad_winid = nil
    return
  end

  if not scratchpad_bufnr or not vim.api.nvim_buf_is_valid(scratchpad_bufnr) then
    scratchpad_bufnr = vim.fn.bufadd(filepath)
    vim.fn.bufload(scratchpad_bufnr)
  end

  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.8)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  scratchpad_winid = vim.api.nvim_open_win(scratchpad_bufnr, true, {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal',
    border = 'rounded',
  })

  vim.bo[scratchpad_bufnr].buftype = ''
  vim.bo[scratchpad_bufnr].bufhidden = 'hide'
  vim.bo[scratchpad_bufnr].filetype = 'markdown'

  vim.cmd([[autocmd BufLeave <buffer> silent! write]])
end

return M
