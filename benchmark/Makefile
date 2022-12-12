all: run

setup:
	./setup.py

run: setup
	./run.py

stat: run
	./stat.py

.PHONY: clean

clean:
	rm -rf ./*.log ./*.png pack plugged

profile:
	nvim -u jetpack.vim --startuptime startup.log --cmd 'profile start profile.log' --cmd 'profile func *' --cmd 'profile file *' --cmd 'profile! func *' --cmd 'profile! file *' -c 'prorfile pause' -c 'noautocmd qall'
