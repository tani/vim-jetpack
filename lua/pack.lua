function setup(config)
  vim.fn['pack#begin']()
  config(function (plugin)
    if (type(plugin) == 'string') then
      vim.fn['pack#add'](plugin)
    else
      vim.fn['pack#add'](plugin[0], plugin)
    end
  end)
  vim.fn['pack#end']()
end

return { setup = setup }
