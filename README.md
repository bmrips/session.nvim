# session.vim

Automatically load the session contained in the current directory.

## Specification

The behaviour of this plugin is:

1. If there is a session file (e.g. `Session.vim`) in the current directory, no input from standard input and no argument on the command line, the session is loaded on start.
1. If a session was loaded on start, or you activated session autosaving with `:ToggleSessionAutosave`, the session is saved on exit.
1. The command `:ToggleSessionAutosave` toggles whether the current session is saved on exit. The session file will be deleted or created accordingly.

## Installation

With [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
return {
  "f1rstlady/session",
  lazy = false,
  opts = {},
}
```

## Configuration

The plugin can be configured through the setup function:

```lua
-- default options
require('session').setup {
  filename = 'Session.vim',
  notifyWhen = {
    autosaveToggled = true,
    conflictingSession = true,
    sessionLoaded = true,
  },
}
```
