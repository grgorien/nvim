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
      -- warning/error on lspconfig framework on instance
      local lspconfig = require("lspconfig")
      local util = require("lspconfig.util")
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      capabilities.textDocument.completion.completionItem.snippetSupport = true
      capabilities.textDocument.completion.completionItem.resolveSupport = {
        properties = { "documentation", "detail", "additionalTextEdits" }
      }

      local on_attach = function(client, bufnr)
        vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')
        vim.notify(client.name .. " attached to buffer " .. bufnr, vim.log.levels.INFO)
      end

      -- shopify/cli shopify/theme(dep) -> cli integrated
      local configs = require("lspconfig.configs")
      if not configs.theme_check then
        configs.theme_check = {
          default_config = {
            cmd = { "shopify", "theme", "language-server" },
            filetypes = { "liquid" },
            root_dir = util.root_pattern(".theme-check.yml", "config.yml", "shopify.theme.toml", ".git"),
            single_file_support = true,
            settings = {},
          },
        }
      end

      lspconfig.theme_check.setup({
        capabilities = capabilities,
        on_attach = on_attach,
      })

      lspconfig.ts_ls.setup({
        capabilities = capabilities,
        on_attach = on_attach,
        settings = {
          typescript = {
            preferences = { includePackageJsonAutoImports = "off" },
            suggest = { includeCompletionsForModuleExports = true },
          },
          javascript = {
            preferences = { includePackageJsonAutoImports = "off" },
            suggest = { includeCompletionsForModuleExports = true },
          },
        },
        filetypes = { "javascript", "typescript", "vue", "liquid" },
      })

      lspconfig.html.setup({
        capabilities = capabilities,
        on_attach = on_attach,
        filetypes = { "html", "liquid" },
        init_options = {
          configurationSection = { "html", "css", "javascript" },
          embeddedLanguages = { css = true, javascript = true },
          provideFormatter = false,
        },
      })

      lspconfig.cssls.setup({
        capabilities = capabilities,
        on_attach = on_attach,
        filetypes = { "css", "scss", "less", "liquid" },
        settings = { css = { lint = { unknownAtRules = "ignore" } } },
      })

      lspconfig.lua_ls.setup({
        capabilities = capabilities,
        on_attach = on_attach,
        settings = {
          Lua = {
            diagnostics = { globals = { "vim" } },
            workspace = { library = vim.api.nvim_get_runtime_file("", true) },
            telemetry = { enable = false },
          },
        },
      })

      lspconfig.gopls.setup({ capabilities = capabilities, on_attach = on_attach })
      lspconfig.golangci_lint_ls.setup({ capabilities = capabilities, on_attach = on_attach })
      lspconfig.jsonls.setup({ capabilities = capabilities, on_attach = on_attach, filetypes = { "json", "jsonc" } })
      lspconfig.ccls.setup({ capabilities = capabilities, on_attach = on_attach, filetypes = { "c", "cpp" } })
      lspconfig.pyright.setup({ capabilities = capabilities, on_attach = on_attach })
      lspconfig.phpactor.setup({ capabilities = capabilities, on_attach = on_attach })

      vim.api.nvim_create_autocmd("FileType", {
        pattern = "liquid",
        callback = function()
          vim.schedule(function()
            vim.cmd("LspStart theme_check")
            vim.cmd("LspStart html")
            vim.cmd("LspStart ts_ls") -- not essential\
          end)
        end,
      })
    end,
  },
}
