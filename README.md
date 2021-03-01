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

## Options

| Keys            | Description                                  | Options |
|-----------------|----------------------------------------------|---------|
| `disable_icons` | Do not use icons to indicate active sessions | boolean |

## Mappings

| Mappings       | Action                            |
|----------------|-----------------------------------|
| `<CR>`         | Start/ Switch to selected project |
| `<C-x>`        | Stop tmuxinator project           |
