;;; ============================================================
;;; factbase.clp
;;; Academic Course Advisor — Fact Base
;;; Based on: Concordia University BCompSc Degree Requirements
;;; ============================================================


;;; ============================================================
;;; TEMPLATES
;;; ============================================================

(deftemplate phase
   "Tracks the current phase of the advising session"
   (slot current))

(deftemplate student
   "Represents a student record in the system"
   (slot id)
   (slot year)
   (slot gpa))

(deftemplate completed
   "Records a course a student has already completed"
   (slot student-id)
   (slot code))

(deftemplate course
   "Represents a course in the Concordia CS catalog"
   (slot code)
   (slot credits)
   (slot level)
   (slot category)
   (slot difficulty)   ; easy | medium | hard
   (slot semester)     ; fall | winter | summer | both
   (slot name))

(deftemplate prerequisite
   "Represents a prerequisite relationship between two courses"
   (slot course)
   (slot required))

(deftemplate gpa-requirement
   "Represents a minimum GPA requirement to enroll in a course"
   (slot course)
   (slot minimum))

(deftemplate eligible
   "Records that a student is eligible to enroll in a course"
   (slot student-id)
   (slot code))

(deftemplate blocked
   "Records that a student is blocked from enrolling in a course"
   (slot student-id)
   (slot code)
   (slot reason))

(deftemplate session
   "Stores the active advising session data for a student"
   (slot student-id)
   (slot semester)
   (slot desired-credits)
   (slot workload))    ; light | moderate | heavy


(deftemplate warning
   "Records advisory warnings and suggestions for the student"
   (slot student-id)
   (slot message))

(deftemplate summer-priority
   (slot student-id)
   (slot code))


;;; ============================================================
;;; COURSE CATALOG
;;; Credits, difficulty, and semester availability per Concordia
;;; ============================================================

(deffacts course-catalog

   ;; ---- CORE COURSES ----
   (course (code COMP228) (credits 3) (level 2) (category core)          (difficulty easy)   (semester both)   (name "System Hardware"))
   (course (code COMP232) (credits 3) (level 2) (category core)          (difficulty medium) (semester both)   (name "Mathematics for Computer Science"))
   (course (code COMP233) (credits 3) (level 2) (category core)          (difficulty medium) (semester both)   (name "Probability and Statistics for CS"))
   (course (code COMP248) (credits 3) (level 2) (category core)          (difficulty easy)   (semester both)   (name "Object-Oriented Programming I"))
   (course (code COMP249) (credits 3) (level 2) (category core)          (difficulty medium) (semester both)   (name "Object-Oriented Programming II"))
   (course (code COMP335) (credits 3) (level 3) (category core)          (difficulty hard)   (semester fall)   (name "Introduction to Theoretical Computer Science"))
   (course (code COMP346) (credits 4) (level 3) (category core)          (difficulty hard)   (semester both)   (name "Operating Systems"))
   (course (code COMP352) (credits 3) (level 3) (category core)          (difficulty hard)   (semester both)   (name "Data Structures and Algorithms"))
   (course (code COMP348) (credits 3) (level 3) (category core)          (difficulty medium) (semester both)   (name "Principles of Programming Languages"))
   (course (code COMP354) (credits 4) (level 3) (category core)          (difficulty medium) (semester both)   (name "Introduction to Software Engineering"))

   ;; ---- COMPLEMENTARY CORE ----
   (course (code ENCS282) (credits 3) (level 2) (category complementary) (difficulty easy)   (semester both)   (name "Technical Writing and Communication"))
   (course (code ENCS393) (credits 3) (level 3) (category complementary) (difficulty medium) (semester both)   (name "Social and Ethical Dimensions of ICT"))

   ;; ---- CS ELECTIVES — AI GROUP ----
   (course (code COMP425) (credits 4) (level 4) (category cs-elective)   (difficulty hard)   (semester both)   (name "Computer Vision"))
   (course (code COMP432) (credits 4) (level 4) (category cs-elective)   (difficulty hard)   (semester winter) (name "Machine Learning"))
   (course (code COMP472) (credits 4) (level 4) (category cs-elective)   (difficulty hard)   (semester both)   (name "Artificial Intelligence"))
   (course (code COMP473) (credits 4) (level 4) (category cs-elective)   (difficulty hard)   (semester summer)   (name "Pattern Recognition"))
   (course (code COMP474) (credits 4) (level 4) (category cs-elective)   (difficulty hard)   (semester both)   (name "Intelligent Systems"))
   (course (code COMP479) (credits 4) (level 4) (category cs-elective)   (difficulty medium) (semester fall)   (name "Information Retrieval and Web Search"))

   ;; ---- CS ELECTIVES — GAMES GROUP ----
   (course (code COMP345) (credits 4) (level 3) (category cs-elective)   (difficulty medium) (semester both)   (name "Advanced Program Design with C++"))
   (course (code COMP371) (credits 4) (level 3) (category cs-elective)   (difficulty medium) (semester both)   (name "Computer Graphics"))
   (course (code COMP376) (credits 4) (level 3) (category cs-elective)   (difficulty medium) (semester summer)   (name "Introduction to Game Development"))
   (course (code COMP476) (credits 4) (level 4) (category cs-elective)   (difficulty hard)   (semester winter) (name "Advanced Game Development"))
   (course (code COMP477) (credits 4) (level 4) (category cs-elective)   (difficulty hard)   (semester fall)   (name "Animation for Computer Games"))

   ;; ---- CS ELECTIVES — DATA / WEB ----
   (course (code COMP333) (credits 4) (level 3) (category cs-elective)   (difficulty medium) (semester both)   (name "Data Analytics"))
   (course (code COMP353) (credits 4) (level 3) (category cs-elective)   (difficulty medium) (semester both)   (name "Databases"))
   (course (code COMP445) (credits 4) (level 4) (category cs-elective)   (difficulty hard)   (semester both)   (name "Data Communication and Computer Networks"))
   (course (code SOEN287) (credits 3) (level 2) (category cs-elective)   (difficulty easy)   (semester both)   (name "Web Programming"))
   (course (code SOEN321) (credits 3) (level 3) (category cs-elective)   (difficulty medium) (semester winter) (name "Information Systems Security"))
   (course (code SOEN357) (credits 3) (level 3) (category cs-elective)   (difficulty easy)   (semester both)   (name "User Interface Design"))

   ;; ---- MATH ELECTIVES ----
   (course (code COMP339) (credits 3) (level 3) (category math-elective) (difficulty hard)   (semester fall)   (name "Combinatorics"))
   (course (code COMP361) (credits 3) (level 3) (category math-elective) (difficulty medium) (semester both)   (name "Elementary Numerical Methods"))
   (course (code MATH251) (credits 3) (level 2) (category math-elective) (difficulty medium) (semester both)   (name "Linear Algebra I"))
   (course (code MATH252) (credits 3) (level 3) (category math-elective) (difficulty hard)   (semester both)   (name "Linear Algebra II"))
)


;;; ============================================================
;;; PREREQUISITES
;;; ============================================================

(deffacts prereq-catalog

   (prerequisite (course COMP249) (required COMP248))

   (prerequisite (course COMP346) (required COMP249))
   (prerequisite (course COMP352) (required COMP249))
   (prerequisite (course COMP352) (required COMP232))
   (prerequisite (course COMP354) (required COMP249))
   (prerequisite (course COMP345) (required COMP249))
   (prerequisite (course COMP333) (required COMP249))
   (prerequisite (course COMP353) (required COMP249))
   (prerequisite (course COMP371) (required COMP249))
   (prerequisite (course COMP376) (required COMP249))
   (prerequisite (course SOEN321) (required COMP249))
   (prerequisite (course SOEN357) (required COMP249))
   (prerequisite (course ENCS393) (required COMP249))

   (prerequisite (course COMP348) (required COMP249))
   (prerequisite (course COMP348) (required COMP352))

   (prerequisite (course COMP335) (required COMP232))
   (prerequisite (course COMP233) (required COMP232))

   (prerequisite (course COMP472) (required COMP352))
   (prerequisite (course COMP473) (required COMP352))
   (prerequisite (course COMP474) (required COMP352))
   (prerequisite (course COMP425) (required COMP352))
   (prerequisite (course COMP432) (required COMP352))
   (prerequisite (course COMP479) (required COMP352))
   (prerequisite (course COMP445) (required COMP352))
   (prerequisite (course COMP476) (required COMP376))
   (prerequisite (course COMP477) (required COMP371))

   (prerequisite (course MATH252) (required MATH251))
)


;;; ============================================================
;;; GPA REQUIREMENTS
;;; ============================================================

(deffacts gpa-requirements
   (gpa-requirement (course COMP376) (minimum 3.0))
   (gpa-requirement (course COMP472) (minimum 2.7))
   (gpa-requirement (course COMP474) (minimum 2.7))
   (gpa-requirement (course COMP432) (minimum 2.7))
)


;;; ============================================================
;;; STUDENT DATABASE
;;; ============================================================

(deffacts student-database

   ;; S1001 — Year 1, strong GPA, just started
   (student (id S1001) (year 1) (gpa 3.5))
   (completed (student-id S1001) (code COMP248))

   ;; S1002 — Year 2, average GPA, finished 200-level core
   (student (id S1002) (year 2) (gpa 2.5))
   (completed (student-id S1002) (code COMP248))
   (completed (student-id S1002) (code COMP249))
   (completed (student-id S1002) (code COMP232))
   (completed (student-id S1002) (code COMP233))
   (completed (student-id S1002) (code COMP228))
   (completed (student-id S1002) (code ENCS282))
   (completed (student-id S1002) (code MATH251))

   ;; S1003 — Year 3, good GPA, deep into core
   (student (id S1003) (year 3) (gpa 3.2))
   (completed (student-id S1003) (code COMP248))
   (completed (student-id S1003) (code COMP249))
   (completed (student-id S1003) (code COMP232))
   (completed (student-id S1003) (code COMP233))
   (completed (student-id S1003) (code COMP228))
   (completed (student-id S1003) (code COMP352))
   (completed (student-id S1003) (code COMP346))
   (completed (student-id S1003) (code COMP335))
   (completed (student-id S1003) (code ENCS282))
   (completed (student-id S1003) (code MATH251))

   ;; S1004 — Year 4, high GPA, nearly done
   (student (id S1004) (year 4) (gpa 3.8))
   (completed (student-id S1004) (code COMP248))
   (completed (student-id S1004) (code COMP249))
   (completed (student-id S1004) (code COMP232))
   (completed (student-id S1004) (code COMP233))
   (completed (student-id S1004) (code COMP228))
   (completed (student-id S1004) (code COMP352))
   (completed (student-id S1004) (code COMP354))
   (completed (student-id S1004) (code COMP346))
   (completed (student-id S1004) (code COMP348))
   (completed (student-id S1004) (code COMP335))
   (completed (student-id S1004) (code ENCS282))
   (completed (student-id S1004) (code ENCS393))
   (completed (student-id S1004) (code COMP371))
   (completed (student-id S1004) (code MATH251))
   (completed (student-id S1004) (code MATH252))
)


;;; ============================================================
;;; INITIAL STATE
;;; ============================================================

(deffacts initial-state
   (phase (current get-student-id)))
