-- Make smart-enter open the full selection set (not just the hovered file)
-- when used with --chooser-file (e.g. browser multi-select upload).
require("smart-enter"):setup({ open_multi = true })
