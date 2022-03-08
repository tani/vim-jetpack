docker run --rm -v $(pwd):/work jetpack sh -c 'nvim --headless -c "JetpackSync" -c "quitall" && nvim --headless  --startuptime "/work/startuptime_jetpack_$(date +%s).log" -c "quit"'
