local M = {}

function M.setup(colors)
    for name, value in pairs(colors) do
        vim.g[name] = value
        local hex_code = name:gsub("base", "") -- extracts "00" from "base00"
        vim.g["base16_gui" .. hex_code] = value
    end
    require("mini.base16").setup({
        palette = colors
    })
end

return M
