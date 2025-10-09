return {
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      {
        "folke/lazydev.nvim",
        ft = "lua",
        opts = {
          library = {
            { path = "${3rd}/luv/library", words = { "vim%.uv" } },
          },
        },
      },
    },
    config = function()
      local lsp = require("core.lsp")
      local servers = {
        "gopls",
        "golangci_lint_ls",
        "ts_ls",
        "html",
        "cssls",
        "lua_ls",
        "jsonls",
        "ccls",
        "phpactor",
        "shopify_theme_ls",
      }

      for _, server in ipairs(servers) do
        lsp.enable(server)
      end
    end,
  },
}
