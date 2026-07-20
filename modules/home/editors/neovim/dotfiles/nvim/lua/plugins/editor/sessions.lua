-- Session management — remember open buffers per project directory
-- Sessions are stored in ~/.local/share/nvim/sessions/

local session_dir = vim.fn.stdpath("data") .. "/sessions/"
vim.fn.mkdir(session_dir, "p")

-- Convert cwd to a safe filename
local function session_file()
  local cwd = vim.fn.getcwd()
  local name = cwd:gsub("/", "%%")
  return session_dir .. name .. ".vim"
end

-- Save session
local function save_session()
  vim.cmd("mksession! " .. vim.fn.fnameescape(session_file()))
end

local function restore_session(options)
  options = options or {}
  local file = session_file()

  if vim.fn.filereadable(file) ~= 1 then
    if options.notify_missing then
      vim.notify("No session found for " .. vim.fn.getcwd(), vim.log.levels.WARN)
    end
    return false
  end

  local ok, err = pcall(vim.cmd, "source " .. vim.fn.fnameescape(file))
  if not ok then
    vim.notify("Failed to restore session " .. file .. ":\n" .. err, vim.log.levels.ERROR)
    return false
  end

  if options.notify_success then
    vim.notify("Session restored for " .. vim.fn.getcwd())
  end
  return true
end

vim.keymap.set("n", "<leader>qs", function()
  save_session()
  vim.notify("Session saved for " .. vim.fn.getcwd())
end, { desc = "Save session" })

-- Restore session
vim.keymap.set("n", "<leader>qr", function()
  local f = session_file()
  if vim.fn.filereadable(f) == 1 then
    -- Close dashboard if open
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.bo[buf].filetype == "snacks_dashboard" then
        vim.api.nvim_buf_delete(buf, { force = true })
      end
    end
    restore_session({ notify_success = true })
  else
    restore_session({ notify_missing = true })
  end
end, { desc = "Restore session" })

-- Auto-save session on exit (always save if there are real buffers)
vim.api.nvim_create_autocmd("VimLeavePre", {
  group = vim.api.nvim_create_augroup("auto_save_session", { clear = true }),
  callback = function()
    local bufs = vim.tbl_filter(function(b)
      return vim.bo[b].buflisted
        and vim.bo[b].buftype == ""
        and vim.bo[b].filetype ~= "snacks_dashboard"
    end, vim.api.nvim_list_bufs())
    if #bufs > 0 then
      -- Close Neo-tree before saving so it doesn't persist its window size
      pcall(vim.cmd, "Neotree close")
      save_session()
    end
  end,
})

-- Auto-restore session on startup
vim.api.nvim_create_autocmd("VimEnter", {
  group = vim.api.nvim_create_augroup("auto_restore_session", { clear = true }),
  callback = function()
    -- Only when opening nvim with no file args or a directory
    if vim.fn.argc() > 0 and vim.fn.isdirectory(vim.fn.argv(0)) == 0 then
      return
    end
    local f = session_file()
    if vim.fn.filereadable(f) ~= 1 then
      return
    end
    -- Defer to run after dashboard and other plugins finish
    vim.schedule(function()
      -- Close dashboard and directory buffers before restoring
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        local ft = vim.bo[buf].filetype
        if ft == "snacks_dashboard" or ft == "netrw" or ft == "neo-tree" then
          vim.api.nvim_buf_delete(buf, { force = true })
        end
      end
      -- Also close any buffer that's just showing a directory
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        local name = vim.api.nvim_buf_get_name(buf)
        if vim.fn.isdirectory(name) == 1 then
          vim.api.nvim_buf_delete(buf, { force = true })
        end
      end
      restore_session()
    end)
  end,
})
