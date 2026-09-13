;;; ============================================================================
;;; test-book.scm — tests for Iteration 1 (src/book.scm)
;;; ============================================================================
;;;
;;; A suite is a procedure returning a LIST of Results.  It builds its own
;;; fixtures, so it does not depend on any other suite having run first.
;;;
;;; Coverage required by the specification:
;;;   (a) ordinary case       — the four selectors, book=?, book->string
;;;   (b) empty case          — an empty-string field
;;;   (c) absent / negative   — book? rejecting every kind of non-book
;;;   (d) boundary            — year 0, negative (BCE) year, structural equality
;;;                             of two distinct objects
;;;
;;; NOTE ON THE ABSTRACTION BARRIER
;;; -------------------------------
;;; The book? cases below construct near-miss lists such as (list 'film "t" "a"
;;; 1 'g) directly.  This is not a barrier violation: testing that a predicate
;;; is TOTAL requires feeding it values that are not books, and those values can
;;; only be built literally.  No selector is ever applied to a non-book, and no
;;; car/cdr/list-ref is ever applied to a real book outside src/book.scm.
;;;
;;; Dependencies: src/book.scm, test/test-framework.scm
;;; ============================================================================

(define (book-tests)
  (let* ((dune      (make-book "Dune" "Frank Herbert" 1965 'sci-fi))
         (dune-copy (make-book "Dune" "Frank Herbert" 1965 'sci-fi))
         (empties   (make-book "" "" 0 'unknown))
         (ancient   (make-book "The Iliad" "Homer" -750 'epic)))
    (list

     ;; ---------------------------------------------------------------- (a)
     ;; The constructor/selector contract.
     (check "book-title returns the title"   "Dune"          (book-title  dune))
     (check "book-author returns the author" "Frank Herbert" (book-author dune))
     (check "book-year returns the year"     1965            (book-year   dune))
     (check "book-genre returns the genre"   'sci-fi         (book-genre  dune))

     ;; ---------------------------------------------------------------- (c)
     ;; book? accepts a book and is TOTAL on everything else: each of these
     ;; must return #f rather than raising an error.
     (check-true  "book? accepts a book"               (book? dune))
     (check-false "book? rejects a string"             (book? "Dune"))
     (check-false "book? rejects the empty list"       (book? '()))
     (check-false "book? rejects a number"             (book? 42))
     (check-false "book? rejects a boolean"            (book? #t))
     (check-false "book? rejects a symbol"             (book? 'book))
     (check-false "book? rejects an improper list"     (book? (cons 'book 3)))
     (check-false "book? rejects a short list"         (book? (list 'book "t" "a")))
     (check-false "book? rejects a long list"
                  (book? (list 'book "t" "a" 1 'g 'extra)))
     (check-false "book? rejects a wrong tag"
                  (book? (list 'film "t" "a" 1 'g)))
     (check-false "book? rejects a non-string title"
                  (book? (list 'book 7 "a" 1 'g)))
     (check-false "book? rejects a non-integer year"
                  (book? (list 'book "t" "a" "1965" 'g)))
     (check-false "book? rejects a non-symbol genre"
                  (book? (list 'book "t" "a" 1 "g")))

     ;; ---------------------------------------------------------------- (d)
     ;; book=? is structural, not identity-based: two separately constructed
     ;; books with equal fields must compare equal.
     (check-true  "book=? is reflexive"            (book=? dune dune))
     (check-true  "book=? compares structurally"   (book=? dune dune-copy))
     (check-true  "book=? is symmetric"            (book=? dune-copy dune))
     (check-false "book=? differs on title"
                  (book=? dune (make-book "Done" "Frank Herbert" 1965 'sci-fi)))
     (check-false "book=? differs on author"
                  (book=? dune (make-book "Dune" "F. Herbert" 1965 'sci-fi)))
     (check-false "book=? differs on year"
                  (book=? dune (make-book "Dune" "Frank Herbert" 1966 'sci-fi)))
     (check-false "book=? differs on genre"
                  (book=? dune (make-book "Dune" "Frank Herbert" 1965 'classic)))

     ;; ---------------------------------------------------------------- (b)
     ;; Empty and extreme field values are ordinary data, not special cases.
     (check "empty title round-trips"   ""        (book-title empties))
     (check "empty author round-trips"  ""        (book-author empties))
     (check "year zero round-trips"     0         (book-year  empties))
     (check-true "a book with empty fields is still a book" (book? empties))
     (check "a negative year round-trips" -750    (book-year ancient))

     ;; ----------------------------------------------------------------
     ;; Persistent update: a new book is returned and the original is intact.
     (check "book-with-genre sets the new genre"
            'classic (book-genre (book-with-genre dune 'classic)))
     (check "book-with-genre leaves the original unchanged"
            'sci-fi  (book-genre dune))
     (check "book-with-genre preserves the other fields"
            "Frank Herbert" (book-author (book-with-genre dune 'classic)))
     (check "book-with-year sets the new year"
            1966 (book-year (book-with-year dune 1966)))
     (check "book-with-year leaves the original unchanged"
            1965 (book-year dune))
     (check-true "an updated book is still a book"
                 (book? (book-with-year dune 1966)))
     (check-false "an updated book is not equal to the original"
                  (book=? dune (book-with-year dune 1966)))

     ;; ----------------------------------------------------------------
     ;; Rendering includes all four fields.
     (check "book->string renders every field"
            "Dune — Frank Herbert (1965) [sci-fi]"
            (book->string dune))
     (check "book->string handles a negative year"
            "The Iliad — Homer (-750) [epic]"
            (book->string ancient)))))
