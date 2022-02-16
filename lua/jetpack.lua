function startup(config)
  vim.fn['pack#begin']()
  config(function (plugin)
    if (type(plugin) == 'string') then
      vim.fn['pack#add'](plugin)
    else
      vim.fn['pack#add'](plugin[1], plugin)
    end
  end)
  vim.fn['pack#end']()
end

function setup(config)
  vim.fn['pack#begin']()
  for _, plugin in pairs(config) do
    if (type(plugin) == 'string') then
      vim.fn['pack#add'](plugin)
    else
      vim.fn['pack#add'](plugin[1], plugin)
    end
  end
  vim.fn['pack#end']()
end

return { startup = startup }
