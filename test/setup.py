#!/usr/bin/env python3
import os

print('nvim -u NONE --headless --cmd "source ./jetpack.vim" +JetpackSync +qa')
os.system('nvim -u NONE --headless --cmd "source ./jetpack.vim" +JetpackSync +qa')
print('nvim -u NONE --headless --cmd "source ./plug.vim" +PlugInstall +qa')
os.system('nvim -u NONE --headless --cmd "source ./plug.vim" +PlugInstall +qa')
