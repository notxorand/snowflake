local lspconfig = require("lspconfig")

lspconfig.zls.setup {

  cmd = { "zls" },

  filetypes = { "zig", "zir" },

  root_dir = lspconfig.util.root_pattern("build.zig", ".git") or vim.loop.cwd,

  single_file_support = true,

}


vim.api.nvim_create_autocmd("LspAttach", {

  callback = function(args)

    local opts = { buffer = args.buf }

    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts) -- Go to definition

    vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)       -- Hover info

  end,

})
