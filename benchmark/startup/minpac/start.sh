docker run --rm -v $(pwd):/work minpac sh -c 'nvim --headless -c "call minpac#update()" -c "quitall" && nvim --headless  --startuptime "/work/startuptime_minpac_$(date +%s).log" -c "quit"'
