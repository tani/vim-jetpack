FROM ubuntu:20.04
RUN apt-get update && apt-get upgrade -y && apt-get install -y git curl
RUN curl -fsSL https://github.com/neovim/neovim/releases/download/v0.6.1/nvim-linux64.tar.gz | tar zxf -
ENV PATH=/nvim-linux64/bin:$PATH
RUN curl -fLo /root/.config/nvim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
COPY vimrc /root/.config/nvim/init.vim
