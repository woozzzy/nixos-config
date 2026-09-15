return {
    {
        "stevearc/conform.nvim",
        opts = {
            formatters = { nixfmt = { args = { "--indent", "2" } } },
            formatters_by_ft = { nix = { "nixfmt" } },
        },
    },
    { "mason-org/mason.nvim", opts = { ensure_installed = {} } }, -- don't let Mason pull nixfmt/nixd
}
