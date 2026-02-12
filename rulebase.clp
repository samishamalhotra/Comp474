;;; ============================================================
;;; rulebase.clp
;;; Academic Course Advisor — Rule Base
;;;
;;; Session flow:
;;;   get-student-id -> show-history -> get-semester
;;;   -> get-desired-credits -> get-workload
;;;   -> compute-eligibility -> output
;;; ============================================================


;;; ============================================================
;;; PHASE 1: GET STUDENT ID
;;; ============================================================

(defrule get-student-id
   "Prompt for a student ID and loop until a valid one is found"
   ?p <- (phase (current get-student-id))
   =>
   (printout t "==========================================" crlf)
   (printout t "      Welcome to the Academic Advisor     " crlf)
   (printout t "==========================================" crlf)
   (bind ?found FALSE)
   (bind ?id nil)
   (while (not ?found)
      (printout t "Enter your Student ID: ")
      (bind ?id (read))
      (if (any-factp ((?s student)) (eq ?s:id ?id))
         then (bind ?found TRUE)
         else (printout t "Student ID '" ?id "' not found. Please try again." crlf)))
   (retract ?p)
   (assert (active-student ?id))
   (assert (phase (current show-history))))


;;; ============================================================
;;; PHASE 2: SHOW HISTORY
;;; ============================================================

(defrule show-student-history
   "Display the student profile and completed course history"
   ?p <- (phase (current show-history))
   (active-student ?id)
   =>
   (do-for-fact ((?s student)) (eq ?s:id ?id)
      (printout t crlf "------------------------------------------" crlf)
      (printout t " Student ID : " ?s:id   crlf)
      (printout t " Year       : " ?s:year crlf)
      (printout t " GPA        : " ?s:gpa  crlf)
      (printout t "------------------------------------------" crlf))
   (printout t " Completed Courses:" crlf)
   (bind ?count 0)
   (do-for-all-facts ((?c completed) (?co course))
      (and (eq ?c:student-id ?id) (eq ?c:code ?co:code))
      (printout t "   - " ?c:code " : " ?co:name crlf)
      (bind ?count (+ ?count 1)))
   (if (= ?count 0)
      then (printout t "   No completed courses on record." crlf))
   (retract ?p)
   (assert (phase (current get-semester))))


;;; ============================================================
;;; PHASE 3: GET SEMESTER
;;; ============================================================

(defrule get-semester
   "Prompt for the target semester and validate input"
   ?p <- (phase (current get-semester))
   (active-student ?id)
   =>
   (bind ?valid FALSE)
   (bind ?sem 0)
   (while (not ?valid)
      (printout t crlf "Which semester are you planning for?" crlf)
      (printout t "  1 = Fall   2 = Winter   3 = Summer" crlf)
      (printout t "Enter choice: ")
      (bind ?sem (read))
      (if (or (= ?sem 1) (= ?sem 2) (= ?sem 3))
         then (bind ?valid TRUE)
         else (printout t "Invalid input. Please enter 1, 2, or 3." crlf)))
   (retract ?p)
   (assert (chosen-semester ?id ?sem))
   (assert (phase (current get-desired-credits))))


;;; ============================================================
;;; PHASE 4: GET DESIRED CREDITS
;;; ============================================================

(defrule get-desired-credits
   "Prompt for desired credit count and validate input"
   ?p  <- (phase (current get-desired-credits))
   ?cs <- (chosen-semester ?id ?sem)
   =>
   (bind ?valid FALSE)
   (bind ?cr 0)
   (while (not ?valid)
      (printout t crlf "How many credits would you like to take this semester?" crlf)
      (printout t "  Enter a number between 3 and 15: ")
      (bind ?cr (read))
      (if (and (numberp ?cr) (>= ?cr 3) (<= ?cr 15))
         then (bind ?valid TRUE)
         else (printout t "Invalid input. Please enter a number between 3 and 15." crlf)))
   (retract ?p)
   (retract ?cs)
   (assert (chosen-credits ?id ?sem ?cr))
   (assert (phase (current get-workload))))


;;; ============================================================
;;; PHASE 5: GET WORKLOAD PREFERENCE
;;; ============================================================

(defrule get-workload
   "Ask the student how challenging a workload they want"
   ?p  <- (phase (current get-workload))
   ?cc <- (chosen-credits ?id ?sem ?cr)
   =>
   (printout t crlf "How heavy of a workload are you looking for?" crlf)
   (printout t "  1 = Light    (easy courses only)"               crlf)
   (printout t "  2 = Moderate (easy and medium difficulty)"      crlf)
   (printout t "  3 = Heavy    (all difficulties including hard)" crlf)
   (bind ?valid FALSE)
   (bind ?wl 0)
   (while (not ?valid)
      (printout t "Enter choice: ")
      (bind ?wl (read))
      (if (or (= ?wl 1) (= ?wl 2) (= ?wl 3))
         then (bind ?valid TRUE)
         else (printout t "Invalid input. Please enter 1, 2, or 3." crlf)))
   (bind ?workload
      (if (= ?wl 1) then light
       else (if (= ?wl 2) then moderate
             else heavy)))
   (retract ?p)
   (retract ?cc)
   (assert (session (student-id ?id) (semester ?sem) (desired-credits ?cr) (workload ?workload)))
   (assert (phase (current compute-eligibility))))


;;; ============================================================
;;; PHASE 6: COMPUTE ELIGIBILITY
;;; All blocking rules at salience 20 — fire before mark-eligible
;;; ============================================================

(defrule block-missing-prereq
   "Block a course if the student has not completed a required prerequisite"
   (declare (salience 20))
   (phase (current compute-eligibility))
   (active-student ?id)
   (course (code ?c))
   (prerequisite (course ?c) (required ?r))
   (not (completed (student-id ?id) (code ?r)))
   =>
   (assert (blocked (student-id ?id) (code ?c) (reason missing-prereq))))

(defrule block-low-gpa
   "Block a course if the student's GPA is below the course minimum"
   (declare (salience 20))
   (phase (current compute-eligibility))
   (active-student ?id)
   (student (id ?id) (gpa ?g))
   (gpa-requirement (course ?c) (minimum ?m))
   (test (< ?g ?m))
   =>
   (assert (blocked (student-id ?id) (code ?c) (reason low-gpa))))

(defrule block-already-completed
   "Block a course the student has already passed"
   (declare (salience 20))
   (phase (current compute-eligibility))
   (active-student ?id)
   (completed (student-id ?id) (code ?c))
   =>
   (assert (blocked (student-id ?id) (code ?c) (reason already-completed))))

(defrule block-level4-year-too-low
   "Block level-4 courses for students below year 3"
   (declare (salience 20))
   (phase (current compute-eligibility))
   (active-student ?id)
   (student (id ?id) (year ?y))
   (course (code ?c) (level 4))
   (test (< ?y 3))
   =>
   (assert (blocked (student-id ?id) (code ?c) (reason year-too-low))))

(defrule block-level3-year1
   "Block level-3 courses for year-1 students"
   (declare (salience 20))
   (phase (current compute-eligibility))
   (active-student ?id)
   (student (id ?id) (year 1))
   (course (code ?c) (level 3))
   =>
   (assert (blocked (student-id ?id) (code ?c) (reason year-too-low))))

(defrule block-wrong-semester
   "Block courses not offered in the student's chosen semester"
   (declare (salience 20))
   (phase (current compute-eligibility))
   (active-student ?id)
   (session (student-id ?id) (semester ?sem))
   (course (code ?c) (semester ?avail))
   ;; 1=fall, 2=winter, 3=summer. Block if course is fall-only but student chose winter, etc.
   (test (not (or (eq ?avail both)
                  (and (= ?sem 1) (eq ?avail fall))
                  (and (= ?sem 2) (eq ?avail winter)))))
   =>
   (assert (blocked (student-id ?id) (code ?c) (reason wrong-semester))))

(defrule block-difficulty-too-hard
   "Block courses that exceed the student's chosen workload preference"
   (declare (salience 20))
   (phase (current compute-eligibility))
   (active-student ?id)
   (session (student-id ?id) (workload ?wl))
   (course (code ?c) (difficulty ?d))
   ;; light: block medium and hard. moderate: block hard only. heavy: block nothing.
   (test (or (and (eq ?wl light)    (or (eq ?d medium) (eq ?d hard)))
             (and (eq ?wl moderate) (eq ?d hard))))
   =>
   (assert (blocked (student-id ?id) (code ?c) (reason difficulty-too-high))))

(defrule mark-eligible
   "Mark a course eligible if no blocking condition applies"
   (declare (salience 0))
   (phase (current compute-eligibility))
   (active-student ?id)
   (course (code ?c))
   (not (blocked (student-id ?id) (code ?c) (reason ?)))
   =>
   (assert (eligible (student-id ?id) (code ?c))))

(defrule finish-eligibility
   "Advance to the output phase once eligibility is fully determined"
   (declare (salience -10))
   ?p <- (phase (current compute-eligibility))
   =>
   (retract ?p)
   (assert (phase (current output))))


;;; ============================================================
;;; PHASE 7: OUTPUT RECOMMENDATIONS
;;; ============================================================

(defrule output-recommendations
   "Print eligible course recommendations up to the desired credit limit"
   ?p <- (phase (current output))
   (active-student ?id)
   (session (student-id ?id) (semester ?sem) (desired-credits ?max) (workload ?wl))
   =>
   (bind ?sem-name
      (if (= ?sem 1) then "Fall"
       else (if (= ?sem 2) then "Winter" else "Summer")))
   (bind ?wl-name
      (if (eq ?wl light) then "Light"
       else (if (eq ?wl moderate) then "Moderate" else "Heavy")))
   (printout t crlf "==========================================" crlf)
   (printout t "  Recommended Courses for " ?id              crlf)
   (printout t "  Semester  : " ?sem-name                    crlf)
   (printout t "  Workload  : " ?wl-name                     crlf)
   (printout t "  Target    : " ?max " credits"              crlf)
   (printout t "==========================================" crlf)
   (bind ?total 0)
   (bind ?found FALSE)
   ;; Easy courses first, then medium, then hard — gradual difficulty ramp
   (foreach ?diff (create$ easy medium hard)
      (do-for-all-facts ((?e eligible) (?co course))
         (and (eq ?e:student-id ?id)
              (eq ?e:code ?co:code)
              (eq ?co:difficulty ?diff))
         (if (<= (+ ?total ?co:credits) ?max)
            then
            (printout t "  " ?co:code " - " ?co:name
                      " (" ?co:credits " cr | " ?co:difficulty ")" crlf)
            (bind ?total (+ ?total ?co:credits))
            (bind ?found TRUE))))
   (if (not ?found)
      then
      (printout t "  No eligible courses match your criteria." crlf)
      (printout t "  Try increasing your workload preference or credit count." crlf)
      else
      (printout t "------------------------------------------" crlf)
      (printout t "  Total recommended : " ?total " credits"  crlf))
   (printout t "==========================================" crlf)
   (printout t "  Advising complete. Good luck!"             crlf)
   (printout t "==========================================" crlf)
   (retract ?p))
