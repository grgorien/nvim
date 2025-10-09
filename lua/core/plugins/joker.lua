return {
  "ksevelyar/joker.vim",
  lazy = false,    -- to make sure it's loaded on startup
  priority = 1000, -- to load before other plugins
  config = function()
    vim.cmd('colorscheme joker')

    vim.api.nvim_set_hl(0, "Visual", {
      bg = "#553399",
      fg = "#FFFFFF",
      bold = true
    })
  end,
}
