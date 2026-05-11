return {
    {
        "neovim/nvim-lspconfig",
        opts = {
            servers = {
                pyright = {},
                tsserver = {},
            },
            setup = {
                tsserver = function(_, opts)
                    require("typescript").setup({
                        server = opts,
                    })
                    return true
                end,
            },
        },
        dependencies = { "jose-elias-alvarez/typescript.nvim" },
        init = function()
            vim.api.nvim_create_autocmd("LspAttach", {
                callback = function(args)
                    local client = vim.lsp.get_client_by_id(args.data.client_id)
                    if not client or client.name ~= "tsserver" then
                        return
                    end
                    local buffer = args.buf
                    vim.keymap.set(
                        "n",
                        "<leader>co",
                        "<cmd>TypescriptOrganizeImports<CR>",
                        { buffer = buffer, desc = "Organize Imports" }
                    )
                    vim.keymap.set(
                        "n",
                        "<leader>cR",
                        "<cmd>TypescriptRenameFile<CR>",
                        { buffer = buffer, desc = "Rename File" }
                    )
                end,
            })
        end,
    },
}
