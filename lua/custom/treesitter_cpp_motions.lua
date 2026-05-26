local M = {}

function M.setup()
  local function collect_nodes(bufnr, lang, group)
    local qstr
    if lang == 'c' then
      if group == 'func' then
        qstr = [[ (function_definition) @obj ]]
      else
        qstr = [[ (struct_specifier) @obj (union_specifier) @obj ]]
      end
    else
      if group == 'func' then
        qstr = [[ (function_definition) @obj ]]
      else
        qstr = [[ (class_specifier) @obj (struct_specifier) @obj ]]
      end
    end
    local okp, parser = pcall(vim.treesitter.get_parser, bufnr, lang)
    if not okp or not parser then return {} end
    local trees = parser:parse()
    local tree = trees and trees[1]
    if not tree then return {} end
    local root = tree:root()
    local query = vim.treesitter.query.parse(lang, qstr)
    local nodes = {}
    for id, node in query:iter_captures(root, bufnr, 0, -1) do
      if query.captures[id] == 'obj' then
        local sr, sc, er, ec = node:range()
        nodes[#nodes + 1] = { sr = sr, sc = sc, er = er, ec = ec }
      end
    end
    table.sort(nodes, function(a, b)
      if a.sr == b.sr then return a.sc < b.sc end
      return a.sr < b.sr
    end)
    return nodes
  end

  local function to_line_first_word(r)
    local line = vim.api.nvim_buf_get_lines(0, r, r + 1, false)[1] or ''
    local col = (line:find '%S' or 1) - 1
    vim.api.nvim_win_set_cursor(0, { r + 1, col })
  end

  local function to_line_end_of_closing_brace(r)
    local line = vim.api.nvim_buf_get_lines(0, r, r + 1, false)[1] or ''
    local col = (line:find('}', 1, true) or (#line + 1)) - 1
    vim.api.nvim_win_set_cursor(0, { r + 1, col })
  end

  local function jump(group, to_end, forward)
    local ft = vim.bo.filetype
    local lang = (ft == 'c') and 'c' or 'cpp'
    local nodes = collect_nodes(0, lang, group)
    if #nodes == 0 then return end
    local cur = vim.api.nvim_win_get_cursor(0)
    local cr, cc = cur[1] - 1, cur[2]
    local target
    if forward then
      for _, n in ipairs(nodes) do
        local r, c = (to_end and n.er or n.sr), (to_end and n.ec or n.sc)
        if r > cr or (r == cr and c > cc) then
          target = n
          break
        end
      end
    else
      for i = #nodes, 1, -1 do
        local n = nodes[i]
        local r, c = (to_end and n.er or n.sr), (to_end and n.ec or n.sc)
        if r < cr or (r == cr and c < cc) then
          target = n
          break
        end
      end
    end
    if not target then return end
    if to_end then
      to_line_end_of_closing_brace(target.er)
    else
      to_line_first_word(target.sr)
    end
  end

  local function set_maps(bufnr)
    local map = function(lhs, fn, desc) vim.keymap.set({ 'n', 'x', 'o' }, lhs, fn, { buffer = bufnr, silent = true, desc = desc }) end
    map(']m', function() jump('func', false, true) end, 'C/C++ TS: next function start')
    map(']M', function() jump('func', true, true) end, 'C/C++ TS: next function end')
    map('[m', function() jump('func', false, false) end, 'C/C++ TS: prev function start')
    map('[M', function() jump('func', true, false) end, 'C/C++ TS: prev function end')
    map(']]', function() jump('class', false, true) end, 'C/C++ TS: next class/struct start')
    map('][', function() jump('class', true, true) end, 'C/C++ TS: next class/struct end')
    map('[[', function() jump('class', false, false) end, 'C/C++ TS: prev class/struct start')
    map('[]', function() jump('class', true, false) end, 'C/C++ TS: prev class/struct end')
  end

  vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('cpp-ts-motions', { clear = true }),
    pattern = { 'c', 'cpp', 'objc', 'objcpp' },
    callback = function(args) set_maps(args.buf) end,
  })
end

return M
