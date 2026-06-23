-- ==========================================================================
-- Neovim Configuration (lazy.nvim)
-- Ported from vimrc_v1 + modern plugin equivalents
-- ==========================================================================

-- ==========================================================================
-- 1. CORE SETTINGS (from your vimrc_v1)
-- ==========================================================================
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Silence ONE known-benign deprecation: nvim-lspconfig and the unmaintained
-- copilot-cmp still call `client.is_stopped()` (dot) instead of the new
-- `client:is_stopped()` method on Neovim 0.12+. Functionality is fine; this is
-- just noise. Scoped to that single message so real deprecations still surface.
-- Remove once both plugins migrate (or if copilot-cmp is dropped).
do
  local orig_deprecate = vim.deprecate
  vim.deprecate = function(name, ...)
    if type(name) == "string" and name:find("is_stopped", 1, true) then return end
    return orig_deprecate(name, ...)
  end
end

local opt = vim.opt
opt.number         = true           -- line numbers
opt.relativenumber = false           -- relative line numbers
opt.clipboard      = "unnamedplus"  -- system clipboard
opt.expandtab      = true           -- spaces instead of tabs
opt.tabstop        = 2
opt.softtabstop    = 2
opt.shiftwidth     = 2
opt.autoindent     = true
opt.smartindent    = true
opt.hidden         = true           -- allow hidden buffers
opt.colorcolumn    = "80"           -- 80 char column marker
opt.termguicolors  = true           -- 24-bit colors
opt.signcolumn     = "yes"          -- always show sign column
opt.cursorline     = true           -- highlight current line
opt.scrolloff      = 8              -- keep 8 lines visible above/below cursor
opt.sidescrolloff  = 8
opt.wrap           = false          -- no line wrap
opt.ignorecase     = true           -- case insensitive search
opt.smartcase      = true           -- unless uppercase used
opt.splitright     = true           -- vertical splits open right
opt.splitbelow     = true           -- horizontal splits open below
opt.undofile       = true           -- persistent undo
opt.updatetime     = 250            -- faster CursorHold events
opt.mouse          = "a"            -- mouse support

-- Fold settings (from your vimrc_v1)
opt.foldmethod     = "expr"
opt.foldexpr       = "v:lua.vim.treesitter.foldexpr()"
opt.foldnestmax    = 10
opt.foldenable     = false          -- don't fold by default
opt.foldlevel      = 99

-- Trailing whitespace highlight
vim.cmd([[
  highlight ExtraWhitespace ctermbg=red guibg=red
  match ExtraWhitespace /\s\+$/
  autocmd BufWinEnter * match ExtraWhitespace /\s\+$/
  autocmd InsertEnter * match ExtraWhitespace /\s\+\%#\@<!$/
  autocmd InsertLeave * match ExtraWhitespace /\s\+$/
  autocmd BufWinLeave * call clearmatches()
]])

-- File type autocmds (from your vimrc_v1)
vim.cmd([[
  autocmd BufNewFile,BufRead *.slim set ft=slim
  autocmd BufRead,BufNewFile *.md set filetype=markdown
  autocmd BufNewFile,BufRead *.haml setl foldmethod=indent nofoldenable
]])

-- Ensure rbenv/mise/pyenv actual binaries are in PATH (so Mason finds correct Ruby/Node)
-- NOTE: shims alone don't work in headless nvim — we need the real binary dirs
local home = os.getenv("HOME") or ""

-- Detect rbenv global Ruby version and add its real bin directory
local rbenv_root = home .. "/.rbenv"
local rbenv_bin = nil
local rbenv_version_file = rbenv_root .. "/version"
local f = io.open(rbenv_version_file, "r")
if f then
  local version = f:read("*l")
  f:close()
  if version then
    version = version:match("^%s*(.-)%s*$") -- trim whitespace
    local candidate = rbenv_root .. "/versions/" .. version .. "/bin"
    if vim.fn.isdirectory(candidate) == 1 then
      rbenv_bin = candidate
    end
  end
end

-- Detect pyenv global Python version and add its real bin directory
local pyenv_root = home .. "/.pyenv"
local pyenv_bin = nil
local pyenv_version_file = pyenv_root .. "/version"
local pf = io.open(pyenv_version_file, "r")
if pf then
  local version = pf:read("*l")
  pf:close()
  if version then
    version = version:match("^%s*(.-)%s*$")
    local candidate = pyenv_root .. "/versions/" .. version .. "/bin"
    if vim.fn.isdirectory(candidate) == 1 then
      pyenv_bin = candidate
    end
  end
end

local extra_paths = {
  rbenv_bin,                                 -- actual rbenv Ruby binary (e.g. ~/.rbenv/versions/3.1.1/bin)
  rbenv_root .. "/shims",                    -- rbenv shims (fallback)
  pyenv_bin,                                 -- actual pyenv Python binary
  pyenv_root .. "/shims",                    -- pyenv shims (fallback)
  home .. "/.local/share/mise/shims",        -- mise shims
  home .. "/.nvm/versions/node",             -- nvm
  "/opt/homebrew/bin",                       -- Homebrew (Apple Silicon)
}
local current_path = vim.env.PATH or ""
for i = #extra_paths, 1, -1 do
  local p = extra_paths[i]
  if p and vim.fn.isdirectory(p) == 1 and not current_path:find(p, 1, true) then
    vim.env.PATH = p .. ":" .. current_path
    current_path = vim.env.PATH
  end
end

-- ==========================================================================
-- 2. BOOTSTRAP LAZY.NVIM
-- ==========================================================================
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- ==========================================================================
-- 3. PLUGINS
-- ==========================================================================
require("lazy").setup({
  spec = {

    -- ===================== Colorscheme =====================
    {
      "ellisonleao/gruvbox.nvim",
      priority = 1000,
      config = function()
        require("gruvbox").setup({
          transparent_mode = true, -- transparent editor bg (terminal shows through)
          contrast = "hard",
          overrides = {
            -- Keep statusline backgrounds SOLID so powerline arrows render correctly
            StatusLine = { bg = "#3c3836", fg = "#ebdbb2" },
            StatusLineNC = { bg = "#1d2021", fg = "#665c54" },
          },
        })
        vim.cmd("colorscheme gruvbox")

        -- Transparent background for editor only (NOT statusline)
        vim.cmd([[
          highlight Normal guibg=NONE ctermbg=NONE
          highlight NonText guibg=NONE ctermbg=NONE
          highlight NormalNC guibg=NONE ctermbg=NONE
          highlight EndOfBuffer guibg=NONE ctermbg=NONE
        ]])

        -- Lualine handles its own mode display, hide Neovim's -- INSERT -- etc
        vim.opt.showmode = false
      end,
    },

    -- ===================== File Explorer (NERDTree replacement) =====================
    {
      "nvim-neo-tree/neo-tree.nvim",
      branch = "v3.x",
      dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-tree/nvim-web-devicons",
        "MunifTanjim/nui.nvim",
      },
      config = function()
        require("neo-tree").setup({
          close_if_last_window = true, -- same as NERDTree autocmd
          filesystem = {
            follow_current_file = { enabled = true },
            hijack_netrw_behavior = "open_current",
            filtered_items = {
              visible = true,
              hide_dotfiles = false,   -- NERDTreeShowHidden=1
              hide_gitignored = false,
            },
          },
          window = {
            width = 35,
            mappings = {
              ["<space>"] = "none",
            },
          },
          default_component_configs = {
            git_status = {
              symbols = {
                added     = "",
                modified  = "",
                deleted   = "",
                renamed   = "➜",
                untracked = "★",
                ignored   = "◌",
                unstaged  = "✗",
                staged    = "✓",
                conflict  = "",
              },
            },
          },
        })
      end,
    },

    -- ===================== Fuzzy Finder (fzf.vim replacement) =====================
    {
      "nvim-telescope/telescope.nvim",
      dependencies = { "nvim-lua/plenary.nvim" },
      config = function()
        local actions = require("telescope.actions")
        require("telescope").setup({
          defaults = {
            vimgrep_arguments = {
              "rg", "--color=never", "--no-heading", "--with-filename",
              "--line-number", "--column", "--smart-case",
              "--fixed-strings",  -- treat pattern as literal (so { } work)
            },

            -- Fullscreen layout: use 99% of screen, wide preview showing lots of code
            layout_strategy = "flex",                 -- horizontal on wide terms, vertical on narrow
            layout_config = {
              width = 0.99,                            -- 99% of screen width
              height = 0.97,                           -- 97% of screen height
              preview_cutoff = 20,                     -- always show preview unless tiny
              prompt_position = "top",
              horizontal = {
                preview_width = 0.65,                  -- 65% of window = preview (more code)
              },
              vertical = {
                preview_height = 0.7,                  -- 70% preview when stacked
                mirror = false,
              },
              flex = {
                flip_columns = 140,                    -- switch to vertical below 140 cols
              },
            },

            sorting_strategy = "ascending",            -- results grow top-down (pairs w/ prompt_position=top)
            path_display = { "truncate" },             -- shorten long paths
            dynamic_preview_title = true,
            preview = {
              filesize_limit = 1,                      -- don't preview files > 1MB
              timeout = 250,
            },
            border = true,
            borderchars = {
              "─", "│", "─", "│", "┌", "┐", "┘", "└",  -- clean box borders
            },

            -- ESC closes directly in insert mode (no need for double-tap)
            mappings = {
              i = {
                ["<Esc>"] = actions.close,
                ["<C-u>"] = false,                     -- let <C-u> clear the prompt instead
                ["<C-j>"] = actions.move_selection_next,
                ["<C-k>"] = actions.move_selection_previous,
              },
            },
          },
          pickers = {
            find_files = {
              hidden = true,                           -- show dotfiles
              find_command = {
                "fd", "--type", "f", "--hidden",
                "--exclude", ".git",
                "--exclude", "node_modules",
                "--exclude", ".bundle",
                "--exclude", "target",
              },
            },
            buffers = {
              sort_lastused = true,
              mappings = {
                i = { ["<C-d>"] = actions.delete_buffer },
              },
            },
          },
        })
      end,
    },

    -- ===================== Syntax Highlighting =====================
    -- NOTE: On the "main" branch (Neovim 0.10+/0.12+), nvim-treesitter is
    -- primarily a parser installer. Highlight/indent are built into Neovim.
    {
      "nvim-treesitter/nvim-treesitter",
      branch = "main",
      lazy = false,
      build = ":TSUpdate",
      config = function()
        require("nvim-treesitter").setup({
          ensure_installed = {
            "c", "lua", "ruby", "python", "javascript", "typescript",
            "html", "css", "json", "yaml", "toml", "bash", "dockerfile",
            "vim", "vimdoc", "query", "markdown", "markdown_inline",
            "terraform", "go", "rust",
          },
          sync_install = false,
          auto_install = true,
        })
        -- Treesitter highlight & indent are now built-in to Neovim 0.12+
        -- They are enabled by default; disable for very large files via autocmd
        vim.api.nvim_create_autocmd("FileType", {
          callback = function(args)
            local max_filesize = 100 * 1024 -- 100 KB
            local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(args.buf))
            if ok and stats and stats.size > max_filesize then
              vim.treesitter.stop(args.buf)
            end
          end,
        })
      end,
    },

    -- ===================== Treesitter endwise (vim-endwise) =====================
    { "RRethy/nvim-treesitter-endwise" },

    -- ===================== Git: fugitive (same as your vimrc_v1) =====================
    {
      "tpope/vim-fugitive",
      cmd = { "G", "Git", "Gvdiffsplit", "Gdiffsplit", "Gread", "Gwrite", "GBrowse" },
      keys = {
        { "gs", ":tab G<CR>",    desc = "Git status (tab)" },
        { "gb", ":G blame<CR>",  desc = "Git blame", mode = { "n", "v" } },
      },
    },
    { "tpope/vim-rhubarb" }, -- GitHub support for :GBrowse

    -- ===================== Git: gitsigns (vim-gitgutter replacement) =====================
    {
      "lewis6991/gitsigns.nvim",
      config = function()
        require("gitsigns").setup({
          signs = {
            add          = { text = "│" },
            change       = { text = "│" },
            delete       = { text = "_" },
            topdelete    = { text = "‾" },
            changedelete = { text = "~" },
          },
          current_line_blame = true,
          current_line_blame_opts = {
            delay = 300,
            virt_text_pos = "eol",
          },
          current_line_blame_formatter = "   <author>, <author_time:%R> • <summary>",
        })
        -- Dim the blame text so it doesn't look like real code
        -- Gruvbox bg3 (#665c54) — visible but clearly secondary
        vim.api.nvim_set_hl(0, "GitSignsCurrentLineBlame", { fg = "#665c54", italic = true })
      end,
    },

    -- ===================== Status Line (vim-airline replacement) =====================
    {
      "nvim-lualine/lualine.nvim",
      dependencies = { "nvim-tree/nvim-web-devicons" },
      config = function()
        -- Custom components
        local function lsp_clients()
          local clients = vim.lsp.get_clients({ bufnr = 0 })
          local names = {}
          for _, client in ipairs(clients) do
            if client.name ~= "copilot" then       -- shown by its own indicator
              table.insert(names, client.name)
            end
          end
          if #names == 0 then return "" end
          return " " .. table.concat(names, ", ")
        end

        local function macro_recording()
          local reg = vim.fn.reg_recording()
          if reg ~= "" then return "󰑋 @" .. reg end
          return ""
        end

        local function search_count()
          if vim.v.hlsearch == 0 then return "" end
          local ok, result = pcall(vim.fn.searchcount, { maxcount = 999 })
          if ok and result.total > 0 then
            return string.format(" %d/%d", result.current, result.total)
          end
          return ""
        end

        local function indent_info()
          if vim.bo.expandtab then
            return "␣ " .. vim.bo.shiftwidth
          else
            return "⇥ " .. vim.bo.tabstop
          end
        end

        -- Current mode's section-a bg color (used to tint the rounded outer caps)
        local function mode_bg()
          local map = {
            n = "#fe8019", i = "#b8bb26", v = "#d3869b", V = "#d3869b", [""] = "#d3869b",
            c = "#fabd2f", R = "#fb4934", t = "#8ec07c", s = "#d3869b", S = "#d3869b",
          }
          return map[vim.fn.mode()] or "#fe8019"
        end
        local statusline_bg = "#1d2021"  -- matches tmux bar bg / gruvbox bg0_h

        -- Gruvbox Powerline theme — matches tmux bar exactly
        -- tmux left:  orange(#fe8019) > purple(#d3869b) > green(#b8bb26)
        -- tmux right: bg1(#3c3836) < bg2(#504945) < aqua(#8ec07c)
        -- tmux bar bg: #1d2021, active window: blue(#83a598)
        local gruvbox_powerline = {
          normal = {
            a = { bg = "#fe8019", fg = "#1d2021", gui = "bold" },  -- orange (matches tmux session)
            b = { bg = "#504945", fg = "#ebdbb2" },                -- bg2 (matches tmux right sec 2)
            c = { bg = "#3c3836", fg = "#a89984" },                -- bg1 (matches tmux right sec 1)
          },
          insert = {
            a = { bg = "#b8bb26", fg = "#1d2021", gui = "bold" },  -- green (matches tmux left sec 3)
            b = { bg = "#504945", fg = "#ebdbb2" },
            c = { bg = "#3c3836", fg = "#a89984" },
          },
          visual = {
            a = { bg = "#d3869b", fg = "#1d2021", gui = "bold" },  -- purple (matches tmux left sec 2)
            b = { bg = "#504945", fg = "#ebdbb2" },
            c = { bg = "#3c3836", fg = "#a89984" },
          },
          replace = {
            a = { bg = "#fb4934", fg = "#1d2021", gui = "bold" },  -- red
            b = { bg = "#504945", fg = "#ebdbb2" },
            c = { bg = "#3c3836", fg = "#a89984" },
          },
          command = {
            a = { bg = "#fabd2f", fg = "#1d2021", gui = "bold" },  -- yellow (matches tmux messages)
            b = { bg = "#504945", fg = "#ebdbb2" },
            c = { bg = "#3c3836", fg = "#a89984" },
          },
          terminal = {
            a = { bg = "#8ec07c", fg = "#1d2021", gui = "bold" },  -- aqua (matches tmux hostname)
            b = { bg = "#504945", fg = "#ebdbb2" },
            c = { bg = "#3c3836", fg = "#a89984" },
          },
          inactive = {
            a = { bg = "#3c3836", fg = "#a89984" },
            b = { bg = "#3c3836", fg = "#a89984" },
            c = { bg = "#1d2021", fg = "#665c54" },                -- darkest bg matches tmux bar bg
          },
        }

        require("lualine").setup({
          options = {
            theme = gruvbox_powerline,
            globalstatus = true,                                     -- single statusline for all windows
            section_separators = { left = "\u{e0b0}", right = "\u{e0b2}" },  --  pointed >  <
            component_separators = { left = "\u{e0b1}", right = "\u{e0b3}" }, --  thin >  <
            disabled_filetypes = {
              statusline = { "neo-tree", "lazy", "mason" },
            },
          },
          sections = {
            lualine_a = {
              {
                function() return "\u{e0b6}" end,                    --  rounded left cap "("
                color = function() return { fg = mode_bg(), bg = statusline_bg } end,
                padding = 0,
                separator = { right = "" },                          -- no powerline arrow between cap and mode
              },
              { "mode", fmt = function(s) return s:sub(1, 3) end },  -- NOR / INS / VIS / CMD
            },
            lualine_b = {
              { "branch", icon = "" },
              {
                "diff",
                symbols = { added = " ", modified = " ", removed = " " },
                colored = true,
              },
              {
                "diagnostics",
                sources = { "nvim_diagnostic" },
                symbols = { error = " ", warn = " ", info = " ", hint = "󰌵 " },
                colored = true,
              },
            },
            lualine_c = {
              {
                "filename",
                path = 1,                   -- relative path
                symbols = {
                  modified = " ●",          -- unsaved changes
                  readonly = " 󰌾",          -- read-only
                  unnamed  = "[No Name]",
                  newfile  = "[New]",
                },
              },
              { macro_recording, color = { fg = "#fb4934" } },    -- red macro indicator
              { search_count, color = { fg = "#fabd2f" } },       -- yellow search count
            },
            lualine_x = {
              { lsp_clients, color = { fg = "#8ec07c" } },        -- aqua LSP names
              {
                function()
                  local ok, clients = pcall(vim.lsp.get_clients, { name = "copilot" })
                  if ok and clients and #clients > 0 then return " " end
                  return ""
                end,
                color = { fg = "#8ec07c" },
              },
              { indent_info },
              { "encoding", fmt = function(s) return s ~= "utf-8" and s or "" end },  -- hide utf-8 (default)
              {
                "fileformat",
                symbols = { unix = "", dos = "", mac = "" },
                fmt = function(s) return s ~= "" and s or "" end,  -- hide unix (default)
              },
              { "filetype", colored = true, icon_only = false },
            },
            lualine_y = {
              { "progress", fmt = function(s) return s == "Top" and "TOP" or s == "Bot" and "BOT" or s end },
            },
            lualine_z = {
              { "location", fmt = function(s) return " " .. s:gsub("%s+", "") end },
              {
                function() return "\u{e0b4}" end,                    --  rounded right cap ")"
                color = function() return { fg = mode_bg(), bg = statusline_bg } end,
                padding = 0,
                separator = { left = "" },                           -- no powerline arrow between location and cap
              },
            },
          },
          inactive_sections = {
            lualine_a = {},
            lualine_b = {},
            lualine_c = { { "filename", path = 1 } },
            lualine_x = { "location" },
            lualine_y = {},
            lualine_z = {},
          },
          tabline = {},
          winbar = {},
          extensions = { "neo-tree", "fugitive", "lazy", "mason", "quickfix" },
        })
      end,
    },

    -- ===================== LSP (LanguageClient replacement) =====================
    {
      "neovim/nvim-lspconfig",
      dependencies = {
        "mason-org/mason.nvim",
        "mason-org/mason-lspconfig.nvim",
      },
      config = function()
        require("mason").setup()
        require("mason-lspconfig").setup({
          ensure_installed = {
            "lua_ls",           -- Lua
            "ruby_lsp",         -- Ruby (solargraph replacement)
            "ts_ls",            -- TypeScript/JavaScript
            "pyright",          -- Python
          },
          automatic_enable = true,
        })

        -- Ruby LSP: use global gem, skip project bundle when private gem sources are unreachable
        vim.lsp.config("ruby_lsp", {
          init_options = {
            enabledFeatures = {
              "codeActions",
              "codeLens",
              "completion",
              "definition",
              "diagnostics",
              "documentHighlights",
              "documentLink",
              "documentSymbols",
              "foldingRanges",
              "formatting",
              "hover",
              "inlayHint",
              "onTypeFormatting",
              "selectionRanges",
              "semanticHighlighting",
              "signatureHelp",
            },
          },
          cmd = { vim.fn.expand("~/.rbenv/versions/3.1.1/bin/ruby-lsp") },
        })

        -- Global LSP keybindings
        vim.api.nvim_create_autocmd("LspAttach", {
          callback = function(args)
            local buf = args.buf
            local map = function(mode, lhs, rhs, desc)
              vim.keymap.set(mode, lhs, rhs, { buffer = buf, desc = desc })
            end
            map("n", "K",          vim.lsp.buf.hover,          "Hover docs")
            map("n", "gd",         vim.lsp.buf.definition,     "Go to definition")
            map("n", "gD",         vim.lsp.buf.declaration,    "Go to declaration")
            map("n", "gi",         vim.lsp.buf.implementation, "Go to implementation")
            map("n", "gr",         vim.lsp.buf.references,     "References")
            map("n", "<F2>",       vim.lsp.buf.rename,         "Rename symbol")
            map("n", "<leader>ca", vim.lsp.buf.code_action,    "Code action")
            map("n", "<leader>D",  vim.lsp.buf.type_definition,"Type definition")
            map("n", "[d",         vim.diagnostic.goto_prev,   "Prev diagnostic")
            map("n", "]d",         vim.diagnostic.goto_next,   "Next diagnostic")
          end,
        })
      end,
    },

    -- ===================== Autocompletion (deoplete replacement) =====================
    {
      "hrsh7th/nvim-cmp",
      dependencies = {
        "hrsh7th/cmp-nvim-lsp",
        "hrsh7th/cmp-buffer",
        "hrsh7th/cmp-path",
        "L3MON4D3/LuaSnip",
        "saadparwaiz1/cmp_luasnip",
        "rafamadriz/friendly-snippets",
        "zbirenbaum/copilot-cmp",
      },
      config = function()
        local cmp = require("cmp")
        local luasnip = require("luasnip")
        require("luasnip.loaders.from_vscode").lazy_load()

        cmp.setup({
          snippet = {
            expand = function(args)
              luasnip.lsp_expand(args.body)
            end,
          },
          mapping = cmp.mapping.preset.insert({
            -- TAB to cycle (like your deoplete TAB mapping)
            ["<Tab>"] = cmp.mapping(function(fallback)
              if cmp.visible() then
                cmp.select_next_item()
              elseif luasnip.expand_or_jumpable() then
                luasnip.expand_or_jump()
              else
                fallback()
              end
            end, { "i", "s" }),
            ["<S-Tab>"] = cmp.mapping(function(fallback)
              if cmp.visible() then
                cmp.select_prev_item()
              elseif luasnip.jumpable(-1) then
                luasnip.jump(-1)
              else
                fallback()
              end
            end, { "i", "s" }),
            ["<CR>"] = cmp.mapping.confirm({ select = true }),
            ["<C-Space>"] = cmp.mapping.complete(),
            ["<C-e>"] = cmp.mapping.abort(),
          }),
          sources = cmp.config.sources({
            { name = "copilot" },
            { name = "nvim_lsp" },
            { name = "luasnip" },
          }, {
            { name = "buffer" },
            { name = "path" },
          }),
        })
      end,
    },

    -- ===================== Linting (ALE replacement) =====================
    {
      "mfussenegger/nvim-lint",
      event = { "BufReadPre", "BufNewFile" },
      config = function()
        local lint = require("lint")
        lint.linters_by_ft = {
          ruby       = { "rubocop" },
          python     = { "flake8" },
          javascript = { "eslint" },
          typescript = { "eslint" },
        }
        vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
          callback = function()
            -- Only lint if the linter binary actually exists (avoids ENOENT errors)
            local ft = vim.bo.filetype
            local linters = lint.linters_by_ft[ft] or {}
            local available = {}
            for _, name in ipairs(linters) do
              if vim.fn.executable(name) == 1 then
                table.insert(available, name)
              end
            end
            if #available > 0 then
              lint.try_lint(available)
            end
          end,
        })
      end,
    },

    -- ===================== Surround (vim-surround replacement) =====================
    {
      "kylechui/nvim-surround",
      version = "*",
      event = "VeryLazy",
      config = true,
    },

    -- ===================== Auto Pairs (auto-pairs replacement) =====================
    {
      "windwp/nvim-autopairs",
      event = "InsertEnter",
      config = true,
    },

    -- ===================== Commenting (vim-commentary replacement) =====================
    {
      "numToStr/Comment.nvim",
      event = "VeryLazy",
      config = true,
      -- gcc = toggle line comment, gbc = toggle block comment
    },

    -- ===================== Indent Guides (indentLine replacement) =====================
    {
      "lukas-reineke/indent-blankline.nvim",
      main = "ibl",
      config = function()
        require("ibl").setup({
          indent = { char = "│" },
          scope = { enabled = true },
        })
      end,
    },

    -- ===================== GitHub Copilot (copilot.lua) =====================
    -- Inline suggestions disabled — completions flow through nvim-cmp via
    -- copilot-cmp instead, so they share one menu and the <Tab> mapping.
    {
      "zbirenbaum/copilot.lua",
      cmd = "Copilot",
      event = "InsertEnter",
      config = function()
        require("copilot").setup({
          suggestion = { enabled = false },
          panel = { enabled = false },
        })
      end,
    },
    {
      "zbirenbaum/copilot-cmp",
      dependencies = { "zbirenbaum/copilot.lua" },
      config = function()
        require("copilot_cmp").setup()
      end,
    },

    -- ===================== Claude Code (CLI in a terminal split) =============
    -- Runs the `claude` binary in a split, inheriting CLAUDE_CONFIG_DIR from the
    -- shell — so whichever account `claude-use` selected is the one used here.
    -- Toggle: <leader>cc (or <C-,>). Continue/resume previous conversations too.
    {
      "greggh/claude-code.nvim",
      dependencies = { "nvim-lua/plenary.nvim" },
      cmd = { "ClaudeCode", "ClaudeCodeContinue", "ClaudeCodeResume" },
      keys = {
        { "<leader>cc", "<cmd>ClaudeCode<CR>",         desc = "Toggle Claude Code" },
        { "<leader>cC", "<cmd>ClaudeCodeContinue<CR>", desc = "Claude Code: continue last" },
        { "<leader>cr", "<cmd>ClaudeCodeResume<CR>",   desc = "Claude Code: resume picker" },
      },
      config = function()
        require("claude-code").setup({
          window = {
            split_ratio = 0.35,
            position = "botright",
            enter_insert = true,
          },
        })
      end,
    },

    -- ===================== CodeCompanion (inline AI via Copilot) =============
    -- Quick in-buffer chat + inline edits using the existing Copilot
    -- subscription (no API key). Complements claude-code.nvim: this is for
    -- fast asks without leaving the buffer; that is for full agentic sessions.
    {
      "olimorris/codecompanion.nvim",
      dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-treesitter/nvim-treesitter",
      },
      cmd = { "CodeCompanion", "CodeCompanionChat", "CodeCompanionActions" },
      keys = {
        { "<leader>ai", "<cmd>CodeCompanionChat Toggle<CR>", desc = "AI chat (CodeCompanion)", mode = { "n", "v" } },
        { "<leader>aa", "<cmd>CodeCompanionActions<CR>",     desc = "AI action palette",       mode = { "n", "v" } },
        { "<leader>ae", "<cmd>CodeCompanion<CR>",            desc = "AI inline edit",          mode = { "n", "v" } },
      },
      opts = {
        interactions = {
          chat   = { adapter = "copilot" },
          inline = { adapter = "copilot" },
        },
      },
    },

    -- ===================== Which Key (shows available keybindings) =====================
    {
      "folke/which-key.nvim",
      event = "VeryLazy",
      config = function()
        require("which-key").setup({
          delay = 500,
        })
      end,
    },

    -- ===================== Ruby/Rails support =====================
    { "tpope/vim-rails",   ft = "ruby" },
    { "tpope/vim-bundler", ft = "ruby" },
    { "tpope/vim-rake",    ft = "ruby" },

    -- ===================== Emmet (same as vimrc_v1) =====================
    { "mattn/emmet-vim", ft = { "html", "css", "eruby", "javascript", "typescript" } },

    -- ===================== Terraform =====================
    { "hashivim/vim-terraform", ft = "terraform" },

    -- ===================== Puppet =====================
    { "rodjek/vim-puppet", ft = "puppet" },

    -- ===================== Markdown — In-editor rendering =====================
    -- Renders headers, code blocks, tables, checkboxes, callouts, etc. beautifully
    -- INSIDE the buffer. No browser needed. Toggle with :RenderMarkdown
    {
      "MeanderingProgrammer/render-markdown.nvim",
      ft = { "markdown", "Avante" },
      dependencies = {
        "nvim-treesitter/nvim-treesitter",
        "nvim-tree/nvim-web-devicons",
      },
      opts = {
        completions = { lsp = { enabled = true } },
        heading = {
          icons = { "󰲡 ", "󰲣 ", "󰲥 ", "󰲧 ", "󰲩 ", "󰲫 " },
          backgrounds = {
            "RenderMarkdownH1Bg", "RenderMarkdownH2Bg", "RenderMarkdownH3Bg",
            "RenderMarkdownH4Bg", "RenderMarkdownH5Bg", "RenderMarkdownH6Bg",
          },
          foregrounds = {
            "RenderMarkdownH1", "RenderMarkdownH2", "RenderMarkdownH3",
            "RenderMarkdownH4", "RenderMarkdownH5", "RenderMarkdownH6",
          },
        },
        code = {
          sign = false,
          width = "block",
          right_pad = 1,
          border = "thick",
        },
        bullet = { icons = { "●", "○", "◆", "◇" } },
        checkbox = {
          unchecked = { icon = "󰄱 " },
          checked   = { icon = "󰱒 " },
          custom = {
            todo  = { raw = "[-]", rendered = "󰥔 ", highlight = "RenderMarkdownTodo" },
            wip   = { raw = "[/]", rendered = "󰦖 ", highlight = "RenderMarkdownTodo" },
          },
        },
        pipe_table = { preset = "round", style = "full" },
      },
    },

    -- ===================== Markdown — Browser preview =====================
    -- Live preview in browser with sync scroll. Supports mermaid, math (KaTeX),
    -- charts, etc. Toggle with :MarkdownPreview / :MarkdownPreviewStop
    {
      "iamcco/markdown-preview.nvim",
      cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
      ft = { "markdown" },
      -- Use the install script directly (avoids needing Node/yarn since nvm is lazy-loaded)
      build = "cd app && bash install.sh",
      config = function()
        vim.g.mkdp_auto_close = 1                 -- close preview when switching away
        vim.g.mkdp_open_to_the_world = 0          -- localhost only
        vim.g.mkdp_browser = ""                   -- system default browser
        vim.g.mkdp_echo_preview_url = 1
        vim.g.mkdp_theme = "dark"                 -- match Gruvbox dark
        vim.g.mkdp_preview_options = {
          mkit = {},
          katex = {},                             -- math support
          uml = {},
          maid = {},                              -- mermaid diagrams
          disable_sync_scroll = 0,
          sync_scroll_type = "middle",
          hide_yaml_meta = 1,
          sequence_diagrams = {},
          flowchart_diagrams = {},
          content_editable = false,
          disable_filename = 0,
        }
      end,
    },

  },

  install = { colorscheme = { "gruvbox" } },
  checker = { enabled = true },
})

-- ==========================================================================
-- 4. KEYBINDINGS (ported from your vimrc_v1)
-- ==========================================================================

local map = vim.keymap.set

-- ---- File Explorer (NERDTree-style) ----
map("n", "<C-n>",      ":Neotree toggle<CR>",               { desc = "Toggle file explorer", silent = true })
map("n", "<C-\\>",     ":Neotree reveal<CR>",               { desc = "Find file in tree", silent = true })
map("n", "<leader>e",  ":Neotree toggle<CR>",               { desc = "Toggle file explorer", silent = true })
map("n", "<leader>o",  ":Neotree focus<CR>",                { desc = "Focus file explorer", silent = true })

-- ---- Telescope (fzf.vim replacement) ----
local builtin = require("telescope.builtin")
map("n", "<C-p>",      builtin.find_files,                  { desc = "Find files" })
map("n", "<C-f>",      builtin.live_grep,                   { desc = "Live grep" })
map("n", "<C-Space>",  builtin.buffers,                     { desc = "Buffers" })
map("n", "<leader>ff", builtin.find_files,                  { desc = "Find files" })
map("n", "<leader>fg", builtin.live_grep,                   { desc = "Live grep" })
map("n", "<leader>fb", builtin.buffers,                     { desc = "Buffers" })
map("n", "<leader>fh", builtin.help_tags,                   { desc = "Help tags" })
map("n", "<leader>gc", builtin.git_commits,                 { desc = "Git commits" })
map("n", "<leader>gs", builtin.git_status,                  { desc = "Git status" })

-- ---- Markdown preview ----
map("n", "<leader>mp", ":MarkdownPreviewToggle<CR>",   { desc = "Markdown preview (browser)", silent = true })
map("n", "<leader>mr", ":RenderMarkdown toggle<CR>",   { desc = "Toggle in-editor markdown rendering", silent = true })

-- ---- Tab Navigation (from your vimrc_v1) ----
map("n", "tn", ":tabnew<Space>",   { desc = "New tab" })
map("n", "tk", ":tabnext<CR>",     { desc = "Next tab", silent = true })
map("n", "tj", ":tabprev<CR>",     { desc = "Prev tab", silent = true })
map("n", "th", ":tabfirst<CR>",    { desc = "First tab", silent = true })
map("n", "tl", ":tablast<CR>",     { desc = "Last tab", silent = true })

-- ---- Git (from your vimrc_v1: gs, gb already in fugitive plugin keys above) ----
map("n", "<C-c>", ":Telescope git_commits<CR>", { desc = "Git log", silent = true })

-- ---- Folding (from your vimrc_v1) ----
map("n", "za", "za", { desc = "Toggle fold" })

-- ---- Timestamp (from your vimrc_v1: F5) ----
map("n", "<F5>", function()
  local ts = os.date("================== %c ==================")
  vim.api.nvim_put({ ts }, "c", true, true)
end, { desc = "Insert timestamp" })
map("i", "<F5>", function()
  local ts = os.date("================== %c ==================")
  vim.api.nvim_put({ ts }, "c", true, true)
end, { desc = "Insert timestamp" })

-- ---- Quality of life ----
map("n", "<leader>w",  ":w<CR>",                            { desc = "Save", silent = true })
map("n", "<leader>q",  ":q<CR>",                            { desc = "Quit", silent = true })
map("n", "<leader>x",  ":x<CR>",                            { desc = "Save & quit", silent = true })
map("n", "<Esc>",      ":nohlsearch<CR>",                   { desc = "Clear search", silent = true })

-- Move lines up/down in visual mode
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move line down", silent = true })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move line up", silent = true })

-- Keep cursor centered when scrolling
map("n", "<C-d>", "<C-d>zz", { desc = "Scroll down centered" })
map("n", "<C-u>", "<C-u>zz", { desc = "Scroll up centered" })

-- Better window navigation
map("n", "<C-h>", "<C-w>h", { desc = "Window left" })
map("n", "<C-j>", "<C-w>j", { desc = "Window down" })
map("n", "<C-k>", "<C-w>k", { desc = "Window up" })
map("n", "<C-l>", "<C-w>l", { desc = "Window right" })

-- Diagnostic inline display
vim.diagnostic.config({
  virtual_text = true,
  signs = true,
  underline = true,
  update_in_insert = false,
  float = { border = "rounded" },
})
