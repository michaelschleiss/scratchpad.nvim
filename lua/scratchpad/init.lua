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

-- Helper to safely close the window
local function close_window()
  if scratchpad_winid and vim.api.nvim_win_is_valid(scratchpad_winid) then
    vim.api.nvim_win_close(scratchpad_winid, true)
  end
  scratchpad_winid = nil
end

function M.toggle()
  -- 1. If the window is open, close it and return
  if scratchpad_winid and vim.api.nvim_win_is_valid(scratchpad_winid) then
    close_window()
    return
  end

  -- 2. If the buffer doesn't exist, create it and set up one-time configs
  if not scratchpad_bufnr or not vim.api.nvim_buf_is_valid(scratchpad_bufnr) then
    scratchpad_bufnr = vim.fn.bufadd(M.config.filepath)

    -- Intercept the swapfile warning and automatically choose "Edit anyway" (e)
    local swap_au_id = vim.api.nvim_create_autocmd("SwapExists", {
      pattern = M.config.filepath,
      callback = function()
        vim.v.swapchoice = 'e'
      end,
    })

    -- Safely load the buffer.
    pcall(vim.fn.bufload, scratchpad_bufnr)

    -- Clean up the temporary swapfile interceptor so it doesn't affect other files
    pcall(vim.api.nvim_del_autocmd, swap_au_id)

    -- Set buffer options
    vim.bo[scratchpad_bufnr].buftype = ''
    vim.bo[scratchpad_bufnr].bufhidden = 'hide'
    vim.bo[scratchpad_bufnr].filetype = 'markdown'

    -- Auto-save exactly once using the Lua API. 
    -- Changed 'write' to 'update' so it only writes to disk if the buffer was modified.
    vim.api.nvim_create_autocmd("BufLeave", {
      buffer = scratchpad_bufnr,
      callback = function()
        vim.cmd("silent! update")
      end,
    })

    -- Auto-close the floating window if it loses focus (e.g. via <C-w><C-w>)
    vim.api.nvim_create_autocmd("WinLeave", {
      buffer = scratchpad_bufnr,
      callback = function()
        -- Schedule the close to avoid errors during the WinLeave event
        vim.schedule(function()
          close_window()
        end)
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

  -- 4. Open the floating window with a title
  scratchpad_winid = vim.api.nvim_open_win(scratchpad_bufnr, true, {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal',
    border = 'rounded',
    title = ' Scratchpad ',
    title_pos = 'center',
  })

  -- Improve margins and reading experience
  vim.opt_local.number = false
  vim.opt_local.relativenumber = false
  vim.opt_local.signcolumn = 'no' -- Completely disable the signcolumn bar
  vim.opt_local.foldcolumn = '1' -- Use 1 space of foldcolumn for pure text padding without the bar
  vim.opt_local.wrap = true
  vim.opt_local.linebreak = true
  vim.opt_local.conceallevel = 2
  vim.opt_local.colorcolumn = ''     -- Remove any vertical ruler
  vim.opt_local.fillchars:append({ eob = ' ' }) -- Hide the '~' at the end of the buffer
end

return M
