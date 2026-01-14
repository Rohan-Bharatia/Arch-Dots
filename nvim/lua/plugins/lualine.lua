return {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
        local noice = require("noice")
        local augroup = vim.api.nvim_create_augroup("LualineDate", { clear = true })
        local function get_time_str(seconds)
            return os.date("%H:%M:%S", seconds)
        end
        vim.api.nvim_create_autocmd({ "BufReadPost", "BufEnter" }, {
            group = augroup,
            callback = function()
                if vim.b.last_saved then return end
                local file = vim.api.nvim_buf_get_name(0)
                if file ~= "" then
                    local f = vim.uv.fs_stat(file)
                    if f then vim.b.last_saved = get_time_str(f.mtime.sec) end
                end
            end,
        })
        vim.api.nvim_create_autocmd("BufWritePost", {
            group = augroup,
            callback = function()
                vim.b.last_saved = get_time_str(os.time())
            end,
        })
        require("lualine").setup({
            options = {
                theme = "auto",
                globalstatus = true,
                component_separators = "|",
                section_separators = { left = "", right = "" },
            },
            sections = {
                lualine_a = { "mode" },
                lualine_b = { "branch", "diff", "diagnostics" },
                lualine_c = {
                    "filename",
                    {
                        noice.api.status.mode.get,
                        cond = noice.api.status.mode.has,
                        color = { fg = vim.g.base16_gui09 },
                    }
                },
                lualine_x = {
                    {
                        function()
                            return "󰆓 " .. (vim.b.last_saved or "New")
                        end,
                        cond = function() return vim.api.nvim_buf_get_name(0) ~= "" end,
                        color = { fg = vim.g.base16_gui0B, gui = "bold" } -- Green
                    },
                    "fileformat",
                    "filetype"
                },
                lualine_y = {
                    {
                        function() return " " .. os.date("%H:%M") end,
                    },
                    "progress"
                },
                lualine_z = {
                    {
                        function()
                            local line = vim.fn.line(".")
                            local col = vim.fn.col(".")
                            local total = vim.api.nvim_buf_line_count(0)
                            return string.format("%d:%d/%d", line, col, total)
                        end,
                        padding = { left = 1, right = 1 }
                    }
                },
            },
        })
    end,
}
