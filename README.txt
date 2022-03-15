timer.lisp is a simple wish/Tk/Ltk GUI timer that depends on a few
dependencies, minimally

* SBCL
* paplay (pulseaudio)
* quicklisp
* split-sequence (quicklisp)
* cl-getopt (quicklisp)
* sbcl-script (https://github.com/ghollisjr/sbcl-script)
* A sound file of your choice for the alarm sound effect

Make sure to edit the *alarm-path* variable to point to an alarm sound
file that you want to use for the alarm if you want an alarm to sound,
as there is no visual cue that the alarm has finished.

The included Makefile assumes that you want to install the script and
core file under your $HOME directory.  If this isn't desirable then
edit the Makefile and timer.lisp scirpt #!/... line accordingly.

Makefile/build-gui-core.sh also assume that you have installed
make-sbcl-core somewhere in your $PATH so that you can automatically
build SBCL cores for scripting.  See the sbcl-script README for more
information.

The gui.core file is larger than it needs to be.  This is because I
personally reuse SBCL cores whenever possible, so this same core can
be used for many different GUI applications with small scripts that
load them.  The minimal requirements are the ones listed above, so
changing the core would be as simple as editing build-gui-core.sh to
only load those systems into the core file.

Controlling the timer:

1. Keyboard arrow keys to adjust the HMS, Space to start/stop, and
   Backspace to reset.

2. Mouse scroll wheel to adjust the HMS, left-click start/stop & reset
   buttons.
