#!/usr/bin/env -S sbcl --core ${HOME}/lib/sbcl-cores/gui.core --script
;; Simple timer with start/stop/reset buttons
(when (not (member :script *features*))
  (ql:quickload :cl-getopt)
  (ql:quickload :sbcl-script)
  (ql:quickload :split-sequence)
  (ql:quickload :usocket)
  (ql:quickload :uiop)
  (ql:quickload :cl-fad)
  (ql:quickload :cl-ppcre)
  (ql:quickload :trivial-clipboard)
  (ql:quickload :ltk))

(use-package :cl-getopt)
(use-package :ltk)
(setf (symbol-function 'split)
      #'split-sequence:split-sequence)

(defvar *start-time* 0
  "Start time for timer.")
(defvar *time* 0
  "Remaining time on the timer in seconds")
(defvar *running* nil
  "T for running, NIL for stopped.")

(defun seconds->hms (seconds)
  "Hacked version of cl-ana.quantity:convert-units"
  (let ((units (list 3600 60))
        (last-unit 1)
        (result ())
        (q seconds)
        factor)
    (dolist (unit units)
      (setf factor (floor (/ q unit)))
      (setf q (- q (* unit factor)))
      (push factor result))
    (push (/ q last-unit) result)
    (nreverse result)))

(defun hms->seconds (hms)
  (destructuring-bind (h m s) hms
    (+ (* 3600 h)
       (* 60 m)
       s)))

(defun time->string (seconds)
  (destructuring-bind (h m s) (seconds->hms seconds)
    (format nil "~2,'0d:~2,'0d:~2,'0d" h m s)))

(defun incf-timer (delta &optional (type :second))
  "type can be :second, :minute, :hour.  Returns *time* in seconds and
hms for convenience."
  (incf *start-time*
        (* delta
           (case type
             (:second 1)
             (:minute 60)
             (:hour 3600)
             (otherwise 1))))
  (when (minusp *start-time*)
    (setf *start-time* 0))
  (reset-timer)
  (values *time*
          (seconds->hms *time*)))

(defun set-timer (time)
  (setf *start-time* time
        *time* time))
(defun reset-timer ()
  (setf *time* *start-time*))

(defun elapse (&optional (seconds 1))
  "Cause some number of seconds to elapse on the timer."
  (if (not (minusp (decf *time* seconds)))
      *time*
      (setf *time* 0)))

(defvar *state* 0
  "State of the timer.  Can be 0 for stopped, 1 for started.")

(defvar *alarm-process* nil
  "Process for playing alarm sound")
(defparameter *alarm-path*
  "/home/ghollisjr/Music/AlarmClock_Sound/Custom_Alarmclock-mechanical.ogg")

(defun start-alarm ()
  "Starts playing alarm"
  (when *alarm-process*
    (sb-ext:process-kill *alarm-process* 9 :process-group))
  (setf *alarm-process*
        (sb-ext:run-program "/usr/bin/env"
                            (list "paplay"
                                  *alarm-path*)
                            :wait nil)))
(defun stop-alarm ()
  "Stops alarm if it's playing"
  (when (and *alarm-process*
             (sb-ext:process-alive-p *alarm-process*))
    (sb-ext:process-kill *alarm-process* 9 :process-group)))

(defun run-timer (&optional (callback (constantly nil)))
  "Steps the timer forward in operation while the timer is in the
start/run state."
  (when (= *state* 1)
    (elapse)
    (funcall callback)
    (when (zerop *time*)
      (start-alarm)
      (timer-control :stop callback)
      (return-from run-timer))
    (when (plusp *time*)
      (after 1000 (lambda ()
                    (run-timer callback))))))

(defun timer-control (arg &optional (callback (constantly nil)))
  "Accepts one of :toggle, :start, :stop, or :reset and manages the clock"
  (case arg
    (:toggle
     (if (= *state* 1)
         (timer-control :stop callback)
         (timer-control :start callback)))
    (:start (unless (or (= *state* 1)
                        (zerop *time*))
              (setf *state* 1)
              (after 1000
                     (lambda (&optional arg)
                       (declare (ignore arg))
                       (run-timer callback)))))
    (:stop (unless (= *state* 0)
             (setf *state* 0))
           (funcall callback))
    (:reset (unless (= *state* 0)
              (setf *state* 0))
            (reset-timer)
            (funcall callback))))

(defparameter *keymap*
  '((:LEFT . 113)
    (:RIGHT . 114)
    (:DOWN . 116)
    (:UP . 111)
    (:SPACE . 65)
    (:RETURN . 36)
    (:BACKSPACE . 66)
    (:SHIFT_L . 50)
    (:SHIFT_R . 62)
    (:CONTROL_L . 37)
    (:CONTROL_R . 105)
    (:ALT_L . 64)
    (:ALT_R . 108)
    (:0 . 19)))

(defun key->code (key)
  (cdr (assoc key *keymap*)))
(defun code->key (code)
  (car (rassoc code *keymap*)))

(defparameter *options*
  (list (list :long "help"
              :short "h"
              :argspec :none
              :description "show this help message")))

(defun help ()
  (format *error-output*
          "Usage: timer.lisp [timer-name]~%~%~a~%"
          (option-descriptions *options*)))

(defun main ()
  (multiple-value-bind (options remaining)
      (getopt sb-ext:*posix-argv* *options*)
    (when (gethash "h" options)
      (help)
      (return-from main))
    (with-ltk ()
    (let* ((main (make-instance 'frame
                                :name "main"))
           (top (make-instance 'frame :name "top" :master main))
           (bot (make-instance 'frame :name "bottom" :master main))
           (hms (mapcar
                 (lambda (n)
                   (make-instance 'message
                                  :foreground "black"
                                  :background "white"
                                  :name n
                                  :master top))
                 (list "h" "m" "s")))
           (start (make-instance 'button
                                 :master bot
                                 :name "start-stop"
                                 :text "start/stop"))
           (reset (make-instance 'button
                                 :master bot
                                 :name "reset"
                                 :text "reset"))
           (selected 1) ; currently selected time element
           )
      (labels ((select (i)
                 (configure (elt hms i) :foreground "white")
                 (configure (elt hms i) :background "black"))
               (deselect (i)
                 (configure (elt hms i) :foreground "black")
                 (configure (elt hms i) :background "white"))
               (start-button ()
                 (focus *tk*)
                 (timer-control :toggle #'update-messages))
               (reset-button ()
                 (focus *tk*)
                 (stop-alarm)
                 (timer-control :reset #'update-messages))
               (update-messages ()
                 (mapcar (lambda (widget time)
                           (setf (text widget)
                                 (format nil "~2,'0d" time)))
                         hms
                         (seconds->hms *time*)))
               (move (delta)
                 (deselect selected)
                 (setf selected
                       (mod (+ selected delta)
                            3))
                 (select selected)))
        (select selected)
        (pack main)
        (pack top :side :top)
        (dolist (text hms)
          (pack text :side :left))
        (update-messages)
        (bind *tk* "<KeyPress>"
              (lambda (event)
                (let* ((code (event-keycode event))
                       (key (code->key code)))
                  (case key
                    (:0 (setf *start-time* 0)
                        (reset-button))
                    (:left (move -1))
                    (:right (move 1))
                    (:up (incf-timer 1
                                     (case selected
                                       (0 :hour)
                                       (1 :minute)
                                       (2 :second)))
                         (update-messages))
                    (:down (incf-timer -1
                                       (case selected
                                         (0 :hour)
                                         (1 :minute)
                                         (2 :second)))
                           (update-messages))
                    (:space (start-button))
                    (:backspace (reset-button))))))
        (setf (command start)
              #'start-button)
        (setf (command reset)
              #'reset-button)
        (pack bot :side :bottom)
        (pack start :side :left)
        (pack reset :side :left)
        (when remaining
          (setf (title *tk*)
                (first remaining))))))))

(when (member :script *features*)
  (main))
