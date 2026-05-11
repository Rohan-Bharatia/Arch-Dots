local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    local lazyrepo = "https://github.com/folke/lazy.nvim.git"
    local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
    if vim.v.shell_error ~= 0 then
        vim.api.nvim_echo({
            { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
            { out,                            "WarningMsg" },
            { "\nPress any key to exit..." },
        }, true, {})
        vim.fn.getchar()
        os.exit(1)
    end
end
vim.opt.rtp:prepend(lazypath)

require("config.options")
require("config.globals")
require("config.keymaps")
require("config.autocmds")
require("lazy").setup({
    rocks = {
        enabled = false,
        hererocks = false,
    },
    spec = {
        { "LazyVim/LazyVim",                                     import = "lazyvim.plugins" },
        { import = "lazyvim.plugins.extras.editor.snacks_picker" },
        { import = "lazyvim.plugins.extras.lang.typescript" },
        { import = "lazyvim.plugins.extras.lang.json" },
        { import = "lazyvim.plugins.extras.coding.nvim-cmp" },
        { import = "plugins" },
    },
    rtp = {
        disabled_plugins = {
            "netrw",
            "netrwPlugin",
            "tohtml",
            "tutor",
            "zipPlugin",
        },
    },
    checker = {
        enabled = true,
        notify = false,
    },
    change_detection = {
        notify = false,
    },
})
