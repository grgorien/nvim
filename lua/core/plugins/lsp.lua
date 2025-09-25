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
      local capabilities = require("cmp_nvim_lsp").default_capabilities()
      capabilities.textDocument.completion.completionItem.snippetSupport = true
      capabilities.textDocument.completion.completionItem.resolveSupport = {
        properties = { "documentation", "detail", "additionalTextEdits" }
      }

      local on_attach = function(client, bufnr)
        vim.api.nvim_set_option_value('omnifunc', 'v:lua.vim.lsp.omnifunc', { buf = bufnr })
        vim.notify(client.name .. " attached to buffer " .. bufnr, vim.log.levels.INFO)
      end

      local function start_lsp_if_needed(config)
        local bufnr = vim.api.nvim_get_current_buf()
        local clients = vim.lsp.get_clients({ bufnr = bufnr, name = config.name })
        if #clients == 0 then
          vim.lsp.start(config)
        end
      end

      vim.api.nvim_create_autocmd("FileType", {
        pattern = "liquid",
        callback = function()
          start_lsp_if_needed({
            name = 'shopify_theme_ls',
            cmd = { "shopify", "theme", "language-server" },
            filetypes = { "liquid" },
            root_dir = vim.fs.find({ ".shopifyignore", ".theme-check.yml", ".theme-check.yaml", "shopify.theme.toml" }, { upward = true })[1],
            settings = {},
            capabilities = capabilities,
            on_attach = on_attach,
          })
        end,
      })

      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "go", "gomod", "gowork", "gotmpl" },
        callback = function()
          start_lsp_if_needed({
            name = 'gopls',
            cmd = { "gopls" },
            filetypes = { "go", "gomod", "gowork", "gotmpl" },
            root_dir = vim.fs.find({ "go.mod", "go.work", ".git" }, { upward = true })[1],
            settings = {},
            capabilities = capabilities,
            on_attach = on_attach,
          })
        end,
      })

      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "go", "gomod" },
        callback = function()
          start_lsp_if_needed({
            name = 'golangci_lint_ls',
            cmd = { "golangci-lint-langserver" },
            filetypes = { "go", "gomod" },
            root_dir = vim.fs.find({ "go.mod", ".git" }, { upward = true })[1],
            capabilities = capabilities,
            on_attach = on_attach,
          })
        end,
      })

      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "javascript", "typescript", "vue" },
        callback = function()
          start_lsp_if_needed({
            name = 'ts_ls',
            cmd = { "typescript-language-server", "--stdio" },
            filetypes = { "javascript", "typescript", "vue", "liquid" },
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
            capabilities = capabilities,
            on_attach = on_attach,
          })
        end,
      })

      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "html" },
        callback = function()
          start_lsp_if_needed({
            name = 'html',
            cmd = { "vscode-html-language-server", "--stdio" },
            filetypes = { "html", "liquid" },
            init_options = {
              configurationSection = { "html", "css", "javascript" },
              embeddedLanguages = { css = true, javascript = true },
              provideFormatter = false,
            },
            capabilities = capabilities,
            on_attach = on_attach,
          })
        end,
      })

      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "css", "scss", "less" },
        callback = function()
          start_lsp_if_needed({
            name = 'cssls',
            cmd = { "vscode-css-language-server", "--stdio" },
            filetypes = { "css", "scss", "less", "liquid" },
            settings = {
              css = {
                lint = { unknownAtRules = "ignore" } 
              }
            },
            capabilities = capabilities,
            on_attach = on_attach,
          })
        end,
      })

      vim.api.nvim_create_autocmd("FileType", {
        pattern = "lua",
        callback = function()
          start_lsp_if_needed({
            name = 'lua_ls',
            cmd = { "lua-language-server" },
            filetypes = { "lua" },
            root_dir = vim.fs.find({ ".luarc.json", ".luarc.jsonc", ".git" }, { upward = true })[1],
            settings = {
              Lua = {
                diagnostics = { globals = { "vim" } },
                workspace = { library = vim.api.nvim_get_runtime_file("", true) },
                telemetry = { enable = false },
              },
            },
            capabilities = capabilities,
            on_attach = on_attach,
          })
        end,
      })

      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "json", "jsonc" },
        callback = function()
          start_lsp_if_needed({
            name = 'jsonls',
            cmd = { "vscode-json-language-server", "--stdio" },
            filetypes = { "json", "jsonc" },
            capabilities = capabilities,
            on_attach = on_attach,
          })
        end,
      })

      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "c", "cpp" },
        callback = function()
          start_lsp_if_needed({
            name = 'ccls',
            cmd = { "ccls" },
            filetypes = { "c", "cpp" },
            root_dir = vim.fs.find({ "compile_commands.json", ".ccls", ".git" }, { upward = true })[1],
            capabilities = capabilities,
            on_attach = on_attach,
          })
        end,
      })

      vim.api.nvim_create_autocmd("FileType", {
        pattern = "python",
        callback = function()
          start_lsp_if_needed({
            name = 'pyright',
            cmd = { "pyright-langserver", "--stdio" },
            filetypes = { "python" },
            root_dir = vim.fs.find({ "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", "Pipfile", ".git" }, { upward = true })[1],
            capabilities = capabilities,
            on_attach = on_attach,
          })
        end,
      })

      vim.api.nvim_create_autocmd("FileType", {
        pattern = "php",
        callback = function()
          start_lsp_if_needed({
            name = 'phpactor',
            cmd = { "phpactor", "language-server" },
            filetypes = { "php" },
            root_dir = vim.fs.find({ "composer.json", ".git" }, { upward = true })[1],
            capabilities = capabilities,
            on_attach = on_attach,
          })
        end,
      })

      vim.api.nvim_create_autocmd("FileType", {
        pattern = "liquid",
        callback = function()
          vim.schedule(function()
            start_lsp_if_needed({
              name = 'html',
              cmd = { "vscode-html-language-server", "--stdio" },
              filetypes = { "html", "liquid" },
              init_options = {
                configurationSection = { "html", "css", "javascript" },
                embeddedLanguages = { css = true, javascript = true },
                provideFormatter = false,
              },
              capabilities = capabilities,
              on_attach = on_attach,
            })

            start_lsp_if_needed({
              name = 'cssls',
              cmd = { "vscode-css-language-server", "--stdio" },
              filetypes = { "css", "scss", "less", "liquid" },
              settings = {
                css = {
                  lint = { unknownAtRules = "ignore" }
                }
              },
              capabilities = capabilities,
              on_attach = on_attach,
            })

            start_lsp_if_needed({
              name = 'ts_ls',
              cmd = { "typescript-language-server", "--stdio" },
              filetypes = { "javascript", "typescript", "vue", "liquid" },
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
              capabilities = capabilities,
              on_attach = on_attach,
            })
          end)
        end,
      })
    end,
  },
}
