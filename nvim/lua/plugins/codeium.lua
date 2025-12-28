return {
	{
		"Exafunction/codeium.nvim",
		cmd = "Codeium",
		event = "InsertEnter",
		dependencies = {
			"hrsh7th/nvim-cmp",
		},
		build = ":Codeium Auth",
		opts = {
			enable_cmp_source = vim.g.ai_cmp,
			virtual_text = {
				enabled = not vim.g.ai_cmp,
				key_bindings = {
					accept = false,
					next = "<M-]>",
					prev = "<M-[>",
				},
			},
		},
	},
}
