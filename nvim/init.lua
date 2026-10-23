-- ============================================================================
-- NvChad Configuration - Uncomment to Enable Version
-- ============================================================================
-- REQUIRED: Create ~/.config/nvim/lua/chadrc.lua (see Quick Start Guide below)
-- Then uncomment what you want and restart Neovim.
-- ============================================================================

-- Set leader key before anything else
vim.g.mapleader = " "
vim.g.base46_cache = vim.fn.stdpath("data") .. "/base46/"

-- ============================================================================
-- Bootstrap lazy.nvim Plugin Manager
-- ============================================================================
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.uv.fs_stat(lazypath) then
	local repo = "https://github.com/folke/lazy.nvim.git"
	vim.fn.system({ "git", "clone", "--filter=blob:none", repo, "--branch=stable", lazypath })
end

vim.opt.rtp:prepend(lazypath)

-- ============================================================================
-- Lazy.nvim Configuration
-- ============================================================================
local lazy_config = {
	defaults = { lazy = true },
	install = { colorscheme = { "nvchad" } },
	ui = {
		icons = {
			ft = "",
			lazy = "󰂠 ",
			loaded = "",
			not_loaded = "",
		},
	},
	performance = {
		rtp = {
			disabled_plugins = {
				"2html_plugin",
				"tohtml",
				"getscript",
				"getscriptPlugin",
				"gzip",
				"logipat",
				"netrw",
				"netrwPlugin",
				"netrwSettings",
				"netrwFileHandlers",
				"matchit",
				"tar",
				"tarPlugin",
				"rrhelper",
				"spellfile_plugin",
				"vimball",
				"vimballPlugin",
				"zip",
				"zipPlugin",
				"tutor",
				"rplugin",
				"syntax",
				"synmenu",
				"optwin",
				"compiler",
				"bugreport",
				"ftplugin",
			},
		},
	},
}

-- ============================================================================
-- Plugin Specifications
-- ============================================================================
require("lazy").setup({
	-- =========================================================================
	-- NvChad Base (UI, Themes, Core Features)
	-- =========================================================================
	{
		"NvChad/NvChad",
		lazy = false,
		branch = "v2.5",
		import = "nvchad.plugins",
	},

	-- =========================================================================
	-- Mason: LSP/Formatter/Linter Package Manager
	-- INSTRUCTIONS: Uncomment the tools you want to use below
	-- Save and restart Neovim - uncommented tools will auto-install!
	-- =========================================================================
	{
		"williamboman/mason.nvim",
		event = "VeryLazy",
		cmd = { "Mason", "MasonInstall", "MasonUpdate" },
		opts = {
			ensure_installed = {
				-- ==========================================
				-- 📝 UNCOMMENT THE LANGUAGES YOU NEED
				-- ==========================================

				--  Lua (Neovim config)
				"lua-language-server",
				"stylua",

				--  C/C++
				"clangd",
				"clang-format",
				"codelldb", -- Debugger

				--  Python
				"pyright",
				"black",
				"isort",
				"ruff", -- Linter
				"debugpy", -- Debugger

				--  JavaScript/TypeScript
				"typescript-language-server",
				"prettier",
				"eslint-lsp",
				"eslint_d", -- Fast linter

				-- 🔷 Web Development (HTML/CSS)
				"html-lsp",
				"css-lsp",
				"emmet-ls",
				-- "prettier",              -- Already listed above if using JS
			},
		},
		config = function(_, opts)
			require("mason").setup(opts)
			local mr = require("mason-registry")

			-- Use a simple function to trigger installs
			local function ensure_installed()
				for _, tool in ipairs(opts.ensure_installed) do
					local p = mr.get_package(tool)
					if not p:is_installed() then
						p:install()
					end
				end
			end

			-- If registry is already loaded, run now. If not, refresh then run.
			if mr.refresh then
				mr.refresh(ensure_installed)
			else
				ensure_installed()
			end
		end,
	},

	-- =========================================================================
	-- LSP Configuration
	-- INSTRUCTIONS: Uncomment the LSP servers that match your Mason tools above
	-- =========================================================================
	{
		"neovim/nvim-lspconfig",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			require("nvchad.configs.lspconfig").defaults()

			-- ==========================================
			-- 📝 UNCOMMENT THE LSP SERVERS YOU NEED
			-- ==========================================
			local servers = {
				--  Lua
				"lua_ls",

				--  C/C++
				"clangd",

				--  Python
				"pyright",

				--  JavaScript/TypeScript
				"ts_ls",

				--  HTML/CSS
				"html",
				"cssls",

				--  ESLint (JS/TS linting)
				"eslint",
			}

			vim.lsp.enable(servers)

			--  Emmet (HTML/CSS snippets) - Uncomment if using web dev
			vim.lsp.config("emmet_ls", {
				filetypes = { "html", "css", "javascriptreact", "typescriptreact" },
			})
			vim.lsp.enable("emmet_ls")
		end,
	},

	-- =========================================================================
	-- Treesitter: Advanced Syntax Highlighting & Parsing
	-- INSTRUCTIONS: Uncomment parsers for languages you use
	-- =========================================================================
	{
		"nvim-treesitter/nvim-treesitter",
		opts = {
			ensure_installed = {
				"lua",
				"vim",
				"vimdoc",
				"markdown", -- useful for READMEs
			},
		},
	},
	-- =========================================================================
	-- Conform: Code Formatting
	-- INSTRUCTIONS: Formatters are already configured - they work automatically
	-- if you've uncommented the corresponding Mason tools above
	-- =========================================================================
	{
		"stevearc/conform.nvim",
		event = "BufWritePre",
		opts = {
			formatters_by_ft = {
				lua = { "stylua" },
				c = { "clang-format" },
				cpp = { "clang-format" },
				python = { "isort", "black" },
				javascript = { "prettier" },
				typescript = { "prettier" },
				javascriptreact = { "prettier" },
				typescriptreact = { "prettier" },
				html = { "prettier" },
				css = { "prettier" },
				json = { "prettier" },
				markdown = { "prettier" },
			},

			format_on_save = {
				timeout_ms = 500,
				lsp_fallback = false,
			},
		},
	},

	-- =========================================================================
	-- nvim-lint: Additional Linting
	-- INSTRUCTIONS: Linters work automatically if Mason tools are uncommented
	-- =========================================================================
	{
		"mfussenegger/nvim-lint",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			local lint = require("lint")

			lint.linters_by_ft = {
				python = { "ruff" },
				javascript = { "eslint_d" },
				typescript = { "eslint_d" },
				javascriptreact = { "eslint_d" },
				typescriptreact = { "eslint_d" },
			}

			local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })
			vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
				group = lint_augroup,
				callback = function()
					lint.try_lint()
				end,
			})
		end,
	},

	-- =========================================================================
	-- Completion with Custom Keybindings
	-- =========================================================================
	{
		"hrsh7th/nvim-cmp",
		event = "InsertEnter",
		opts = function(_, opts)
			local cmp = require("cmp")

			opts.mapping = vim.tbl_deep_extend("force", opts.mapping, {
				["<Up>"] = cmp.mapping.select_prev_item(),
				["<Down>"] = cmp.mapping.select_next_item(),
			})

			return opts
		end,
	},

	-- =========================================================================
	-- nvim-dap: Debugging Support
	-- INSTRUCTIONS: Debuggers work automatically if uncommented in Mason
	-- =========================================================================
	{
		"mfussenegger/nvim-dap",
		dependencies = {
			"rcarriga/nvim-dap-ui",
			"theHamsta/nvim-dap-virtual-text",
		},
		keys = {
			{
				"<leader>db",
				function()
					require("dap").toggle_breakpoint()
				end,
				desc = "Toggle Breakpoint",
			},
			{
				"<leader>dc",
				function()
					require("dap").continue()
				end,
				desc = "Continue",
			},
			{
				"<leader>di",
				function()
					require("dap").step_into()
				end,
				desc = "Step Into",
			},
			{
				"<leader>do",
				function()
					require("dap").step_over()
				end,
				desc = "Step Over",
			},
			{
				"<leader>dO",
				function()
					require("dap").step_out()
				end,
				desc = "Step Out",
			},
			{
				"<leader>dr",
				function()
					require("dap").repl.open()
				end,
				desc = "Open REPL",
			},
			{
				"<leader>du",
				function()
					require("dapui").toggle()
				end,
				desc = "Toggle DAP UI",
			},
		},
		config = function()
			local dap = require("dap")

			-- Python debugger configuration
			dap.adapters.python = {
				type = "executable",
				command = "debugpy-adapter",
			}

			dap.configurations.python = {
				{
					type = "python",
					request = "launch",
					name = "Launch file",
					program = "${file}",
					pythonPath = function()
						return "python"
					end,
				},
			}

			-- C/C++ debugger configuration (CodeLLDB)
			dap.adapters.codelldb = {
				type = "server",
				port = "${port}",
				executable = {
					command = vim.fn.stdpath("data") .. "/mason/bin/codelldb",
					args = { "--port", "${port}" },
				},
			}

			dap.configurations.c = {
				{
					name = "Launch",
					type = "codelldb",
					request = "launch",
					program = function()
						return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
					end,
					cwd = "${workspaceFolder}",
					stopOnEntry = false,
				},
			}

			dap.configurations.cpp = dap.configurations.c

			-- Setup DAP UI
			require("dapui").setup()
			require("nvim-dap-virtual-text").setup()
		end,
	},
}, lazy_config)

-- ============================================================================
-- Theme & UI
-- ============================================================================
dofile(vim.g.base46_cache .. "defaults")
dofile(vim.g.base46_cache .. "statusline")

-- ============================================================================
-- Options
-- ============================================================================
require("nvchad.options")

-- Custom options
vim.o.cursorlineopt = "both"

-- ============================================================================
-- Autocommands
-- ============================================================================
require("nvchad.autocmds")

-- ============================================================================
-- Key Mappings
-- ============================================================================
vim.schedule(function()
	require("nvchad.mappings")

	local map = vim.keymap.set

	-- General keybindings
	map("n", ";", ":", { desc = "Enter command mode" })
	map("i", "jk", "<ESC>", { desc = "Exit insert mode" })

	-- LSP keybindings
	map("n", "gd", vim.lsp.buf.definition, { desc = "Go to definition" })
	map("n", "gr", vim.lsp.buf.references, { desc = "Show references" })
	map("n", "K", vim.lsp.buf.hover, { desc = "Show hover info" })
	map("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "Code actions" })
	map("n", "<leader>rn", vim.lsp.buf.rename, { desc = "Rename symbol" })
	map("n", "[d", function()
		vim.diagnostic.jump({ count = -1 })
	end, { desc = "Previous diagnostic" })
	map("n", "]d", function()
		vim.diagnostic.jump({ count = 1 })
	end, { desc = "Next diagnostic" })

	-- Format keybinding
	map("n", "<leader>fm", function()
		require("conform").format({ lsp_fallback = true })
	end, { desc = "Format file" })
end)

-- ============================================================================
-- 📝 QUICK START GUIDE
-- ============================================================================
-- FIRST TIME SETUP (One-time only):
-- ----------------------------------
-- 1. Create file: ~/.config/nvim/lua/chadrc.lua
-- 2. Add this content:
--
--    ---@type ChadrcConfig
--    local M = {}
--
--    M.base46 = {
--      theme = "onedark",
--    }
--
--    return M
--
-- 3. Save and restart Neovim
--
-- AFTER SETUP - Using This Config:
-- ----------------------------------
-- 1. Uncomment tools in Mason section (line ~105)
-- 2. Uncomment matching LSP servers (line ~150)
-- 3. Uncomment Treesitter parsers (line ~185)
-- 4. Save and restart Neovim → Auto-installs!
--
-- Example: To enable Python support
-- ✅ Uncomment: "pyright", "black", "isort", "ruff", "debugpy" in Mason
-- ✅ Uncomment: "pyright" in LSP servers
-- ✅ Uncomment: "python" in Treesitter
-- ✅ Save and restart → Python support ready!
--
-- Available themes: onedark, gruvbox, catppuccin, tokyonight, nord, everforest
-- Change theme in lua/chadrc.lua
-- ============================================================================
