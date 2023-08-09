# Artemis 🏹

***Hunt the lines of your jump list***

## Documentation

see `:help artemis`

Visual help to go through your jump list faster. Displays two floating windows. One shows the lines content of the jump list entry. Here you can choose which line to jump to, and the other shows a preview of the surrounding lines of the line you would jump to.

### Tested on NVIM v0.9.1 

## Sample setup

```lua
vim.keymap.set('n', '<leader>jl', function ()
 require("artemis").visjump()
end, {desc = 'navigate [J]ump [L]ist'})
```

## Keymaps in poseidon
**Keymaps are only used in poseidon and are remapped to the original keymaps when poseidon is closed**
| Key            | Action                                      |
| -------------- | ------------------------------------------- |
| `<CR>`         | Jump to position of current line in Artemis |
| `<ESC>`        | Close Artemis without action                |
