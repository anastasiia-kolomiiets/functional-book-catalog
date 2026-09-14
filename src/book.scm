;;; ============================================================================
;;; book.scm — Iteration 1: Object Representation (Data Abstraction)
;;; ============================================================================

;;; ----------------------------------------------------------------------------
;;; The type tag
;;; ----------------------------------------------------------------------------

;; book-tag : Symbol
;; The discriminating tag carried by every Book.  Tagging makes a Book
;; self-identifying, which is what lets book? be a total predicate and what
;; will let Iteration 5 tell a Book apart from a category node.
(define book-tag 'book)


;;; ----------------------------------------------------------------------------
;;; Constructor
;;; ----------------------------------------------------------------------------

;; make-book : String String Integer Symbol -> Book
;; Builds a book record from its four fields.
;; (make-book "Dune" "Frank Herbert" 1965 'sci-fi) => <book>
(define (make-book title author year genre)
  (list book-tag title author year genre))


;;; ----------------------------------------------------------------------------
;;; Selectors
;;; ----------------------------------------------------------------------------

;; book-title : Book -> String
;; The title of B.
;; (book-title (make-book "Dune" "Frank Herbert" 1965 'sci-fi)) => "Dune"
(define (book-title b) (list-ref b 1))

;; book-author : Book -> String
;; The author of B.
(define (book-author b) (list-ref b 2))

;; book-year : Book -> Integer
;; The year of publication of B.
(define (book-year b) (list-ref b 3))

;; book-genre : Book -> Symbol
;; The genre of B.
(define (book-genre b) (list-ref b 4))


;;; ----------------------------------------------------------------------------
;;; Predicates
;;; ----------------------------------------------------------------------------

;; book? : Any -> Boolean
;; True exactly for values produced by make-book.
;;
;; This procedure is TOTAL: it returns #f rather than raising an error for any
;; input whatsoever.  The list? guard is what makes that true — length raises
;; an error on an improper list such as (book . 3), so it must not be reached
;; until the argument is known to be a proper list.
;;
;; (book? (make-book "Dune" "Frank Herbert" 1965 'sci-fi)) => #t
;; (book? '())                                             => #f
(define (book? x)
  (and (pair? x)
       (list? x)
       (= (length x) 5)
       (eq? (car x) book-tag)
       (string? (list-ref x 1))
       (string? (list-ref x 2))
       ;; integer? rather than exact-integer? to stay within R5RS; a year is
       ;; expected to be exact, but inexact integers are not rejected here.
       (integer? (list-ref x 3))
       (symbol? (list-ref x 4))))

;; book=? : Book Book -> Boolean
;; Structural equality: true when B1 and B2 agree on all four fields.
;; (book=? dune dune)                        => #t
;; (book=? dune (book-with-year dune 1966))  => #f
(define (book=? b1 b2)
  (and (string=? (book-title  b1) (book-title  b2))
       (string=? (book-author b1) (book-author b2))
       (=        (book-year   b1) (book-year   b2))
       (eq?      (book-genre  b1) (book-genre  b2))))


;;; ----------------------------------------------------------------------------
;;; Persistent update
;;; ----------------------------------------------------------------------------

;; book-with-genre : Book Symbol -> Book
;; A copy of B whose genre is G.  B itself is unchanged.
;; (book-genre (book-with-genre dune 'classic)) => classic
;; (book-genre dune)                            => sci-fi
(define (book-with-genre b g)
  (make-book (book-title b) (book-author b) (book-year b) g))

;; book-with-year : Book Integer -> Book
;; A copy of B whose year is Y.  B itself is unchanged.
(define (book-with-year b y)
  (make-book (book-title b) (book-author b) y (book-genre b)))


;;; ----------------------------------------------------------------------------
;;; Rendering
;;; ----------------------------------------------------------------------------

;; book->string : Book -> String
;; A single-line rendering of B, including all four fields.
;; (book->string dune) => "Dune — Frank Herbert (1965) [sci-fi]"
;;
;; This returns a string rather than printing one: printing is a side effect and
;; belongs in the presentation layer (main.scm), not here.
(define (book->string b)
  (string-append (book-title b)
                 " — " (book-author b)
                 " (" (number->string (book-year b)) ")"
                 " [" (symbol->string (book-genre b)) "]"))
