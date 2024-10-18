require("catppuccin").setup({
  flavour = "auto",
  priority = 1000,
  background = {
    light = "latte",
    dark = "mocha",
  },
  transparent_background = false,
  show_end_of_buffer = false,
  term_colors = false,
  no_italic = false,
  no_bold = false,
  no_underline = false,
  styles = {
    comments = { "italic" },
    conditionals = { "italic" },
  },
  default_integrations = true,
})

vim.o.termguicolors = true
vim.o.background = "dark"
vim.cmd.colorscheme "catppuccin"
