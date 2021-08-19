# telescope-tmuxinator.nvim
Integration for [tmuxinator](https://github.com/tmuxinator/tmuxinator) with [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim).

## Requirements

- [tmux](https://github.com/tmuxinator/tmuxinator#tmux) 
- [tmuxinator](https://github.com/tmuxinator/tmuxinator) 
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)

## Setup

You can setup the extension by doing

```lua
require('telescope').load_extension('tmuxinator')
```

Somewhere after your `require('telescope').setup()` call.

## Available functions

```lua
require('telescope').extensions.tmuxinator.projects{}
```

As this extension does not support preview, using the dropdown is recommended:

```lua
require('telescope').extensions.tmuxinator.projects(require('telescope.themes').get_dropdown({}))
```

## Mappings

| Mappings       | Action        |
|----------------|---------------|
| `<CR>`         | Select action |
| `<C-x>`        | Stop action   |

## Configuration

See [default configuration](https://github.com/nvim-telescope/telescope.nvim#telescope-defaults) for full details on configuring Telescope.

- `select_action` (default: `switch`)

  One of:
  - `switch`: Switch project
  - `stop`: Switch project and stop the current project
  - `kill`: Switch project and kill the current project
  Defaults to `switch` if unset.

- `stop_action` (default: `stop`)

  One of:
  - `stop`: Stop the current project
  - `kill`: Kill the current project
  Defaults to `stop` if unset.

- `disable_icons` (default: `false`)

  Do not use icons to indicate active sessions


### Example Configuration:

```lua
telescope.setup {
  extensions = {
    tmuxinator = {
      select_action = 'switch', -- | 'stop' | 'kill'
      stop_action = 'stop', -- | 'kill'
      disable_icons = false,
    },
  },
}
```
