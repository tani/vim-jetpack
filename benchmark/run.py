#!/usr/bin/env python3
import os

cmd = 'nvim -u "{}" --headless --startuptime "{}" +qa!'
for m in ['jetpack', 'plug']:
    if os.path.exists(m + '.log'):
        os.unlink(m + '.log')
    for i in range(100):
        print('{:4d} {}'.format(i, cmd.format('./' + m + '.vim', './' + m + '.log')))
        os.system(cmd.format('./' + m + '.vim', './' + m + '.log'))
