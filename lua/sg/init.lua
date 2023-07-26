---@tag sg.nvim
---@config { ["name"] = "INTRODUCTION" }

---@brief [[
--- sg.nvim is a plugin for interfacing with Sourcegraph and Cody
---
--- To configure logging in:
---
--- - Log in on your Sourcegraph instance.
--- - Click your user menu in the top right, then select Settings > Access tokens.
--- - Create your access token, and then run `:SourcegraphLogin` in your neovim editor after installation.
--- - Type in the link to your Sourcegraph instance (for example: `https://sourcegraph.com`)
--- - And then paste in your access token.
---
--- An alternative to this is to use the environment variables specified for [src-cli](https://github.com/sourcegraph/src-cli#log-into-your-sourcegraph-instance).
---
--- You can check that you're logged in by then running `:checkhealth sg`
---@brief ]]

local data_file = require("sg.utils").joinpath(vim.fn.stdpath "data", "cody.json")

local M = {}

local get_cody_data = function()
  local handle = io.open(data_file, "r")

  ---@type CodyConfig
  local cody_data = {
    tos_accepted = false,
  }

  if handle ~= nil then
    local contents = handle:read "*a"
    local ok, decoded = pcall(vim.json.decode, contents)
    if ok and decoded then
      cody_data = decoded
    end
  end

  return cody_data
end

local write_cody_data = function(cody_data)
  vim.notify("[cody] Writing data to:" .. data_file)
  vim.fn.writefile({ vim.json.encode(cody_data) }, data_file)
end

local accept_tos = function(opts)
  opts = opts or {}

  local cody_data = get_cody_data()
  if opts.accept_tos and not cody_data.tos_accepted then
    cody_data.tos_accepted = true
    write_cody_data(cody_data)
  end

  if not cody_data.tos_accepted then
    local choice = vim.fn.inputlist {
      "By using Cody, you agree to its license and privacy statement:"
        .. " https://about.sourcegraph.com/terms/cody-notice . Do you wish to proceed? Yes/No: ",
      "1. Yes",
      "2. No",
    }

    cody_data.tos_accepted = choice == 1
    write_cody_data(cody_data)
  end

  return cody_data.tos_accepted
end

M.setup = function(opts)
  opts = opts or {}

  accept_tos(opts)

  local config = require "sg.config"
  for key, value in pairs(opts) do
    if config[key] ~= nil then
      config[key] = value
    end
  end

  require("sg.lsp").setup()
end

M.accept_tos = accept_tos

M._is_authed = function()
  return require("sg.env").endpoint() ~= "" and require("sg.env").token() ~= ""
end

return M
