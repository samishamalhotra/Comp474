;;;============================================
;;; COMP 474 - Academic Course Advisor
;;; FACTBASE - Course Information
;;;============================================


;;;--------------------------------------------
;;; TEMPLATES - Define the structure of facts
;;;--------------------------------------------

;;; Course information template
(deftemplate course
  (slot code (type SYMBOL))           ; Course code (e.g., COMP-248)
  (slot name (type STRING))           ; Course name
  (slot credits (type NUMBER))        ; Credits
  (slot difficulty (type SYMBOL))     ; easy, medium, hard
  (slot semester (type SYMBOL))       ; fall, winter, both
)

;;; Prerequisite relationship template
(deftemplate prerequisite
  (slot course (type SYMBOL))         ; Course that has prerequisite
  (slot requires (type SYMBOL))       ; Required prerequisite course
)

;;; Student status template
(deftemplate student-status
  (slot type (type SYMBOL))           ; full-time, part-time
  (slot max-courses (type INTEGER))   ; Maximum courses per semester
  (slot min-courses (type INTEGER))   ; Minimum courses per semester
)


;;;--------------------------------------------
;;; FACTS - BCompSc Core Courses (10 mandatory)
;;;--------------------------------------------

(deffacts course-catalog
  
  ;;; First Year Core
  (course
    (code COMP-228)
    (name "System Hardware")
    (credits 3)
    (difficulty medium)
    (semester both)
  )
  
  (course
    (code COMP-232)
    (name "Mathematics for Computer Science")
    (credits 3)
    (difficulty medium)
    (semester both)
  )
  
  (course
    (code COMP-233)
    (name "Probability and Statistics for Computer Science")
    (credits 3)
    (difficulty medium)
    (semester both)
  )
  
  (course
    (code COMP-248)
    (name "Object-Oriented Programming I")
    (credits 3.5)
    (difficulty medium)
    (semester both)
  )
  
  (course
    (code COMP-249)
    (name "Object-Oriented Programming II")
    (credits 3.5)
    (difficulty medium)
    (semester both)
  )
  
  ;;; Second/Third Year Core
  (course
    (code COMP-335)
    (name "Introduction to Theoretical Computer Science")
    (credits 3)
    (difficulty hard)
    (semester fall)
  )
  
  (course
    (code COMP-346)
    (name "Operating Systems")
    (credits 4)
    (difficulty hard)
    (semester both)
  )
  
  (course
    (code COMP-348)
    (name "Principles of Programming Languages")
    (credits 3)
    (difficulty medium)
    (semester both)
  )
  
  (course
    (code COMP-352)
    (name "Data Structures and Algorithms")
    (credits 3)
    (difficulty hard)
    (semester both)
  )
  
  (course
    (code COMP-354)
    (name "Introduction to Software Engineering")
    (credits 4)
    (difficulty medium)
    (semester both)
  )
  
  ;;; Popular Electives (to reach 12 courses)
  (course
    (code COMP-353)
    (name "Databases")
    (credits 4)
    (difficulty medium)
    (semester both)
  )
  
  (course
    (code SOEN-287)
    (name "Web Programming")
    (credits 3)
    (difficulty easy)
    (semester both)
  )
  
)

;;;--------------------------------------------
;;; FACTS - Prerequisites
;;;--------------------------------------------

(deffacts course-prerequisites
  
  (prerequisite
    (course COMP-233)
    (requires COMP-232)
  )
  
  (prerequisite
    (course COMP-249)
    (requires COMP-248)
  )
  
  (prerequisite
    (course COMP-335)
    (requires COMP-232)
  )
  
  (prerequisite
    (course COMP-348)
    (requires COMP-248)
  )
  
  (prerequisite
    (course COMP-352)
    (requires COMP-249)
  )
  
  (prerequisite
    (course COMP-352)
    (requires COMP-232)
  )
  
  (prerequisite
    (course COMP-346)
    (requires COMP-352)
  )
  
  (prerequisite
    (course COMP-353)
    (requires COMP-249)
  )
  
  (prerequisite
    (course SOEN-287)
    (requires COMP-248)
  )
  
)

;;;--------------------------------------------
;;; FACTS - Student Status
;;;--------------------------------------------

(deffacts student-workload
  
  (student-status
    (type full-time)
    (max-courses 5)
    (min-courses 4)
  )
  
  (student-status
    (type part-time)
    (max-courses 2)
    (min-courses 1)
  )
  
)