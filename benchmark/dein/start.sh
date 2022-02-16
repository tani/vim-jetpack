docker run --rm -it -v $(pwd):/work dein sh -c 'nvim -c "call dein#install()" -c ":qa" && nvim  --startuptime "/work/startuptime_dein_$(date +%s).log" -c ":q"'
