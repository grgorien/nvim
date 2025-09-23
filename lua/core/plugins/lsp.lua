return {
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      {
        "folke/lazydev.nvim",
        ft = "lua", -- only load on lua files
        opts = {
          library = {
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
      lspconfig.golangci_lint_ls.setup{
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
              location = "/home/websilkfx/.nvm/versions/node/v22.19.0/lib/node_modules/@vue/typescript-plugin",
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

      lspconfig.jsonls.setup{
        capabilities = capabilities,
        filetypes = { "json", "jsonc" }
      }

      lspconfig.ccls.setup{
        filetypes = { "c", "cpp" }
      }
      lspconfig.pyright.setup{
        capabilities = capabilities
      }
      lspconfig.phpactor.setup{
        capabilities = capabilities
      }
    end,
  }
}
