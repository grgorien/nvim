return {
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      {
        "folke/lazydev.nvim",
        ft = "lua", -- only load on lua files
        opts = {
          library = {
            -- See the configuration section for more details
            -- Load luvit types when the `vim.uv` word is found
            { path = "${3rd}/luv/library", words = { "vim%.uv" } },
          },
        },
      },
    },
    config = function()
      local lspconfig = require('lspconfig')
      local capabilities = require('cmp_nvim_lsp').default_capabilities()

      lspconfig.lua_ls.setup{
        capabilities = capabilities,
      }
      lspconfig.gopls.setup{
        capabilities = capabilities,
      }
      lspconfig.html.setup{
        capabilities = capabilities,
      }
      lspconfig.cssls.setup{
        capabilities = capabilities,
      }
      lspconfig.ts_ls.setup{
        capabilities = capabilities,
        init_options = {
          plugins = {
            {
              name = "@vue/typescript-plugin",
              location = "/usr/lib/node_modules/typescript-plugin",
              languages = { "javascript", "typescript", "vue" },
            }
          }
        },
        filetypes = {
          "javascript",
          "typescript",
          "vue"
        },
      }
      lspconfig.pyright.setup{
        capabilities = capabilities,
      }
    end,
  }
}
