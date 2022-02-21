FROM nvim
RUN curl https://raw.githubusercontent.com/Shougo/dein.vim/master/bin/installer.sh > installer.sh && sh ./installer.sh /root/.cache/dein
COPY vimrc /root/.config/nvim/init.vim
