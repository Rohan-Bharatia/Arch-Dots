return {
    "mbbill/undotree",
    cmd = "UndotreeToggle",
    keys = {
        { "<leader>u", vim.cmd.UndotreeToggle, desc = "Toggle Undotree" },
    },
    config = function()
        vim.g.undotree_SetFocusWhenToggle = 1
    end,
}
