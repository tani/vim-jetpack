-- =============== JETPACK.vim =================
--       The lightning-fast plugin manager
--      Copyrigh (c) 2022 TANGUCHI Masaya.
--           All Rights Reserved.
--  MIT License.
-- =============================================

local alias = {
  run = 'do',
  ft = 'for'
}

local function use(plugin)
  if (type(plugin) == 'string') then
    vim.fn['jetpack#add'](plugin)
  else
    local name = plugin[1]
    plugin[1] = nil
    if vim.fn.type(plugin) == vim.v.t_list then
      vim.fn['jetpack#add'](name)
    else 
      for key, value in pairs(alias) do
        if plugin[key] ~= nil then
          plugin[value] = plugin[key]
        end
      end
      local opts = plugin
      vim.fn['jetpack#add'](name, opts)
    end
  end
end

local function startup(config)
  vim.fn['jetpack#begin']()
  config(use)
  vim.fn['jetpack#end']()
end

local function setup(config)
  vim.fn['jetpack#begin']()
  for _, plugin in pairs(config) do
    use(plugin)
  end
  vim.fn['jetpack#end']()
end

return {
  startup = startup,
  setup = setup,
  tap = vim.fn["jetpack#tap"],
  sync = vim.fn["jetpack#sync"]
}
