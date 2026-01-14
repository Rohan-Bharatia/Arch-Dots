return {
    "nvim-tree/nvim-tree.lua",
    cmd = { "NvimTreeToggle", "NvimTreeFocus" },
    config = function()
        require("nvim-tree").setup({
            filters = {
                dotfiles = true,
            },
            view = {
                adaptive_size = true,
            },
        })
    end,
}
