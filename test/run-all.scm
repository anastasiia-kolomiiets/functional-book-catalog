;;; run-all.scm — загружає всі файли джерела та всі набори тестів, а потім запускає їх.
;;;
;;; Файли завантажуються в порядку залежностей. Файл може залежати лише від файлів,
;;; завантажених раніше:
;;;
;;;     book <- catalog <- search <- pipeline <- tree <- index <- sort <- io <- main

(load "src/book.scm")           ; Ітерація 1
(load "src/catalog.scm")        ; Ітерація 2
(load "src/search.scm")         ; Ітерація 3
(load "src/pipeline.scm")       ; Ітерація 4
(load "src/tree.scm")           ; Ітерація 5
;; (load "src/index.scm")       ; Ітерація 6
;; (load "src/sort.scm")        ; Ітерація 8
;; (load "src/io.scm")          ; Ітерація 7
;; (load "src/main.scm")        ; Ітерація 8

(load "test/test-framework.scm")
(load "test/test-book.scm")
(load "test/test-catalog.scm")
(load "test/test-search.scm")
(load "test/test-pipeline.scm")
(load "test/test-tree.scm")
;; (load "test/test-index.scm")
;; (load "test/test-io.scm")
;; (load "test/test-main.scm")


;; run-all-suites : -> unspecified
;; Запускає всі реалізовані набори тестів і виводить загальну кількість помилок.
(define (run-all-suites)
  (let ((failures
         (+ (run-suite "Ітерація 1 — book"    (book-tests))
            (run-suite "Ітерація 2 — catalog" (catalog-tests))
            (run-suite "Ітерація 3 — search"  (search-tests))
            (run-suite "Ітерація 4 — pipeline" (pipeline-tests))
            (run-suite "Ітерація 5 — tree"     (tree-tests))
            ;; (run-suite "Ітерація 6 — index"    (index-tests))
            ;; (run-suite "Ітерація 7 — io"       (io-tests))
            ;; (run-suite "Ітерація 8 — system"   (system-tests))
            0)))
    (display "TOTAL FAILURES: ") (display failures) (newline)
    failures))

(run-all-suites)
