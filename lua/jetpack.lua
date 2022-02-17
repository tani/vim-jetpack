function startup(config)
  vim.fn['jetpack#begin']()
  config(function (plugin)
    if (type(plugin) == 'string') then
      vim.fn['jetpack#add'](plugin)
    else
      vim.fn['jetpack#add'](plugin[1], plugin)
    end
  end)
  vim.fn['pack#end']()
end

function setup(config)
  vim.fn['jetpack#begin']()
  for _, plugin in pairs(config) do
    if (type(plugin) == 'string') then
      vim.fn['jetpack#add'](plugin)
    else
      vim.fn['jetpack#add'](plugin[1], plugin)
    end
  end
  vim.fn['jetpack#end']()
end

return { startup = startup }
