docker run --rm -it -v $(pwd):/work minpac sh -c 'nvim -c "call minpac#update()" -c ":qa" && nvim  --startuptime "/work/startuptime_minpac_$(date +%s).log" -c ":q"'
