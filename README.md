# nvim-scratchpad

A minimal floating markdown scratchpad for Neovim.

## 📦 Installation (with lazy.nvim)

```lua
{
  "yourname/nvim-scratchpad",
  keys = {
    { "<leader>s", function() require("scratchpad").toggle() end, desc = "Toggle Scratchpad" }
  }
}
