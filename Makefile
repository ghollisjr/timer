gui.core: build-gui-core.sh
	./build-gui-core.sh
install: gui.core
	mkdir -p ${HOME}/lib/sbcl-cores/
	cp -v gui.core ${HOME}/lib/sbcl-cores/
	mkdir -p ${HOME}/bin/
	cp -v timer.lisp ${HOME}/bin/
