FROM ubuntu:20.04

# Install Vim
RUN apt-get update && apt-get install -y vim git curl \
 && apt-get clean  && rm -rf /var/lib/apt/lists/*

# Copy vim-jetpack
COPY . /root/.vim/pack/jetpack/start/vim-jetpack

# Set working directory
WORKDIR /root/.vim/pack/jetpack/start/vim-jetpack

# Install thinca/vim-themis
RUN git -C /opt clone --depth=1  https://github.com/thinca/vim-themis
ENV PATH=/opt/vim-themis/bin:$PATH
