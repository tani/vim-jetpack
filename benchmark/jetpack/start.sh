docker run --rm -it jetpack sh -c 'nvim -c "PackSync" -c ":qa" && nvim  --startuptime startuptime.log -c ":q" && cat startuptime.log'
