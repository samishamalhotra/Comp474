;;;============================================
;;; Complete Test File - Standalone
;;; Includes factbase + testing
;;;============================================

;;; Clear everything
(clear)

;;;--------------------------------------------
;;; TEMPLATES
;;;--------------------------------------------

(deftemplate course
  (slot code (type SYMBOL))
  (slot name (type STRING))
  (slot credits (type NUMBER))
  (slot difficulty (type SYMBOL))
  (slot semester (type SYMBOL))
)

(deftemplate prerequisite
  (slot course (type SYMBOL))
  (slot requires (type SYMBOL))
)

(deftemplate student-status
  (slot type (type SYMBOL))
  (slot max-courses (type INTEGER))
  (slot min-courses (type INTEGER))
)

;;;--------------------------------------------
;;; FACTS
;;;--------------------------------------------

(deffacts course-catalog
  (course (code COMP-228) (name "System Hardware") (credits 3) (difficulty medium) (semester both))
  (course (code COMP-232) (name "Mathematics for Computer Science") (credits 3) (difficulty medium) (semester both))
  (course (code COMP-233) (name "Probability and Statistics for Computer Science") (credits 3) (difficulty medium) (semester both))
  (course (code COMP-248) (name "Object-Oriented Programming I") (credits 3.5) (difficulty medium) (semester both))
  (course (code COMP-249) (name "Object-Oriented Programming II") (credits 3.5) (difficulty medium) (semester both))
  (course (code COMP-335) (name "Introduction to Theoretical Computer Science") (credits 3) (difficulty hard) (semester fall))
  (course (code COMP-346) (name "Operating Systems") (credits 4) (difficulty hard) (semester both))
  (course (code COMP-348) (name "Principles of Programming Languages") (credits 3) (difficulty medium) (semester both))
  (course (code COMP-352) (name "Data Structures and Algorithms") (credits 3) (difficulty hard) (semester both))
  (course (code COMP-354) (name "Introduction to Software Engineering") (credits 4) (difficulty medium) (semester both))
  (course (code COMP-353) (name "Databases") (credits 4) (difficulty medium) (semester both))
  (course (code SOEN-287) (name "Web Programming") (credits 3) (difficulty easy) (semester both))
)

(deffacts course-prerequisites
  (prerequisite (course COMP-233) (requires COMP-232))
  (prerequisite (course COMP-249) (requires COMP-248))
  (prerequisite (course COMP-335) (requires COMP-232))
  (prerequisite (course COMP-348) (requires COMP-248))
  (prerequisite (course COMP-352) (requires COMP-249))
  (prerequisite (course COMP-352) (requires COMP-232))
  (prerequisite (course COMP-346) (requires COMP-352))
  (prerequisite (course COMP-353) (requires COMP-249))
  (prerequisite (course SOEN-287) (requires COMP-248))
)

(deffacts student-workload
  (student-status (type full-time) (max-courses 5) (min-courses 4))
  (student-status (type part-time) (max-courses 2) (min-courses 1))
)

;;; Initialize facts
(reset)

;;;--------------------------------------------
;;; TEST OUTPUT
;;;--------------------------------------------

(printout t crlf)
(printout t "========================================" crlf)
(printout t "  FACTBASE TEST RESULTS" crlf)
(printout t "========================================" crlf)
(printout t crlf)

(printout t "=== ALL COURSES ===" crlf)
(printout t crlf)
(do-for-all-facts ((?c course)) TRUE
  (printout t ?c:code " - " ?c:name crlf)
  (printout t "  Credits: " ?c:credits crlf)
  (printout t "  Difficulty: " ?c:difficulty crlf)
  (printout t "  Semester: " ?c:semester crlf)
  (printout t crlf)
)

(printout t "=== PREREQUISITES ===" crlf)
(printout t crlf)
(do-for-all-facts ((?p prerequisite)) TRUE
  (printout t ?p:course " requires " ?p:requires crlf)
)

(printout t crlf)
(printout t "=== STUDENT WORKLOAD GUIDELINES ===" crlf)
(printout t crlf)
(do-for-all-facts ((?s student-status)) TRUE
  (printout t ?s:type " student:" crlf)
  (printout t "  Min courses: " ?s:min-courses crlf)
  (printout t "  Max courses: " ?s:max-courses crlf)
  (printout t crlf)
)

(printout t "=== SUMMARY ===" crlf)
(printout t "Total courses: " (length$ (find-all-facts ((?c course)) TRUE)) crlf)
(printout t "Total prerequisites: " (length$ (find-all-facts ((?p prerequisite)) TRUE)) crlf)
(printout t "Total student status facts: " (length$ (find-all-facts ((?s student-status)) TRUE)) crlf)
(printout t "TOTAL FACTS: " (+ 
  (length$ (find-all-facts ((?c course)) TRUE))
  (length$ (find-all-facts ((?p prerequisite)) TRUE))
  (length$ (find-all-facts ((?s student-status)) TRUE))
) crlf)
(printout t crlf)

(printout t "========================================" crlf)
(printout t "  TEST COMPLETE!" crlf)
(printout t "========================================" crlf)
(printout t crlf)
```

---

