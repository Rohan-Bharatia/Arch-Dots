local last_cursor_group = vim.api.nvim_create_augroup("LastCursorGroup", {})
vim.api.nvim_create_autocmd("BufReadPost", {
    group = last_cursor_group,
    callback = function()
        local mark = vim.api.nvim_buf_get_mark(0, '"')
        local lcount = vim.api.nvim_buf_line_count(0)
        local ft = vim.bo.filetype
        local contains = vim.list_contains or vim.tbl_contains
        if not contains({ "gitcommit", "gitrebase" }, ft)
            and mark[1] > 0
            and mark[1] <= lcount
        then
            pcall(vim.api.nvim_win_set_cursor, 0, mark)
        end
    end,
})
local highlight_yank_group = vim.api.nvim_create_augroup("HighlightYank", {})
vim.api.nvim_create_autocmd("TextYankPost", {
    group = highlight_yank_group,
    pattern = "*",
    callback = function()
        vim.hl.on_yank({ higroup = "IncSearch", timeout = 200 })
    end,
})
