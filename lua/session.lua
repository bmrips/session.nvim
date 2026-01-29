local M = {}

---@class session.notification.Config
---@field autosaveToggled boolean When the autosave setting changes
---@field conflictingSession boolean When autosave is not enabled due to a conflicting session
---@field sessionLoaded boolean When a session is loaded at startup

---@class session.Config
---@field filename string The session filename
---@field notifyWhen session.notification.Config
local config = {
  filename = 'Session.vim',
  notifyWhen = {
    autosaveToggled = true,
    conflictingSession = true,
    sessionLoaded = true,
  },
}

local argumentsWereGiven = vim.fn.argc(-1) ~= 0
local autosaveEnabled = false
local readFromStdin = false

local function notify(message, log_level)
  log_level = log_level or vim.log.levels.INFO
  vim.notify(message, log_level, { title = 'Session' })
end

local function callOrNotify(...)
  local ok, msg = pcall(...)
  if ok then
    return
  end
  msg = msg:match 'E%d*:.+' or msg -- capture the Nvim error only
  notify(msg, vim.log.levels.ERROR)
end

-- Checks whether a session file exists in the current directory.
---@return boolean doesExist Whether a session exists
function M.exists()
  local f = io.open(config.filename, 'r')
  if f ~= nil then
    io.close(f)
    return true
  else
    return false
  end
end

-- Sources the session file it it exists.
---@return boolean didLoad Whether a session was loaded
function M.load()
  if not M.exists() then
    return false
  end

  callOrNotify(vim.cmd.source, config.filename)

  if config.notifyWhen.sessionLoaded then
    notify 'loaded'
  end

  return true
end

-- Deletes the session file.
function M.delete()
  assert(os.remove(config.filename))
end

-- Saves the current session into the session file.
function M.save()
  callOrNotify(vim.cmd.mksession, {
    bang = true,
    args = { config.filename },
  })
end

-- Disables autosave.
function M.disableAutosave()
  autosaveEnabled = false
  M.delete()
  if config.notifyWhen.autosaveToggled then
    notify 'deleted & autosave disabled'
  end
end

-- Enables autosave.
---@param opts? { force? : boolean } whether to overwrite a conflicting session
function M.enableAutosave(opts)
  opts = vim.tbl_extend('keep', opts or {}, { force = false })

  if not opts.force and M.exists() then
    vim.ui.select({ 'yes', 'no' }, {
      prompt = 'Overwrite the conflicting session?',
    }, function(choice)
      if choice == 'yes' then
        M.enableAutosave { force = true }
      elseif config.notifyWhen.conflictingSession then
        notify 'autosave was not enabled due to a conflicting session'
      end
    end)
  else
    autosaveEnabled = true
    M.save()
    if config.notifyWhen.autosaveToggled then
      notify 'saved & autosave enabled'
    end
  end
end

-- Toggles autosave.
function M.toggleAutosave()
  if autosaveEnabled then
    M.disableAutosave()
  else
    M.enableAutosave()
  end
end

---@param opts session.Config
function M.setup(opts)
  config = vim.tbl_deep_extend('force', config, opts or {})

  local augroup = vim.api.nvim_create_augroup('session', { clear = true })

  vim.api.nvim_create_autocmd('VimEnter', {
    group = augroup,
    nested = true,
    desc = 'If a session exists, load it',
    callback = function()
      if readFromStdin or argumentsWereGiven then
        return
      end
      _, autosaveEnabled = pcall(M.load)
    end,
  })

  vim.api.nvim_create_autocmd('VimLeave', {
    group = augroup,
    nested = true,
    desc = 'Save a session if autosave is enabled',
    callback = function()
      if not autosaveEnabled then
        return
      end
      M.save()
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
    M.toggleAutosave()
  end, {
    force = true,
    bar = true,
    desc = 'Toggle session autosaving',
  })
end

return M
