docker run --rm -it -v $(pwd):/work paq sh -c 'nvim -c "PaqSync" -c "sleep 5" -c "quitall" && nvim --startuptime "/work/startuptime_paq_$(date +%s).log" -c "quit"'
