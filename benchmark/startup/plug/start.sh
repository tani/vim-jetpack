docker run --rm -v $(pwd):/work plug sh -c 'nvim --headless -c "PlugInstall" -c "quitall" && nvim --headless  --startuptime "/work/startuptime_plug_$(date +%s).log" -c "quit"'
