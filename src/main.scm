;;; --- sources ---------------------------------------------------------------
(load "src/book.scm")

(define dune (make-book "Dune" "Frank Herbert" 1965 'sci-fi))

(display (book-title dune)) (newline)             ; => "Dune"
(display (book-year  dune)) (newline)             ; => 1965
(display (book? dune)) (newline)                  ; => #t
(display (book? "Dune")) (newline)                ; => #f
(display (book? '())) (newline)                   ; => #f

(define dune2 (book-with-genre dune 'classic))
(display (book-genre dune2)) (newline)            ; => classic
(display (book-genre dune)) (newline)             ; => sci-fi     <- unchanged: persistence
(display (book=? dune dune2)) (newline)           ; => #f

(display (book->string dune)) (newline)
;; Dune — Frank Herbert (1965) [sci-fi]
(display (book->string dune2)) (newline)
;; Dune2 — Frank Herbert (1965) [classic]