docker run --rm -it -v $(pwd):/work plug sh -c 'nvim -c "PlugInstall" -c ":qa" && nvim  --startuptime "/work/startuptime_plug_$(date +%s).log" -c ":q"'
