;;; --- sources ---------------------------------------------------------------
(load "src/book.scm")

(define dune (make-book "Dune" "Frank Herbert" 1965 'sci-fi))

(book-title dune)                       ; => "Dune"
(book-year  dune)                       ; => 1965
(book? dune)                            ; => #t
(book? "Dune")                          ; => #f
(book? '())                             ; => #f

(define dune2 (book-with-genre dune 'classic))
(book-genre dune2)                      ; => classic
(book-genre dune)                       ; => sci-fi     <- unchanged: persistence
(book=? dune dune2)                     ; => #f

(display (book->string dune))
;; Dune — Frank Herbert (1965) [sci-fi]
