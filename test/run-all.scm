;;; ============================================================================
;;; run-all.scm — loads every source file and every suite, then runs them.
;;; ============================================================================
;;;
;;; Run this from the PROJECT ROOT, because the paths below are relative to the
;;; working directory, not to this file:
;;;
;;;     guile -l test/run-all.scm
;;;     chez  --script test/run-all.scm
;;;     mit-scheme --quiet < test/run-all.scm
;;;
;;; Files are loaded in dependency order.  A file may depend only on files
;;; loaded before it:
;;;
;;;     book <- catalog <- search <- pipeline <- tree <- index <- sort <- io <- main
;;; ============================================================================


;;; --- sources ---------------------------------------------------------------
(load "src/book.scm")
;; (load "src/catalog.scm")     ; Iteration 2
;; (load "src/search.scm")      ; Iteration 3
;; (load "src/pipeline.scm")    ; Iteration 4
;; (load "src/tree.scm")        ; Iteration 5
;; (load "src/index.scm")       ; Iteration 6
;; (load "src/sort.scm")        ; Iteration 8
;; (load "src/io.scm")          ; Iteration 7
;; (load "src/main.scm")        ; Iteration 8

;;; --- test harness and suites -----------------------------------------------
(load "test/test-framework.scm")
(load "test/test-book.scm")
;; (load "test/test-catalog.scm")
;; (load "test/test-search.scm")
;; (load "test/test-pipeline.scm")
;; (load "test/test-tree.scm")
;; (load "test/test-index.scm")
;; (load "test/test-io.scm")
;; (load "test/test-main.scm")


;; run-all-suites : -> unspecified
;; Runs every implemented suite and prints the total number of failures.
;; Each run-suite call returns its failure count, so the total is a plain sum —
;; no mutable counter is involved.
(define (run-all-suites)
  (let ((failures
         (+ (run-suite "Iteration 1 — book" (book-tests))
            ;; (run-suite "Iteration 2 — catalog"  (catalog-tests))
            ;; (run-suite "Iteration 3 — search"   (search-tests))
            ;; (run-suite "Iteration 4 — pipeline" (pipeline-tests))
            ;; (run-suite "Iteration 5 — tree"     (tree-tests))
            ;; (run-suite "Iteration 6 — index"    (index-tests))
            ;; (run-suite "Iteration 7 — io"       (io-tests))
            ;; (run-suite "Iteration 8 — system"   (system-tests))
            0)))
    (display "TOTAL FAILURES: ") (display failures) (newline)
    failures))

(run-all-suites)
