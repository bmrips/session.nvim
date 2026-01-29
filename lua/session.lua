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

M.autosaveEnabled = false

local function notify(message, log_level)
  log_level = log_level or vim.log.levels.INFO
  vim.notify(message, log_level, { title = 'Session' })
end

local function callOrNotify(...)
  local ok, msg = pcall(...)
  if ok then
    return
  end
  ---@diagnostic disable-next-line: param-type-mismatch, need-check-nil
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
  M.autosaveEnabled = false
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
    M.autosaveEnabled = true
    M.save()
    if config.notifyWhen.autosaveToggled then
      notify 'saved & autosave enabled'
    end
  end
end

-- Toggles autosave.
function M.toggleAutosave()
  if M.autosaveEnabled then
    M.disableAutosave()
  else
    M.enableAutosave()
  end
end

---@param opts session.Config
function M.setup(opts)
  config = vim.tbl_deep_extend('force', config, opts or {})
end

return M
