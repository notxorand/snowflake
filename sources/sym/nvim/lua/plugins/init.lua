return {
    {
        "stevearc/conform.nvim",
        -- event = 'BufWritePre', -- uncomment for format on save
        opts = require "configs.conform",
    },

    -- These are some examples, uncomment them if you want to see them work!
    {
        "neovim/nvim-lspconfig",
        config = function()
            require "configs.lspconfig"
        end,
    },

    {
    	"nvim-treesitter/nvim-treesitter",
    	opts = {
    		ensure_installed = {
    			"vim", "lua", "vimdoc",
          "html", "css", "zig",
          "rust", "toml", "json",
    		},
    	},
    },
    {
        "williamboman/mason.nvim"
    },

    {
        'mrcjkb/rustaceanvim',
        version = '^4',
        lazy = false,
        ["rust-analyzer"] = {
            cargo = {
                allFeatures = true
            }
        }
    },

    {
        "nvzone/typr",
        dependencies = "nvzone/volt",
        opts = {},
        cmd = { "Typr", "TyprStats" },
    },

    { "nvzone/volt", lazy = true },
    { "nvzone/menu", lazy = true },
    {
        "nvzone/minty",
        cmd = { "Shades", "Huefy" },
    },
    { "nvzone/timerly",       cmd = "TimerlyToggle" },

    {
        "supermaven-inc/supermaven-nvim",
        lazy = false,
        config = function()
            require("supermaven-nvim").setup({})
        end,
    },

    {
        "rmagatti/auto-session",
        event = "VimEnter",
        config = function()
            vim.o.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"
            require("auto-session").setup({
                auto_create = true,
                auto_restore = true,
                auto_restore_last_session = true,
                auto_save = true,
                auto_session_session_name = "Session.vim",
                enabled = true,
                log_level = "error",
                root_dir = "~/.config/nvim/session",
                session_lens = {
                    load_on_setup = true,
                    previewer = false,
                    theme_conf = {
                        border = true
                    }
                }
            })
        end
    },

    { "nvim-lua/plenary.nvim" },

    {
        "pwntester/octo.nvim",
        lazy = false,
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-telescope/telescope.nvim",
            "nvim-tree/nvim-web-devicons",
        },
        config = function()
            require("octo").setup()
        end,
    },

    -- {
      -- "sphamba/smear-cursor.nvim",
      -- lazy = false,
      -- opts = {}
    -- },

    {
      "wakatime/vim-wakatime",
      lazy = false,
    }
}
