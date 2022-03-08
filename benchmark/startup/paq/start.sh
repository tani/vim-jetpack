docker run --rm -v $(pwd):/work paq sh -c 'nvim --headless -c "PaqSync" -c "sleep 5" -c "quitall" && nvim --headless --startuptime "/work/startuptime_paq_$(date +%s).log" -c "quit"'
