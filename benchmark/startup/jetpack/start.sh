docker run --rm -it -v $(pwd):/work jetpack sh -c 'nvim -c "PackSync" -c ":qa" && nvim  --startuptime "/work/startuptime_jetpack_$(date +%s).log" -c ":q"'
