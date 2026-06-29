vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.smartindent = true

vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = true
vim.opt.incsearch = true
vim.opt.clipboard = "unnamedplus"

local map = vim.keymap.set
map("n", "<leader>w", "<cmd>w<CR>")
map("n", "<leader>q", "<cmd>q<CR>")
map("n", "<leader><Esc>", "<cmd>Dired<CR>", { desc = "dired fs active" })

vim.pack.add({
	{ src = "https://github.com/MunifTanjim/nui.nvim", name = "nui" },
	{ src = "https://github.com/X3eRo0/dired.nvim", name = "dired" },
	{ src = "https://github.com/blazkowolf/gruber-darker.nvim", name = "gruber" },

})


require("dired").setup({
	path_separator = "/",
	show_banner = false,
	show_icons = false,
	show_hidden = true,
	show_dot_dirs = true,
	show_colors = true,

	keybinds = {
		dired_enter = "<CR>",
		dired_back = "-",
		dired_up = "_",
		dired_rename = "R",
		dired_quit = "q",
	},
})

vim.cmd.colorscheme("gruber-darker")
require("gruber-darker").setup({
	opts = {
		bold = false,
		italic = {
			strings = false,
		},
	}
})
