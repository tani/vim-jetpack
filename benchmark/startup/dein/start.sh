docker run --rm -v $(pwd):/work dein sh -c 'nvim --headless -c "call dein#install()" -c "quitall" && nvim --headless  --startuptime "/work/startuptime_dein_$(date +%s).log" -c "quit"'
