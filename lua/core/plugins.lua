require("lazy").setup({
  { "catppuccin/nvim", name = "catppuccin", priority = 1000 },
  "tpope/vim-commentary",
  "mattn/emmet-vim",
  "ellisonleao/gruvbox.nvim",
  "dracula/vim",
  "nvim-lualine/lualine.nvim",
  {"nvim-treesitter/nvim-treesitter", build = ":TSUpdate"},
  "vim-test/vim-test",
  "lewis6991/gitsigns.nvim",
  "preservim/vimux",
  "christoomey/vim-tmux-navigator",
  "tpope/vim-fugitive",
  "tpope/vim-surround",
  "stevearc/oil.nvim",
  -- completion
  "hrsh7th/nvim-cmp",
  "hrsh7th/cmp-nvim-lsp",
  {"L3MON4D3/LuaSnip", build = "make install_jsregexp"},
  "saadparwaiz1/cmp_luasnip",
  "rafamadriz/friendly-snippets",
  "github/copilot.vim",
  "williamboman/mason.nvim",
  "williamboman/mason-lspconfig.nvim",
  "neovim/nvim-lspconfig",
  {
    "vinnymeller/swagger-preview.nvim",
    run = "npm install -g swagger-ui-watcher",
  },
  {
    "iamcco/markdown-preview.nvim",
    run = "cd app && npm install",
  },
  {
    "nvim-telescope/telescope.nvim", tag = "0.1.8",
    dependencies = { "nvim-lua/plenary.nvim" }
  },
  {
    "epwalsh/obsidian.nvim", version = "*",
    lazy = true,
    ft = "markdown",
    dependencies = {"nvim-lua/plenary.nvim"},
    opts = {
      workspaces = {
        {
          name = "personal",
          path = "~/personal",
        },
        {
          name = "work",
          path = "~/work",
        },
      },
    },
  },
})
