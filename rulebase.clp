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
   (test (not (or (eq ?avail both)
                  (and (= ?sem 1) (eq ?avail fall))
                  (and (= ?sem 2) (eq ?avail winter))
                  (and (= ?sem 3) (eq ?avail summer)))))
   =>
   (assert (blocked (student-id ?id) (code ?c) (reason wrong-semester))))


(defrule block-difficulty-too-hard
   "Block courses that exceed the student's chosen workload preference"
   (declare (salience 20))
   (phase (current compute-eligibility))
   (active-student ?id)
   (session (student-id ?id) (workload ?wl))
   (course (code ?c) (difficulty ?d))
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


;;; ============================================================
;;; ADVISORY RULES (salience 10)
;;; Fire after eligibility is marked but before phase transitions
;;; ============================================================

(defrule mark-summer-courses-priority
   "If student chose Summer, mark eligible summer-offered courses as priority"
   (declare (salience 10))
   (phase (current compute-eligibility))
   (active-student ?id)
   (session (student-id ?id) (semester 3))
   (eligible (student-id ?id) (code ?c))
   (course (code ?c) (semester summer))
   (not (summer-priority (student-id ?id) (code ?c)))
   =>
   (assert (summer-priority (student-id ?id) (code ?c))))



(defrule explain-blocked-course
   (phase (current compute-eligibility))
   (blocked (student-id ?id) (code ?c) (reason ?r))
   =>
   (assert (warning (student-id ?id)
      (message
         (str-cat "Cannot take " ?c ": "
            (if (eq ?r missing-prereq) then "missing prerequisite"
            else (if (eq ?r low-gpa) then "GPA below requirement"
            else (if (eq ?r already-completed) then "already completed"
            else (if (eq ?r year-too-low) then "year standing too low"
            else (if (eq ?r wrong-semester) then "not offered this semester"
            else (if (eq ?r difficulty-too-high) then "exceeds preferred workload"
            else "restricted")))))))))))

(deffunction count-completed (?id)
   (bind ?n 0)
   (do-for-all-facts ((?c completed))
      (eq ?c:student-id ?id)
      (bind ?n (+ ?n 1)))
   ?n)

(defrule nearing-graduation
   (phase (current compute-eligibility))
   (active-student ?id)
   (student (id ?id) (year 4))
   (test (>= (count-completed ?id) 12))
   =>
   (assert (warning (student-id ?id)
      (message "You appear close to completing degree requirements."))))

(defrule suggest-comp249-gateway
   (phase (current compute-eligibility))
   (active-student ?id)
   (eligible (student-id ?id) (code COMP249))
   (not (completed (student-id ?id) (code COMP249)))
   =>
   (assert (warning (student-id ?id)
      (message "COMP249 is a gateway course required for many advanced CS courses."))))

(defrule warn-low-gpa-heavy
   (phase (current compute-eligibility))
   (student (id ?id) (gpa ?g))
   (session (student-id ?id) (workload heavy))
   (test (< ?g 2.7))
   =>
   (assert (warning (student-id ?id)
      (message "Heavy workload may be risky given your current GPA."))))

(defrule warn-light-load-senior
   (phase (current compute-eligibility))
   (student (id ?id) (year 4))
   (session (student-id ?id) (desired-credits ?cr))
   (test (< ?cr 9))
   =>
   (assert (warning (student-id ?id)
      (message "Taking fewer than 9 credits may delay graduation."))))

(defrule suggest-encs282-early
   "Recommend ENCS282 early for year 1-2 students"
   (declare (salience 10))
   (phase (current compute-eligibility))
   (active-student ?id)
   (student (id ?id) (year ?y))
   (test (<= ?y 2))
   (eligible (student-id ?id) (code ENCS282))
   (not (completed (student-id ?id) (code ENCS282)))
   =>
   (assert (warning (student-id ?id) 
                   (message "ENCS282 (Technical Writing) is required with no prerequisites - consider taking it early"))))

(defrule missing-encs393
   (phase (current compute-eligibility))
   (student (id ?id) (year 4))
   (not (completed (student-id ?id) (code ENCS393)))
   =>
   (assert (warning (student-id ?id)
      (message "ENCS393 is required for graduation — consider taking it soon."))))

(defrule suggest-ai-track-high-gpa
   "Suggest AI track to high GPA year 3+ students"
   (declare (salience 10))
   (phase (current compute-eligibility))
   (active-student ?id)
   (student (id ?id) (gpa ?g) (year ?y))
   (test (and (>= ?g 3.5) (>= ?y 3)))
   (eligible (student-id ?id) (code COMP472))
   =>
   (assert (warning (student-id ?id)
                   (message "Your high GPA qualifies you for AI track courses like COMP472, COMP474, COMP432"))))

(defrule warn-behind-on-core-year3
   "Warn year 3+ students missing 200-level core"
   (declare (salience 10))
   (phase (current compute-eligibility))
   (active-student ?id)
   (student (id ?id) (year ?y))
   (test (>= ?y 3))
   (not (completed (student-id ?id) (code COMP228)))
   =>
   (assert (warning (student-id ?id)
                   (message "You are missing 200-level core courses - catch up to stay on track"))))

(defrule suggest-core-priority-general
   "Suggest prioritizing core courses when both core and electives are available"
   (declare (salience 10))
   (phase (current compute-eligibility))
   (active-student ?id)
   (eligible (student-id ?id) (code ?core))
   (course (code ?core) (category core))
   (eligible (student-id ?id) (code ?elec))
   (course (code ?elec) (category cs-elective))
   =>
   (assert (warning (student-id ?id)
                   (message "Tip: Prioritize core courses over electives to stay on graduation track"))))

(defrule warn-many-hard-courses-available
   "Warn when many hard courses are available"
   (declare (salience 10))
   (phase (current compute-eligibility))
   (active-student ?id)
   (eligible (student-id ?id) (code ?c1))
   (course (code ?c1) (difficulty hard))
   (eligible (student-id ?id) (code ?c2))
   (course (code ?c2) (difficulty hard))
   (test (neq ?c1 ?c2))
   (eligible (student-id ?id) (code ?c3))
   (course (code ?c3) (difficulty hard))
   (test (and (neq ?c1 ?c3) (neq ?c2 ?c3)))
   =>
   (assert (warning (student-id ?id)
                   (message "Many hard courses are available - consider balancing your schedule with easier courses"))))

;;; ============================================================
;;; D2 TODO 3 — FUZZY RECOMMENDATION LAYER
;;; Runs during compute-eligibility, after eligible courses exist,
;;; before finish-eligibility switches to output.
;;; ============================================================

(defrule create-fuzzy-course-target
   "Every eligible course becomes a target for fuzzy evaluation"
   (declare (salience 4))
   (phase (current compute-eligibility))
   (eligible (student-id ?id) (code ?c))
   (not (fuzzy-course-target (student-id ?id) (code ?c)))
   =>
   (assert (fuzzy-course-target (student-id ?id) (code ?c))))

(defrule map-light-workload-to-score
   (declare (salience 4))
   (phase (current compute-eligibility))
   (session (student-id ?id) (workload light))
   (not (workload-score (student-id ?id) (value ?)))
   =>
   (assert (workload-score (student-id ?id) (value 2))))

(defrule map-moderate-workload-to-score
   (declare (salience 4))
   (phase (current compute-eligibility))
   (session (student-id ?id) (workload moderate))
   (not (workload-score (student-id ?id) (value ?)))
   =>
   (assert (workload-score (student-id ?id) (value 5))))

(defrule map-heavy-workload-to-score
   (declare (salience 4))
   (phase (current compute-eligibility))
   (session (student-id ?id) (workload heavy))
   (not (workload-score (student-id ?id) (value ?)))
   =>
   (assert (workload-score (student-id ?id) (value 8))))

(defrule begin-fuzzy-evaluation-for-course
   "Start simplified TODO 3 evaluation for one eligible course at a time"
   (declare (salience 3))
   (phase (current compute-eligibility))
   (fuzzy-course-target (student-id ?id) (code ?c))
   (not (fuzzy-course-evaluated (student-id ?id) (code ?c)))
   (not (active-fuzzy-course (student-id ?any) (code ?anyc)))
   =>
   (assert (active-fuzzy-course (student-id ?id) (code ?c)))
)

;;; ---- Simplified TODO 3 score-accumulator rules ----
;;; low = 2, medium = 5, high = 8

(defrule score-low-gpa-easy-course
   (declare (salience 2))
   (phase (current compute-eligibility))
   (active-fuzzy-course (student-id ?id) (code ?c))
   (student (id ?id) (gpa ?g&:(< ?g 2.7)))
   (course-difficulty-score (code ?c) (value ?d&:(<= ?d 3)))
   =>
   (assert (course-score-contribution
              (student-id ?id)
              (code ?c)
              (value 5)
              (source gpa-difficulty)))
)

(defrule score-low-gpa-medium-course
   (declare (salience 2))
   (phase (current compute-eligibility))
   (active-fuzzy-course (student-id ?id) (code ?c))
   (student (id ?id) (gpa ?g&:(< ?g 2.7)))
   (course-difficulty-score (code ?c) (value ?d&:(and (> ?d 3) (< ?d 7))))
   =>
   (assert (course-score-contribution
              (student-id ?id)
              (code ?c)
              (value 2)
              (source gpa-difficulty)))
)

(defrule score-low-gpa-hard-course
   (declare (salience 2))
   (phase (current compute-eligibility))
   (active-fuzzy-course (student-id ?id) (code ?c))
   (student (id ?id) (gpa ?g&:(< ?g 2.7)))
   (course-difficulty-score (code ?c) (value ?d&:(>= ?d 7)))
   =>
   (assert (course-score-contribution
              (student-id ?id)
              (code ?c)
              (value 2)
              (source gpa-difficulty)))
)

(defrule score-medium-gpa-easy-course
   (declare (salience 2))
   (phase (current compute-eligibility))
   (active-fuzzy-course (student-id ?id) (code ?c))
   (student (id ?id) (gpa ?g&:(and (>= ?g 2.7) (< ?g 3.5))))
   (course-difficulty-score (code ?c) (value ?d&:(<= ?d 3)))
   =>
   (assert (course-score-contribution
              (student-id ?id)
              (code ?c)
              (value 8)
              (source gpa-difficulty)))
)

(defrule score-medium-gpa-medium-course
   (declare (salience 2))
   (phase (current compute-eligibility))
   (active-fuzzy-course (student-id ?id) (code ?c))
   (student (id ?id) (gpa ?g&:(and (>= ?g 2.7) (< ?g 3.5))))
   (course-difficulty-score (code ?c) (value ?d&:(and (> ?d 3) (< ?d 7))))
   =>
   (assert (course-score-contribution
              (student-id ?id)
              (code ?c)
              (value 5)
              (source gpa-difficulty)))
)

(defrule score-medium-gpa-hard-course
   (declare (salience 2))
   (phase (current compute-eligibility))
   (active-fuzzy-course (student-id ?id) (code ?c))
   (student (id ?id) (gpa ?g&:(and (>= ?g 2.7) (< ?g 3.5))))
   (course-difficulty-score (code ?c) (value ?d&:(>= ?d 7)))
   =>
   (assert (course-score-contribution
              (student-id ?id)
              (code ?c)
              (value 2)
              (source gpa-difficulty)))
)

(defrule score-high-gpa-easy-course
   (declare (salience 2))
   (phase (current compute-eligibility))
   (active-fuzzy-course (student-id ?id) (code ?c))
   (student (id ?id) (gpa ?g&:(>= ?g 3.5)))
   (course-difficulty-score (code ?c) (value ?d&:(<= ?d 3)))
   =>
   (assert (course-score-contribution
              (student-id ?id)
              (code ?c)
              (value 8)
              (source gpa-difficulty)))
)

(defrule score-high-gpa-medium-course
   (declare (salience 2))
   (phase (current compute-eligibility))
   (active-fuzzy-course (student-id ?id) (code ?c))
   (student (id ?id) (gpa ?g&:(>= ?g 3.5)))
   (course-difficulty-score (code ?c) (value ?d&:(and (> ?d 3) (< ?d 7))))
   =>
   (assert (course-score-contribution
              (student-id ?id)
              (code ?c)
              (value 8)
              (source gpa-difficulty)))
)

(defrule score-high-gpa-hard-course
   (declare (salience 2))
   (phase (current compute-eligibility))
   (active-fuzzy-course (student-id ?id) (code ?c))
   (student (id ?id) (gpa ?g&:(>= ?g 3.5)))
   (course-difficulty-score (code ?c) (value ?d&:(>= ?d 7)))
   =>
   (assert (course-score-contribution
              (student-id ?id)
              (code ?c)
              (value 5)
              (source gpa-difficulty)))
)

(defrule score-light-workload-hard-course
   (declare (salience 2))
   (phase (current compute-eligibility))
   (active-fuzzy-course (student-id ?id) (code ?c))
   (workload-score (student-id ?id) (value ?w&:(<= ?w 3)))
   (course-difficulty-score (code ?c) (value ?d&:(>= ?d 7)))
   =>
   (assert (course-score-contribution
              (student-id ?id)
              (code ?c)
              (value 2)
              (source workload-difficulty)))
)

(defrule score-moderate-workload-medium-course
   (declare (salience 2))
   (phase (current compute-eligibility))
   (active-fuzzy-course (student-id ?id) (code ?c))
   (workload-score (student-id ?id) (value ?w&:(and (> ?w 3) (< ?w 7))))
   (course-difficulty-score (code ?c) (value ?d&:(and (> ?d 3) (< ?d 7))))
   =>
   (assert (course-score-contribution
              (student-id ?id)
              (code ?c)
              (value 5)
              (source workload-difficulty)))
)

(defrule score-heavy-workload-hard-course
   (declare (salience 2))
   (phase (current compute-eligibility))
   (active-fuzzy-course (student-id ?id) (code ?c))
   (workload-score (student-id ?id) (value ?w&:(>= ?w 7)))
   (course-difficulty-score (code ?c) (value ?d&:(>= ?d 7)))
   =>
   (assert (course-score-contribution
              (student-id ?id)
              (code ?c)
              (value 8)
              (source workload-difficulty)))
)

(defrule finalize-fuzzy-course
   "Average TODO 3 score contributions and store one crisp recommendation per course"
   (declare (salience 1))
   (phase (current compute-eligibility))
   ?af <- (active-fuzzy-course (student-id ?id) (code ?c))
   (exists (course-score-contribution (student-id ?id) (code ?c) (value ?)))
   =>
   (bind ?sum 0)
   (bind ?count 0)

   (do-for-all-facts ((?sc course-score-contribution))
      (and (eq ?sc:student-id ?id)
           (eq ?sc:code ?c))
      (bind ?sum (+ ?sum ?sc:value))
      (bind ?count (+ ?count 1)))

   (bind ?score (/ ?sum ?count))

   (bind ?label
      (if (< ?score 3.5)
         then low
         else
         (if (< ?score 6.5)
            then medium
            else high)))

   (assert (fuzzy-course-recommendation
              (student-id ?id)
              (code ?c)
              (score ?score)
              (label ?label)))

   (assert (fuzzy-course-evaluated (student-id ?id) (code ?c)))

   (do-for-all-facts ((?sc course-score-contribution))
      (and (eq ?sc:student-id ?id)
           (eq ?sc:code ?c))
      (retract ?sc))

   (retract ?af))
   
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
   
   ;; Print warnings first
   (bind ?has-warnings FALSE)
   (do-for-all-facts ((?w warning))
      (eq ?w:student-id ?id)
      (if (not ?has-warnings)
         then
         (printout t crlf "ADVISOR NOTES:" crlf)
         (bind ?has-warnings TRUE))
      (printout t "  * " ?w:message crlf))
   (if ?has-warnings
      then
      (printout t crlf "==========================================" crlf))
   
   (bind ?total 0)
   (bind ?found FALSE)

      ;; If Summer term: print summer-offered eligible courses first (priority)
   (if (= ?sem 3)
   then
   (progn
      ;; EASY summer-priority first
      (do-for-all-facts ((?e eligible) (?co course) (?sp summer-priority))
         (and (eq ?e:student-id ?id)
              (eq ?e:code ?co:code)
              (eq ?sp:student-id ?id)
              (eq ?sp:code ?co:code)
              (eq ?co:difficulty easy))
         (if (<= (+ ?total ?co:credits) ?max)
            then
            (printout t "  " ?co:code " - " ?co:name " (" ?co:credits " cr | " ?co:difficulty ")" crlf)
            (bind ?total (+ ?total ?co:credits))
            (bind ?found TRUE)))

      ;; MEDIUM summer-priority first
      (do-for-all-facts ((?e eligible) (?co course) (?sp summer-priority))
         (and (eq ?e:student-id ?id)
              (eq ?e:code ?co:code)
              (eq ?sp:student-id ?id)
              (eq ?sp:code ?co:code)
              (eq ?co:difficulty medium))
         (if (<= (+ ?total ?co:credits) ?max)
            then
            (printout t "  " ?co:code " - " ?co:name " (" ?co:credits " cr | " ?co:difficulty ")" crlf)
            (bind ?total (+ ?total ?co:credits))
            (bind ?found TRUE)))

      ;; HARD summer-priority first
      (do-for-all-facts ((?e eligible) (?co course) (?sp summer-priority))
         (and (eq ?e:student-id ?id)
              (eq ?e:code ?co:code)
              (eq ?sp:student-id ?id)
              (eq ?sp:code ?co:code)
              (eq ?co:difficulty hard))
         (if (<= (+ ?total ?co:credits) ?max)
            then
            (printout t "  " ?co:code " - " ?co:name " (" ?co:credits " cr | " ?co:difficulty ")" crlf)
            (bind ?total (+ ?total ?co:credits))
            (bind ?found TRUE)))))


   ;; For rest of the terms (NOT SUMMER)
   ;; Easy courses, not summer
   (do-for-all-facts ((?e eligible) (?co course))
      (and (eq ?e:student-id ?id)
           (eq ?e:code ?co:code)
           (eq ?co:difficulty easy)
            (not (any-factp ((?sp summer-priority))
               (and (eq ?sp:student-id ?id) (eq ?sp:code ?co:code)))))
      (if (<= (+ ?total ?co:credits) ?max)
         then
         (printout t "  " ?co:code " - " ?co:name " (" ?co:credits " cr | " ?co:difficulty ")" crlf)
         (bind ?total (+ ?total ?co:credits))
         (bind ?found TRUE)))
   
   ;; Then medium courses, whe not summer
   (do-for-all-facts ((?e eligible) (?co course))
      (and (eq ?e:student-id ?id)
           (eq ?e:code ?co:code)
           (eq ?co:difficulty medium)
            (not (any-factp ((?sp summer-priority))
               (and (eq ?sp:student-id ?id) (eq ?sp:code ?co:code)))))
      (if (<= (+ ?total ?co:credits) ?max)
         then
         (printout t "  " ?co:code " - " ?co:name " (" ?co:credits " cr | " ?co:difficulty ")" crlf)
         (bind ?total (+ ?total ?co:credits))
         (bind ?found TRUE)))
   
   ;; Finally hard courses, when not summer
   (do-for-all-facts ((?e eligible) (?co course))
      (and (eq ?e:student-id ?id)
           (eq ?e:code ?co:code)
           (eq ?co:difficulty hard)
            (not (any-factp ((?sp summer-priority))
               (and (eq ?sp:student-id ?id) (eq ?sp:code ?co:code)))))
      (if (<= (+ ?total ?co:credits) ?max)
         then
         (printout t "  " ?co:code " - " ?co:name " (" ?co:credits " cr | " ?co:difficulty ")" crlf)
         (bind ?total (+ ?total ?co:credits))
         (bind ?found TRUE)))
   
   (if (not ?found)
      then
      (printout t "  No eligible courses match your criteria." crlf)
      (printout t "  Try increasing your workload preference or credit count." crlf)
      else
      (printout t "------------------------------------------" crlf)
      (printout t "  Total recommended : " ?total " credits"  crlf))
      (printout t "==========================================" crlf)
      (printout t "  RECOMMENDATION CONFIDENCE SCORES (D2)   " crlf)
      (printout t "  (Higher CF = stronger recommendation)   " crlf)
      (printout t "==========================================" crlf)

      ;; Print each eligible course's recommendation-confidence with its CF
      (do-for-all-facts ((?rc recommendation-confidence) (?co course))
         (and (eq ?rc:student-id ?id)
            (eq ?rc:code ?co:code))
         (printout t "  CF " (get-cf ?rc) " | " ?co:code 
                  " - " ?co:name 
                  " (" ?co:difficulty ")" crlf))

                        (printout t crlf
         "==========================================" crlf)
      (printout t "  FUZZY RECOMMENDATION SCORES (TODO 3)    " crlf)
      (printout t "==========================================" crlf)

      (do-for-all-facts ((?fr fuzzy-course-recommendation) (?co course))
         (and (eq ?fr:student-id ?id)
              (eq ?fr:code ?co:code))
         (printout t "  " ?fr:label
                  " | score " ?fr:score
                  " | " ?co:code
                  " - " ?co:name
                  crlf))

      (printout t "==========================================" crlf)
      (printout t "  Advising complete. Good luck!"             crlf)
      (printout t "==========================================" crlf)
      (retract ?p))

;;; ============================================================
;;; D2 TODO 2 — CERTAINTY FACTOR RULES
;;; These rules fire at salience 5 — after blocking (20) and
;;; eligibility marking (0), but before finish-eligibility (-10).
;;; They layer a confidence computation on top of the crisp
;;; eligibility decisions produced in D1.
;;;
;;; CF formulas used (from Lab 6):
;;;   Propagation:   CF_output = CF_fact × CF_rule
;;;   Combination:   CF_combined = max(CF_1, CF_2, ...)
;;; ============================================================

;;; ---- HELPER DEFFUNCTION ----

(deffunction count-completed-in-track (?id ?track)
   "Count how many courses the student has completed in a given track"
   (bind ?n 0)
   (do-for-all-facts ((?c completed) (?tc track-course))
      (and (eq ?c:student-id ?id)
           (eq ?c:code ?tc:code)
           (eq ?tc:track ?track))
      (bind ?n (+ ?n 1)))
   ?n)


;;; ---- GPA TIER CLASSIFIERS (Rules 1-3) ----

(defrule classify-gpa-strong
   "Classify students with GPA >= 3.5 as strong performers"
   (declare (salience 5) (CF 0.90))
   (phase (current compute-eligibility))
   (active-student ?id)
   (student (id ?id) (gpa ?g))
   (test (>= ?g 3.5))
   =>
   (assert (gpa-performance-tier (student-id ?id) (tier strong))))

(defrule classify-gpa-average
   "Classify students with 2.7 <= GPA < 3.5 as average performers"
   (declare (salience 5) (CF 0.80))
   (phase (current compute-eligibility))
   (active-student ?id)
   (student (id ?id) (gpa ?g))
   (test (and (>= ?g 2.7) (< ?g 3.5)))
   =>
   (assert (gpa-performance-tier (student-id ?id) (tier average))))

(defrule classify-gpa-struggling
   "Classify students with GPA < 2.7 as struggling performers"
   (declare (salience 5) (CF 0.75))
   (phase (current compute-eligibility))
   (active-student ?id)
   (student (id ?id) (gpa ?g))
   (test (< ?g 2.7))
   =>
   (assert (gpa-performance-tier (student-id ?id) (tier struggling))))


;;; ---- TRACK INTEREST INFERENCE (Rules 4-5) ----

(defrule infer-track-interest-two-courses
   "If student has completed at least 2 courses in a track, infer interest"
   (declare (salience 5) (CF 0.70))
   (phase (current compute-eligibility))
   (active-student ?id)
   (track-course (track ?t))
   (test (>= (count-completed-in-track ?id ?t) 2))
   =>
   (assert (track-interest (student-id ?id) (track ?t))))

(defrule infer-track-interest-three-plus
   "Strengthen track interest when student has 3+ courses in a track"
   (declare (salience 5) (CF 0.90))
   (phase (current compute-eligibility))
   (active-student ?id)
   (track-course (track ?t))
   (test (>= (count-completed-in-track ?id ?t) 3))
   =>
   (assert (track-interest (student-id ?id) (track ?t))))


;;; ---- PASS LIKELIHOOD RULES (Rules 6-8) ----
;;; These use CF propagation: the difficulty-pass-rate fact's CF
;;; multiplies through the rule CF to produce the output CF.

(defrule pass-likelihood-strong-gpa
   "Strong-GPA students have high pass confidence on eligible courses"
   (declare (salience 5) (CF 0.85))
   (phase (current compute-eligibility))
   (eligible (student-id ?id) (code ?c))
   (course (code ?c) (difficulty ?d))
   (difficulty-pass-rate (difficulty ?d))
   (gpa-performance-tier (student-id ?id) (tier strong))
   =>
   (assert (pass-likelihood (student-id ?id) (code ?c))))

(defrule pass-likelihood-average-gpa
   "Average-GPA students have moderate pass confidence"
   (declare (salience 5) (CF 0.65))
   (phase (current compute-eligibility))
   (eligible (student-id ?id) (code ?c))
   (course (code ?c) (difficulty ?d))
   (difficulty-pass-rate (difficulty ?d))
   (gpa-performance-tier (student-id ?id) (tier average))
   =>
   (assert (pass-likelihood (student-id ?id) (code ?c))))


(defrule pass-likelihood-struggling-gpa
   "Struggling students have lower pass confidence across all difficulties"
   (declare (salience 5) (CF 0.40))
   (phase (current compute-eligibility))
   (eligible (student-id ?id) (code ?c))
   (course (code ?c) (difficulty ?d))
   (difficulty-pass-rate (difficulty ?d))
   (gpa-performance-tier (student-id ?id) (tier struggling))
   =>
   (assert (pass-likelihood (student-id ?id) (code ?c))))



;;; ---- TRACK MATCH RECOMMENDATION (Rules 9-10) ----

(defrule recommend-course-track-match
   "Recommend courses that match the student's inferred track interest"
   (declare (salience 5) (CF 0.95))
   (phase (current compute-eligibility))
   (eligible (student-id ?id) (code ?c))
   (track-course (track ?t) (code ?c))
   (track-interest (student-id ?id) (track ?t))
   =>
   (assert (track-bonus (student-id ?id) (code ?c))))

(defrule recommend-core-course-priority
   "Core courses get a recommendation boost regardless of track"
   (declare (salience 5) (CF 0.75))
   (phase (current compute-eligibility))
   (eligible (student-id ?id) (code ?c))
   (course (code ?c) (category core))
   =>
   (assert (core-bonus (student-id ?id) (code ?c))))

;;; ---- AGGREGATOR RULE (Rule 11) ----
;;; Combines pass-likelihood, track-bonus, and core-bonus into a final
;;; recommendation-confidence using explicit max combination.
;;;
;;; This rule fires at salience 3 — after Rules 6-10 (salience 5) have
;;; produced their intermediate facts. It uses (max ...) to compute the
;;; combined CF, matching the formula from Lab 6 slide 13:
;;;   CF_combined = max(CF_1, CF_2, ...)
;;;
;;; The CF on this rule is 1.0 because we are not adding any new
;;; uncertainty — we are just selecting the strongest existing signal.

(defrule aggregate-recommendation-confidence
   "Combine all CF signals for an eligible course via max"
   (declare (salience 3) (CF 1.0))
   (phase (current compute-eligibility))
   (eligible (student-id ?id) (code ?c))
   =>
   (bind ?best 0.0)
   ;; Check pass-likelihood
   (do-for-all-facts ((?pl pass-likelihood))
      (and (eq ?pl:student-id ?id) (eq ?pl:code ?c))
      (if (> (get-cf ?pl) ?best) then (bind ?best (get-cf ?pl))))
   ;; Check track-bonus
   (do-for-all-facts ((?tb track-bonus))
      (and (eq ?tb:student-id ?id) (eq ?tb:code ?c))
      (if (> (get-cf ?tb) ?best) then (bind ?best (get-cf ?tb))))
   ;; Check core-bonus
   (do-for-all-facts ((?cb core-bonus))
      (and (eq ?cb:student-id ?id) (eq ?cb:code ?c))
      (if (> (get-cf ?cb) ?best) then (bind ?best (get-cf ?cb))))
   ;; Only assert if at least one signal fired
   (if (> ?best 0.0) then
      (assert (recommendation-confidence (student-id ?id) (code ?c)) CF ?best)))

