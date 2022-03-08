docker run --rm -v $(pwd):/work packer sh -c 'nvim --headless -c "PackerSync" -c "sleep 5" -c "quitall" && nvim --headless --startuptime "/work/startuptime_packer_$(date +%s).log" -c "quit"'
