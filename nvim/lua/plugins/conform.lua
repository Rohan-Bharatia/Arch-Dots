return {
    "stevearc/conform.nvim",
    event = { "BufReadPost", "BufNewFile" },
    cmd = { "ConformInfo" },
    keys = {
        {
            "<leader>cf",
            function()
                require("conform").format({ async = true, lsp_fallback = true })
            end,
            mode = { "n", "v" },
            desc = "Code Format",
        },
    },
    opts = {
        formatters_by_ft = {
            lua = { "stylua" },
            bash = { "shfmt" },
            sh = { "shfmt" },
            zsh = { "shfmt" },
            typescript = { "prettier" },
            css = { "prettier" },
            html = { "prettier" },
            json = { "prettier" },
            yaml = { "prettier" },
            markdown = { "prettier" },
        },
        format_on_save = false,
    },
}
