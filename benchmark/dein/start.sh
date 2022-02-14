docker run --rm -it dein sh -c 'nvim -c "call dein#install()" -c ":qa" && nvim  --startuptime startuptime.log -c ":q" && cat startuptime.log'
