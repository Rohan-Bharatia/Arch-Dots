return {
    {
        "nvim-mini/mini.base16",
        lazy = false,
        priority = 1000,
        config = function()
            local matugen_path = os.getenv("HOME") .. "/.config/matugen/generated/neovim-colors.lua"
            local default_colors = {
                base00 = "#1e1e2e",
                base01 = "#181825",
                base02 = "#313244",
                base03 = "#45475a",
                base04 = "#585b70",
                base05 = "#cdd6f4",
                base06 = "#f5e0dc",
                base07 = "#b4befe",
                base08 = "#f38ba8",
                base09 = "#fab387",
                base0A = "#f9e2af",
                base0B = "#a6e3a1",
                base0C = "#94e2d5",
                base0D = "#89b4fa",
                base0E = "#cba6f7",
                base0F = "#f2cdcd",
            }
            local function load_theme()
                if vim.uv.fs_stat(matugen_path) then
                    local ok, err = pcall(dofile, matugen_path)
                    if not ok then
                        vim.notify("Matugen load error: " .. err, vim.log.levels.ERROR)
                        require("base16-colorscheme").setup(default_colors)
                    end
                end
            end
            load_theme()
            local function apply_tweaks()
                vim.api.nvim_set_hl(0, "Comment", { italic = true })
                vim.api.nvim_set_hl(0, "NvimTreeNormal", { bg = "NONE", ctermbg = "NONE" })
                vim.opt.guicursor = "n-v-c:hor20-Cursor,i-ci-ve:ver25-Cursor,r-cr-o:hor20-Cursor"
            end
            apply_tweaks()
            local signal = vim.uv.new_signal()
            signal:start("sigusr1", function()
                vim.schedule(function()
                    load_theme()
                    apply_tweaks()
                    if package.loaded["lualine"] then
                        require("lualine").refresh()
                    end
                    vim.notify("Theme reloaded via SIGUSR1")
                end)
            end)
        end,
    },
}
