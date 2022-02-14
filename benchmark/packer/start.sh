docker run --rm -it packer sh -c '/nvim-linux64/bin/nvim -c "PackerSync" -c ":qa" && /nvim-linux64/bin/nvim --startuptime startuptime.log -c ":q" && cat startuptime.log'
