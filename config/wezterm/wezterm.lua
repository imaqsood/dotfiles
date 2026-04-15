-- ==========================================================================
-- WezTerm Configuration — Feature-Rich & Performant
-- ==========================================================================
-- Optimized for: tmux user on macOS (Apple Silicon)
-- Stack: tmux (multiplexer), Neovim (editor), Gruvbox Dark, Nerd Fonts
-- WezTerm is the "dumb terminal" — tmux handles tabs/panes/sessions
-- ==========================================================================

local wezterm = require("wezterm")
local act = wezterm.action
local mux = wezterm.mux
local config = wezterm.config_builder()

-- ==========================================================================
-- 1. GPU / RENDERING / PERFORMANCE
-- ==========================================================================
-- front_end intentionally omitted — let WezTerm pick the best renderer
config.max_fps = 120
config.animation_fps = 60
config.cursor_blink_rate = 500
config.scrollback_lines = 10000

-- ==========================================================================
-- 2. TERMINAL / SHELL
-- ==========================================================================
config.term = "xterm-256color"
config.default_cursor_style = "BlinkingBar"
config.automatically_reload_config = true
config.window_close_confirmation = "NeverPrompt"
config.adjust_window_size_when_changing_font_size = false
config.audible_bell = "Disabled"

-- Use Homebrew zsh (system /bin/zsh may be outdated)
config.default_prog = { "/opt/homebrew/bin/zsh", "-l" }

-- Homebrew PATH for WezTerm-spawned shells
config.set_environment_variables = {
  PATH = "/opt/homebrew/bin:" .. os.getenv("PATH"),
}

-- ==========================================================================
-- 3. FONT CONFIGURATION WITH FALLBACKS
-- ==========================================================================
config.font = wezterm.font_with_fallback({
  {
    family = "JetBrainsMono Nerd Font",
    weight = "Medium",
    harfbuzz_features = {
      "calt=1", -- contextual alternates (ligatures)
      "clig=1", -- contextual ligatures
      "liga=1", -- standard ligatures
    },
  },
  { family = "Monaco Nerd Font", weight = "Regular" },
  { family = "Symbols Nerd Font Mono", weight = "Regular" },
  "Apple Color Emoji",
})
config.font_size = 15.0
config.line_height = 1.15
config.cell_width = 1.0
config.warn_about_missing_glyphs = false

-- ==========================================================================
-- 4. COLOR SCHEME — GRUVBOX DARK
-- ==========================================================================
config.color_scheme = "Gruvbox Dark (Gogh)"

local gruvbox = {
  bg      = "#282828",
  bg0_h   = "#1d2021",
  bg1     = "#3c3836",
  bg2     = "#504945",
  bg3     = "#665c54",
  bg4     = "#7c6f64",
  fg      = "#ebdbb2",
  fg0     = "#fbf1c7",
  fg4     = "#a89984",
  red     = "#fb4934",
  green   = "#b8bb26",
  yellow  = "#fabd2f",
  blue    = "#83a598",
  purple  = "#d3869b",
  aqua    = "#8ec07c",
  orange  = "#fe8019",
}

-- ==========================================================================
-- 5. WINDOW APPEARANCE
-- ==========================================================================
config.window_decorations = "RESIZE"
config.window_padding = {
  left   = 12,
  right  = 12,
  top    = 8,
  bottom = 4,
}

-- macOS window effects
config.macos_window_background_blur = 20
config.window_background_opacity = 0.95

-- ==========================================================================
-- 6. TAB BAR — DISABLED (tmux handles multiplexing)
-- ==========================================================================
config.enable_tab_bar = false
config.enable_scroll_bar = false

-- ==========================================================================
-- 7. KEY BINDINGS (no leader — tmux owns Ctrl-A)
-- ==========================================================================
-- WezTerm only handles terminal-level shortcuts.
-- All pane/tab/session management goes through tmux.
config.keys = {
  -- Toggle fullscreen
  { key = "Enter", mods = "ALT", action = act.ToggleFullScreen },

  -- Clear scrollback (fixes garbled p10k lines after resize)
  { key = "k", mods = "CMD", action = act.ClearScrollback("ScrollbackAndViewport") },

  -- Open this config in Neovim
  {
    key = ",",
    mods = "SUPER",
    action = act.SpawnCommandInNewTab({
      cwd = wezterm.home_dir,
      args = { "nvim", wezterm.config_file },
    }),
  },

  -- macOS: Option+Arrow for word movement in shell
  { key = "LeftArrow",  mods = "OPT", action = act.SendString("\x1bb") },
  { key = "RightArrow", mods = "OPT", action = act.SendString("\x1bf") },

  -- Font size
  { key = "+", mods = "SUPER|SHIFT", action = act.IncreaseFontSize },
  { key = "-", mods = "SUPER",       action = act.DecreaseFontSize },
  { key = "0", mods = "SUPER",       action = act.ResetFontSize },

  -- Quick Select (Ctrl+Shift+Space — pick text patterns from screen)
  { key = "phys:Space", mods = "CTRL|SHIFT", action = act.QuickSelect },

  -- Copy mode (Ctrl+Shift+X — vim-like selection)
  { key = "X", mods = "CTRL|SHIFT", action = act.ActivateCopyMode },

  -- Search (Ctrl+Shift+F)
  { key = "F", mods = "CTRL|SHIFT", action = act.Search("CurrentSelectionOrEmptyString") },
}

-- ==========================================================================
-- 8. MOUSE BINDINGS
-- ==========================================================================
config.mouse_bindings = {
  -- Right-click: copy if selection exists, otherwise paste
  {
    event = { Down = { streak = 1, button = "Right" } },
    mods = "NONE",
    action = wezterm.action_callback(function(window, pane)
      local has_selection = window:get_selection_text_for_pane(pane) ~= ""
      if has_selection then
        window:perform_action(act.CopyTo("ClipboardAndPrimarySelection"), pane)
        window:perform_action(act.ClearSelection, pane)
      else
        window:perform_action(act.PasteFrom("Clipboard"), pane)
      end
    end),
  },

  -- Left click: select text
  {
    event = { Up = { streak = 1, button = "Left" } },
    mods = "NONE",
    action = act.CompleteSelection("ClipboardAndPrimarySelection"),
  },

  -- Ctrl+Click: open hyperlink
  {
    event = { Up = { streak = 1, button = "Left" } },
    mods = "CTRL",
    action = act.OpenLinkAtMouseCursor,
  },
  {
    event = { Down = { streak = 1, button = "Left" } },
    mods = "CTRL",
    action = act.Nop,
  },

  -- Ctrl+Scroll = zoom font
  {
    event = { Down = { streak = 1, button = { WheelUp = 1 } } },
    mods = "CTRL",
    action = act.IncreaseFontSize,
  },
  {
    event = { Down = { streak = 1, button = { WheelDown = 1 } } },
    mods = "CTRL",
    action = act.DecreaseFontSize,
  },
}

-- Bypass mouse reporting for Alt-click (useful inside tmux)
config.bypass_mouse_reporting_modifiers = "ALT"

-- ==========================================================================
-- 9. HYPERLINK DETECTION
-- ==========================================================================
config.hyperlink_rules = wezterm.default_hyperlink_rules()

-- GitHub "user/repo" shorthand
table.insert(config.hyperlink_rules, {
  regex = [[["]?([\w\d]{1}[-\w\d]+)(/)([-\w\d\.]+)["]?]],
  format = "https://www.github.com/$1/$3",
})

-- ==========================================================================
-- 10. QUICK SELECT PATTERNS
-- ==========================================================================
config.quick_select_patterns = {
  "[0-9a-f]{7,40}",                                    -- Git SHA
  "\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}",       -- IPv4
  "[a-z]+(?:-[a-z0-9]+)+-[a-z0-9]+",                  -- k8s pod names
  "(?:/[\\w.-]+)+",                                     -- Unix file paths
  "[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}", -- UUID
  "[\\w.+-]+@[\\w.-]+\\.[a-zA-Z]{2,}",                -- Email
  "\\d+\\.\\d+\\.\\d+(?:-[\\w.]+)?",                  -- Semver
}

-- ==========================================================================
-- 11. STARTUP — MAXIMIZE
-- ==========================================================================
wezterm.on("gui-startup", function(cmd)
  local _tab, _pane, window = mux.spawn_window(cmd or {})
  window:gui_window():maximize()
end)

-- ==========================================================================
return config
