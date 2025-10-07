local M = {}

local function date()
  return os.date("%d %b %Y - %H:%M:%S")
end

-- Pad a string to `width` columns. If ensure_tilde==true,
-- the final character will be '~' and total width will be `width`.
local function pad_to_width(s, width, ensure_tilde)
  -- remove trailing spaces / tildes
  s = s:gsub("%s*$", "")
  s = s:gsub("~%s*$", "")

  local cur = vim.fn.strdisplaywidth(s)
  local inner = ensure_tilde and (width - 1) or width

  if cur < inner then
    s = s .. string.rep(" ", inner - cur)
  elseif cur > inner then
    s = s:sub(1, inner)
  end

  return s .. (ensure_tilde and "~" or "")
end

-- Find header start/end within the first N lines (returns 1-based indices)
local function find_header_range(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local total = vim.api.nvim_buf_line_count(bufnr)
  local limit = math.min(200, total) -- header should be near top
  local head = vim.api.nvim_buf_get_lines(bufnr, 0, limit, false)

  local start_i, end_i
  for i, l in ipairs(head) do
    if l:match("^%s*/%*~") then
      start_i = i
      break
    end
  end
  if not start_i then
    return nil
  end

  for j = start_i, #head do
    if head[j]:match("~+%*/%s*$") then
      end_i = j
      break
    end
  end
  if not end_i then
    return nil
  end

  return start_i, end_i
end

--------------------------------------------------------------------------------
-- Update existing header (on save) - only inside the header block
--------------------------------------------------------------------------------
function M.update_header()
  local bufnr = vim.api.nvim_get_current_buf()
  local start_i, end_i = find_header_range(bufnr)
  if not start_i then
    return
  end -- no header found -> do nothing

  local start0 = start_i - 1 -- 0-based start for API
  local end_excl = end_i -- exclusive end for API
  local header_lines = vim.api.nvim_buf_get_lines(bufnr, start0, end_excl, false)
  local filename = vim.fn.expand("%:t")

  local changed = false
  local out = {}

  for _, line in ipairs(header_lines) do
    if line:match("%*%s*File Name") then
      -- keep left prefix (spaces and optional '~') up to the '*'
      local star_pos = line:find("%*")
      local leading = star_pos and line:sub(1, star_pos - 1) or ""
      local new_line = leading .. "* File Name     : " .. filename
      local ensure_tilde = (line:find("~") ~= nil)
      new_line = pad_to_width(new_line, 80, ensure_tilde)
      table.insert(out, new_line)
      changed = true
    elseif line:match("%*%s*Creation Date") then
      local star_pos = line:find("%*")
      local leading = star_pos and line:sub(1, star_pos - 1) or ""
      local current = line:match(":%s*(.*)")
      if not current or current:match("^%s*$") then
        -- fill creation date only if empty
        local new_line = leading .. "* Creation Date : " .. date()
        local ensure_tilde = (line:find("~") ~= nil)
        new_line = pad_to_width(new_line, 80, ensure_tilde)
        table.insert(out, new_line)
        changed = true
      else
        table.insert(out, line)
      end
    elseif line:match("%*%s*Last Modified") then
      local star_pos = line:find("%*")
      local leading = star_pos and line:sub(1, star_pos - 1) or ""
      local new_line = leading .. "* Last Modified : " .. date()
      local ensure_tilde = (line:find("~") ~= nil)
      new_line = pad_to_width(new_line, 80, ensure_tilde)
      table.insert(out, new_line)
      changed = true
    else
      -- leave all other header lines untouched (keeps ASCII art exact)
      table.insert(out, line)
    end
  end

  if changed then
    vim.api.nvim_buf_set_lines(bufnr, start0, end_excl, false, out)
  end
end

--------------------------------------------------------------------------------
-- Insert header manually (exact layout, dynamic fields padded)
--------------------------------------------------------------------------------
function M.insert_header()
  local filename = vim.fn.expand("%:t")
  local today = date()

  -- lines copied from your exact template; dynamic lines are built/padded
  local header_template = {
    "/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
    "~                               ████████╗███████╗                              ~",
    "           ........     ██████╗ ╚══██╔══╝╚═════██╗            ........          ",
    "~        ..........    ██╔═══██╗   ██║    ██████╔╝            ..........       ~",
    "         ..........    ██║   ██║   ██║   ██╔════╝             ..........        ",
    "~          ........    ╚██████╔╝   ██║   ████████╗███████╗    ........         ~",
    "                        ╚═════╝    ╚═╝   ╚═══════╝╚══════╝                      ",
    -- dynamic lines (pad them to 80 columns)
    pad_to_width("~  * File Name     : " .. filename, 80, true),
    pad_to_width("   * Creation Date : " .. today, 80, false),
    pad_to_width("~  * Last Modified : " .. today, 80, true),
    pad_to_width("   * Created By    : oT2_", 80, false),
    pad_to_width("~  * Email         : contact@ot2.dev", 80, true),
    "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/",
    "",
  }

  vim.api.nvim_buf_set_lines(0, 0, 0, false, header_template)
end

return M
