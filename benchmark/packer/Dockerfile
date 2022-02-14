FROM ubuntu:20.04
RUN apt-get update && apt-get upgrade -y && apt-get install -y git curl
RUN curl -fsSL https://github.com/neovim/neovim/releases/download/v0.6.1/nvim-linux64.tar.gz | tar zxf -
ENV PATH=/nvim-linux64/bin:$PATH
RUN git clone --depth 1 https://github.com/wbthomason/packer.nvim /root/.local/share/nvim/site/pack/packer/start/packer.nvim
COPY vimrc /root/.config/nvim/init.vim
