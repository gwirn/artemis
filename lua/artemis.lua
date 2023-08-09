-- split string with separator
local function split_string (inputstr, sep)
  if sep == nil then
          sep = "%s"
  end
  local t={}
  for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
          table.insert(t, str)
  end
  return t
end


local M = {}

M.visjump = function ()
  -- get items of jumplist and store their line content and their data in list
  local jumplist = vim.fn.getjumplist()[1]
  -- reverse jumplist
  for i = 1, math.floor(#jumplist/2) do
     local j = #jumplist - i + 1
      jumplist[i], jumplist[j] = jumplist[j], jumplist[i]
  end
  local jump_list = {}
  local jump_data = {}
  for _, i in pairs(jumplist) do
    local code_line = string.gsub(vim.fn.getbufoneline(i["bufnr"], i["lnum"]), '^%s*(.-)%s*$', '%1')
    if code_line:len() > 0 then
      table.insert(jump_list, code_line)
      table.insert(jump_data, i)
    end
  end

  -- all keymaps before they get remapped in the buffer of the floating window
  local all_keymaps = vim.api.nvim_get_keymap("n")
  local keymaps = {"<CR>", "<ESC>"}
  local remap_keymaps = function ()
      for _, key in pairs(keymaps) do
        local mapping = all_keymaps[key]
        if mapping then
          if mapping.lhs then
            if mapping.rhs then
              vim.api.nvim_set_keymap("n", mapping.lhs, mapping.rhs, {})
            end
          else
            vim.api.nvim_del_keymap("n", key)
          end
        else
          vim.api.nvim_del_keymap("n", key)
        end
      end
  end

  -- create floating window for lines
  local buf, win
  buf = vim.api.nvim_create_buf(false, true)
  -- write jumplist code lines to buffer
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, jump_list)
  vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")

  -- generate new floating window
  local width = vim.api.nvim_get_option("columns")
  local height = vim.api.nvim_get_option("lines")

  local win_height = math.floor(height * 0.2)
  local win_width = math.ceil(width * 0.4)
  local row = math.ceil((height - win_height) / 2)
  local col = math.floor((width - win_width) / 4)

  local opts = {
    style = "minimal",
    relative = "editor",
    width = win_width,
    height = win_height,
    row = row,
    col = col,
    border = "rounded",
    title = "Artemis",
    title_pos = "center"
  }
  win = vim.api.nvim_open_win(buf, true, opts)
  vim.api.nvim_win_set_option(win, "cursorline", true)

  -- create preview window where lines around jumps are shown
  win_height = math.ceil(height*0.7)
  local buf2, win2
  local row2 = math.ceil(height*0.1)
  local col2 = math.ceil((width - win_width) / 4 + win_width) + 1
  local opts2 = {
    style = "minimal",
    relative = "editor",
    width = win_width,
    height = win_height,
    row = row2,
    col = col2,
    border = "rounded",
    title = "Preview",
    title_pos = "center"
  }
  buf2 = vim.api.nvim_create_buf(false, true)
  win2 = vim.api.nvim_open_win(buf2, false, opts2)
  vim.api.nvim_win_set_option(win2, "cursorline", true)
  vim.bo[buf].modifiable = false

  -- create auto command that gets executed every time the cursor position changes
  local cur_data
  local ns_artemis = vim.api.nvim_create_namespace("Artemis")

  -- close all windows when one is closed and reset the key maps
  vim.api.nvim_create_autocmd({"BufWinLeave"}, { buffer=buf, callback= function ()
    if vim.api.nvim_win_is_valid(win2) then
      vim.api.nvim_win_close(win2, true)
      remap_keymaps()
    end
  end})
  vim.api.nvim_create_autocmd({"BufWinLeave"}, { buffer=buf2, callback= function ()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
      remap_keymaps()
    end
  end})

  vim.api.nvim_create_autocmd({"CursorHold", "CursorHoldI"}, { buffer=buf, callback = function ()
    -- at which line we are in the floating window
    cur_data = jump_data[vim.fn.line(".")]
    local buf_name = vim.api.nvim_buf_get_name(cur_data["bufnr"])
    local filetype_buf = split_string(buf_name, ".")
    filetype_buf = filetype_buf[#filetype_buf]
    local start = cur_data["lnum"] - 10
    local start_adapt = start
    local neg_start_off = 0
    if start_adapt < 1 then
      start_adapt = 1
      neg_start_off = start - 1
    end
    -- write file path in the first line
    vim.api.nvim_buf_set_lines(buf2, 0, 2, false, {buf_name, string.rep("=", win_width)})
    vim.api.nvim_buf_set_lines(buf2, 2, -1, false, vim.fn.getbufline(cur_data["bufnr"], start_adapt, start_adapt + win_height))
    -- write content into the buffer
    vim.api.nvim_buf_set_option(buf2, "filetype", filetype_buf)
    vim.api.nvim_buf_add_highlight(buf2, ns_artemis, "CurSearch", 12 + neg_start_off , 0, -1)
  end})
  local do_command = function (lhs)
    vim.keymap.set("n", lhs, function ()
      local pos = vim.fn.line(".")
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
      end
      if vim.api.nvim_win_is_valid(win2) then
        vim.api.nvim_win_close(win2, true)
      end
      -- execute jump
      if lhs == "<CR>" then
        vim.api.nvim_command(string.format(":b %d | %d", jump_data[pos]["bufnr"], jump_data[pos]["lnum"]))
      end
      win = nil
      win2 = nil
      buf = nil
      buf2 = nil
  end)
  end
  do_command("<CR>")
  do_command("<ESC>")
end

return M
