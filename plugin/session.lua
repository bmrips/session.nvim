local argumentsWereGiven = vim.fn.argc(-1) ~= 0
local readFromStdin = false

local augroup = vim.api.nvim_create_augroup('session', { clear = true })

vim.api.nvim_create_autocmd('VimEnter', {
  group = augroup,
  nested = true,
  desc = 'If a session exists, load it',
  callback = function()
    if readFromStdin or argumentsWereGiven then
      return
    end
    local session = require 'session'
    session.autosaveEnabled = session.load()
  end,
})

vim.api.nvim_create_autocmd('VimLeave', {
  group = augroup,
  nested = true,
  desc = 'Save a session if autosave is enabled',
  callback = function()
    local session = require 'session'
    ---@diagnostic disable-next-line: unnecessary-if
    if not session.autosaveEnabled then
      return
    end
    session.save()
  end,
})

vim.api.nvim_create_autocmd('StdinReadPost', {
  group = augroup,
  desc = 'Remember that stdin was read from',
  callback = function()
    readFromStdin = true
  end,
})

vim.api.nvim_create_user_command('ToggleSessionAutosave', function()
  require('session').toggleAutosave()
end, {
  force = true,
  bar = true,
  desc = 'Toggle session autosaving',
})
