rm -rf "$(pwd)/pack"
nvim --headless -u vimrc -c 'JetpackSync' -c 'quit'
nvim --headless -u vimrc -c "source $(pwd)/test.vim" -c 'quit'
