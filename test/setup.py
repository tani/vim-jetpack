#!/usr/bin/env python3
import os

print('nvim -u ./jetpack.vim --headless +JetpackSync +qa')
os.system('nvim -u ./jetpack.vim --headless +JetpackSync +qa')
print('nvim -u ./plug.vim --headless +PlugInstall +qa')
os.system('nvim -u ./plug.vim --headless +PlugInstall +qa')
