timer.lisp is a simple wish/Tk/Ltk GUI timer that depends on a few
dependencies, minimally

* quicklisp
* cl-getopt (https://github.com/ghollisjr/cl-getopt)
* sbcl-script (https://github.com/ghollisjr/sbcl-script)

The included Makefile assumes that you want to install the script and
core file under your $HOME directory.  If this isn't desirable then
edit the Makefile and timer.lisp scirpt #!/... line accordingly.

Makefile/build-gui-core.sh also assume that you have installed
make-sbcl-core somewhere in your $PATH so that you can automatically
build SBCL cores for scripting.  See the sbcl-script README for more
information.
