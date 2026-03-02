local M = {}

-- Store configuration with a sensible default
M.config = {
  filepath = vim.fn.expand("~/.scratchpad.md")
}

local scratchpad_bufnr = nil
local scratchpad_winid = nil

-- Optional setup function if you want to configure it later
function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
end

function M.toggle()
  -- 1. If the window is open, close it and return
  if scratchpad_winid and vim.api.nvim_win_is_valid(scratchpad_winid) then
    vim.api.nvim_win_close(scratchpad_winid, true)
    scratchpad_winid = nil
    return
  end

  -- 2. If the buffer doesn't exist, create it and set up one-time configs
  if not scratchpad_bufnr or not vim.api.nvim_buf_is_valid(scratchpad_bufnr) then
    scratchpad_bufnr = vim.fn.bufadd(M.config.filepath)
    vim.fn.bufload(scratchpad_bufnr)

    -- Set buffer options
    vim.bo[scratchpad_bufnr].buftype = ''
    vim.bo[scratchpad_bufnr].bufhidden = 'hide'
    vim.bo[scratchpad_bufnr].filetype = 'markdown'

    -- Auto-save exactly once using the Lua API
    vim.api.nvim_create_autocmd("BufLeave", {
      buffer = scratchpad_bufnr,
      callback = function()
        vim.cmd("silent! write")
      end,
    })

    -- Add quick-close mappings (press 'q' or '<Esc>' in normal mode to dismiss)
    local keymap_opts = { noremap = true, silent = true, buffer = scratchpad_bufnr }
    vim.keymap.set('n', 'q', M.toggle, keymap_opts)
    vim.keymap.set('n', '<Esc>', M.toggle, keymap_opts)
  end

  -- 3. Calculate dynamic window size based on current terminal size
  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.8)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  -- 4. Open the floating window
  scratchpad_winid = vim.api.nvim_open_win(scratchpad_bufnr, true, {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal',
    border = 'rounded',
  })
end

return M
