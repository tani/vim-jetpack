docker run --rm -it -v $(pwd):/work packer sh -c 'nvim -c "PackerSync" -c "sleep 5" -c "quitall" && nvim --startuptime "/work/startuptime_packer_$(date +%s).log" -c "quit"'
