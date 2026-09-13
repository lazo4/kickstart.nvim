vim.pack.add { 'https://github.com/David-Kunz/gen.nvim' }

require('gen').setup {
  model = 'qwen2.5-coder:3b',
  host = 'localhost',
  port = 11434,
  display_mode = 'vertical-split',
  show_prompt = true,
  show_model = true,
  command = function(options)
    local body = { model = options.model, stream = true }
    local jq_filter = 'jq --unbuffered -c \'if (.message.thinking // "") != "" then .message.content = .message.thinking  else . end\''
    local python = [[import sys, json

in_think = False

for line in sys.stdin:
    if not line.strip():
        continue
    try:
        d = json.loads(line)
        msg = d.get("message", {})
        t = msg.get("thinking")
        c = msg.get("content")

        chunk = ""
        if t:
            if not in_think:
                chunk += "<think>\n"
                in_think = True
            chunk += t
        elif c:
            if in_think:
                chunk += "\n</think>\n\n"
                in_think = False
            chunk += c
        elif in_think and d.get("done"):
            chunk += "\n</think>\n"
            in_think = False

        msg["content"] = chunk
        print(json.dumps(d), flush=True)
    except Exception:
        pass]]

    return 'curl --silent --no-buffer -X POST http://' .. options.host .. ':' .. options.port .. '/api/chat -d $body | ' .. "python3 -c '" .. python .. "'"
  end,
}

vim.keymap.set({ 'n', 'v' }, '<leader>ac', '<cmd>Gen Chat<cr>', { desc = '[A]I [C]hat' })
vim.keymap.set({ 'n', 'v' }, '<leader>am', '<cmd>Gen<cr>', { desc = '[A]I [M]enu' })
vim.keymap.set('n', '<leader>ao', require('gen').select_model, { desc = '[A]I Model [O]verride' })

-- Native fold evaluator for think blocks
_G.think_fold = function(lnum)
  local line = vim.fn.getline(lnum)
  if line:find('<think>', 1, true) then
    -- Only start a fold if </think> exists further down in the buffer
    if vim.fn.search('</think>', 'nW') > lnum then return '>1' end
  elseif line:find('</think>', 1, true) then
    return '<1'
  end
  return '='
end

vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'markdown', 'gen' },
  callback = function()
    vim.cmd [[
      syntax region thinkBlock start="<think>" end="</think>"
      highlight default link thinkBlock Comment
    ]]
    vim.opt_local.foldmethod = 'expr'
    vim.opt_local.foldexpr = 'v:lua.think_fold(v:lnum)'
    vim.opt_local.foldlevel = 0 -- Auto-close completed folds  end,
  end,
})
