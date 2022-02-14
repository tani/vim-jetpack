docker run --rm -it plug sh -c 'nvim -c "PlugInstall" -c ":qa" && nvim  --startuptime startuptime.log -c ":q" && cat startuptime.log'
