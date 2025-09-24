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
    -- this vim.lsp from require() -> framework issue changed
    config = function()
      local capabilities = require("cmp_nvim_lsp").default_capabilities()
      capabilities.textDocument.completion.completionItem.snippetSupport = true
      capabilities.textDocument.completion.completionItem.resolveSupport = {
        properties = { "documentation", "detail", "additionalTextEdits" }
      }

      local on_attach = function(client, bufnr)
        vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')
        vim.notify(client.name .. " attached to buffer " .. bufnr, vim.log.levels.INFO)
      end

      vim.lsp.enable('shopify_theme_ls', {
        cmd = { "shopify", "theme", "language-server" },
        filetypes = { "liquid" },
        root_dir = vim.fs.find({ ".shopifyignore", ".theme-check.yml", ".theme-check.yaml", "shopify.theme.toml" }, { upward = true })[1],
        settings = {},
        capabilities = capabilities,
        on_attach = on_attach,
      })

      vim.lsp.enable('gopls', {
        cmd = { "gopls" },
        filetypes = { "go", "gomod", "gowork", "gotmpl" },
        root_dir = vim.fs.find({ "go.mod", "go.work", ".git" }, { upward = true })[1],
        settings = {},
        capabilities = capabilities,
        on_attach = on_attach,
      })

      vim.lsp.enable('ts_ls', {
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

      vim.lsp.enable('html', {
        filetypes = { "html", "liquid" },
        init_options = {
          configurationSection = { "html", "css", "javascript" },
          embeddedLanguages = { css = true, javascript = true },
          provideFormatter = false,
        },
        capabilities = capabilities,
        on_attach = on_attach,
      })

      vim.lsp.enable('cssls', {
        filetypes = { "css", "scss", "less", "liquid" },
        settings = { css = { lint = { unknownAtRules = "ignore" } } },
        capabilities = capabilities,
        on_attach = on_attach,
      })

      vim.lsp.enable('lua_ls', {
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

      vim.lsp.enable('golangci_lint_ls', {
        capabilities = capabilities,
        on_attach = on_attach,
      })

      vim.lsp.enable('jsonls', {
        filetypes = { "json", "jsonc" },
        capabilities = capabilities,
        on_attach = on_attach,
      })

      vim.lsp.enable('ccls', {
        filetypes = { "c", "cpp" },
        capabilities = capabilities,
        on_attach = on_attach,
      })

      vim.lsp.enable('pyright', {
        capabilities = capabilities,
        on_attach = on_attach,
      })

      vim.lsp.enable('phpactor', {
        capabilities = capabilities,
        on_attach = on_attach,
      })

      -- Automatically start LSP servers for liquid files
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "liquid",
        callback = function()
          vim.schedule(function()
            vim.lsp.enable('shopify_theme_ls')
            vim.lsp.enable('html')
            vim.lsp.enable('ts_ls')
          end)
        end,
      })
    end,
  },
}
