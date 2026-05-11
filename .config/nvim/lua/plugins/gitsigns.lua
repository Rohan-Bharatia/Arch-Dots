return {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
        signs = {
            add = { text = "" },
            change = { text = "" },
            delete = { text = "󰅘" },
            topdelete = { text = "" },
            changedelete = { text = "" },
            untracked = { text = "󰧠" },
        },
        numhl = false,
        linehl = false,
        signcolumn = true,
        attach_to_untracked = true,
        worktrees = {
            {
                toplevel = os.getenv("HOME"),
                gitdir = os.getenv("HOME") .. "/rohan",
            },
        },
    },
    config = function(_, opts)
        require("gitsigns").setup(opts)
        vim.api.nvim_set_hl(0, "GitSignsChange", { link = "DiagnosticError" })
        vim.api.nvim_set_hl(0, "GitSignsDelete", { link = "GitSignsAdd" })
        vim.api.nvim_set_hl(0, "GitSignsTopDelete", { link = "GitSignsAdd" })
        vim.api.nvim_set_hl(0, "GitSignsChangeDelete", { link = "GitSignsAdd" })
        vim.api.nvim_set_hl(0, "GitSignsUntracked", { link = "GitSignsAdd" })
    end,
}
