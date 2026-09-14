vim.pack.add { 'https://github.com/olimorris/codecompanion.nvim' }

require('codecompanion').setup {
  interactions = {
    chat = {
      adapter = {
        name = 'ollama',
        model = 'qwen3.5-8k:2b',
      },
      tools = {
        ['ask_questions'] = {
          visible = true,
        },
        crates_io_search = {
          description = 'Search for rust crates on crates.io',
          name = 'crates_io_search',
          cmds = {
            function(self, args)
              local crate_query = args.crate_query
              local command = { 'cargo', 'search', crate_query }
              if args.limit then
                table.insert(command, '--limit')
                table.insert(command, tostring(args.limit))
              end
              local output = vim.system(command):wait()
              if output.code ~= 0 or not output.stdout then return { status = 'error', data = 'Error running cargo search' } end
              return { status = 'success', data = output.stdout }
            end,
          },

          schema = {
            type = 'function',
            ['function'] = {
              name = 'crates_io_search',
              description = 'Search for rust crates on crates.io',
              parameters = {
                type = 'object',
                properties = {
                  crate_query = {
                    type = 'string',
                    description = 'The search terms to use',
                  },
                  limit = {
                    type = 'number',
                    description = '(Optional) The maximum number of results to return',
                  },
                },
                required = {
                  'crate_query',
                },
                additionalProperties = false,
              },
              strict = true,
            },
          },
          output = {
            success = function(self, stdout, meta)
              local chat = meta.tools.chat
              return chat:add_tool_output(self, tostring(stdout[1]), 'Ran crate search for ' .. self.args.crate_query)
            end,
            error = function(self, stderr, meta) return vim.notify('An error occurred', vim.log.levels.ERROR) end,
          },
        },
      },
    },
  },
}

vim.keymap.set('n', '<leader>cc', '<cmd>CodeCompanionChat<cr>', { desc = '[C]odeCompanion [C]hat' })
