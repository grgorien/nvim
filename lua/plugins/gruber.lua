return {
  "blazkowolf/gruber-darker.nvim",
  lazy = false,
  priority = 1000,
  opts = {
    bold = false,
    italic = {
      strings = false,
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "gruber-darker",
    },
  },
}
