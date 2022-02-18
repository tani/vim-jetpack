local function startup(config)
  vim.fn['jetpack#begin']()
  config(function (plugin)
    if (type(plugin) == 'string') then
      vim.fn['jetpack#add'](plugin)
    else
      local name = plugin[1]
      -- we don't want the title to be included because
      -- vimscript can't take lua table where you mix array-like and map-like
      plugin[1] = nil
      local opts = plugin
      vim.fn['jetpack#add'](name, opts)
    end
  end)
  vim.fn['pack#end']()
end

local function setup(config)
  vim.fn['jetpack#begin']()
  for _, plugin in pairs(config) do
    if (type(plugin) == 'string') then
      vim.fn['jetpack#add'](plugin)
    else
      local name = plugin[1]
      -- we don't want the title to be included because
      -- vimscript can't take lua table where you mix array-like and map-like
      plugin[1] = nil
      local opts = plugin
      vim.fn['jetpack#add'](name, opts)
    end
  end
  vim.fn['jetpack#end']()
end

return {
  startup = startup,
  setup = setup
}
