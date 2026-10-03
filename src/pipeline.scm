;;; ============================================================================
;;; pipeline.scm — Iteration 4: Functional Collection Processing
;;; ============================================================================
;;;
;;; map, filter and fold are written by hand, and every domain question below is
;;; answered by chaining them rather than by writing a fresh recursion.
;;; ============================================================================


;;; ----------------------------------------------------------------------------
;;; Generic layer — knows nothing about books
;;; ----------------------------------------------------------------------------

;; my-map : (A -> B) (listof A) -> (listof B)
;; Applies F to every element, keeping the order.
;; (my-map (lambda (x) (* x x)) '(1 2 3)) => (1 4 9)
(define (my-map f lst)
  (if (null? lst)
      '()
      (cons (f (car lst)) (my-map f (cdr lst)))))

;; my-filter : (A -> Boolean) (listof A) -> (listof A)
;; The elements for which PRED is true, in the original order.
;; (my-filter odd? '(1 2 3 4 5)) => (1 3 5)
(define (my-filter pred lst)
  (cond ((null? lst) '())
        ((pred (car lst)) (cons (car lst) (my-filter pred (cdr lst))))
        (else (my-filter pred (cdr lst)))))

;; fold-right : (A B -> B) B (listof A) -> B
;; Combines from the right: (f x1 (f x2 (... (f xn init)))).
;; Not tail recursive — each f waits for the fold of the rest.
;; (fold-right cons '() '(1 2 3)) => (1 2 3)
(define (fold-right f init lst)
  (if (null? lst)
      init
      (f (car lst) (fold-right f init (cdr lst)))))

;; fold-left : (B A -> B) B (listof A) -> B
;; Combines from the left: (f (... (f (f init x1) x2) ...) xn).
;; Tail recursive — INIT is the accumulator, so it runs in constant space.
;; (fold-left + 0 '(1 2 3))              => 6
;; (fold-left (lambda (acc x) (cons x acc)) '() '(1 2 3)) => (3 2 1)
(define (fold-left f init lst)
  (if (null? lst)
      init
      (fold-left f (f init (car lst)) (cdr lst))))

;; flat-map : (A -> (listof B)) (listof A) -> (listof B)
;; Maps F over LST and concatenates the resulting lists.
;; (flat-map (lambda (x) (list x x)) '(1 2)) => (1 1 2 2)
(define (flat-map f lst)
  (fold-right (lambda (x acc) (append (f x) acc)) '() lst))

;; unique : (listof A) -> (listof A)
;; LST without duplicates (compared with equal?), keeping the first occurrence
;; of each element in its original position.  O(n^2).
;; (unique '(a b a c b)) => (a b c)
(define (unique lst)
  (if (null? lst)
      '()
      (let ((x (car lst)))
        (cons x (unique (my-filter (lambda (y) (not (equal? x y)))
                                   (cdr lst)))))))


;;; ----------------------------------------------------------------------------
;;; Iteration 3 searches, rewritten
;;; ----------------------------------------------------------------------------
;;;
;;; search-catalog was my-filter in disguise, and count-matching was a fold.
;;; Redefined here so the logic lives in one place; the Iteration 3 suite is the
;;; regression test.

;; search-catalog : (Book -> Boolean) Catalog -> (listof Book)
(define (search-catalog pred catalog)
  (my-filter pred (catalog->list catalog)))

;; count-matching : (Book -> Boolean) Catalog -> Integer
(define (count-matching pred catalog)
  (fold-left (lambda (n b) (if (pred b) (+ n 1) n))
             0
             (catalog->list catalog)))


;;; ----------------------------------------------------------------------------
;;; Domain layer — projections
;;; ----------------------------------------------------------------------------

;; catalog-titles : Catalog -> (listof String)
;; Replaces the hand-written recursion from catalog.scm.
(define (catalog-titles catalog)
  (my-map book-title (catalog->list catalog)))

;; catalog-authors : Catalog -> (listof String)
;; Each author once, in order of first appearance.
(define (catalog-authors catalog)
  (unique (my-map book-author (catalog->list catalog))))

;; catalog-genres : Catalog -> (listof Symbol)
;; Each genre once, in order of first appearance.
(define (catalog-genres catalog)
  (unique (my-map book-genre (catalog->list catalog))))


;;; ----------------------------------------------------------------------------
;;; Domain layer — aggregations
;;; ----------------------------------------------------------------------------

;; catalog-year-sum : Catalog -> Integer
;; Sum of publication years; 0 for an empty catalog.
(define (catalog-year-sum catalog)
  (fold-left + 0 (my-map book-year (catalog->list catalog))))

;; catalog-average-year : Catalog -> Real | #f
;; Mean publication year, or #f for an empty catalog (there is no mean of
;; nothing, and dividing by zero would raise).  The result is exact, so it may
;; be a fraction: no precision is lost, and the caller can apply exact->inexact.
;; (catalog-average-year (catalog-from-list (list dune neuromancer))) => 3949/2
(define (catalog-average-year catalog)
  (if (catalog-empty? catalog)
      #f
      (/ (catalog-year-sum catalog) (catalog-count catalog))))

;; pipeline/pick : (Book Book -> Boolean) Catalog -> Book | #f
;; The book that BETTER? prefers over every other, or #f for an empty catalog.
;; (better? candidate champion) must be true for the candidate to win, so on a
;; tie the earlier book is kept.
(define (pipeline/pick better? catalog)
  (fold-left (lambda (champion b)
               (if (or (not champion) (better? b champion)) b champion))
             #f
             (catalog->list catalog)))

;; catalog-oldest : Catalog -> Book | #f
;; The book with the smallest year; the first one on a tie.
(define (catalog-oldest catalog)
  (pipeline/pick (lambda (b champion) (< (book-year b) (book-year champion)))
                 catalog))

;; catalog-newest : Catalog -> Book | #f
;; The book with the largest year; the first one on a tie.
(define (catalog-newest catalog)
  (pipeline/pick (lambda (b champion) (> (book-year b) (book-year champion)))
                 catalog))

;; catalog-year-range : Catalog -> (Integer . Integer) | #f
;; (min-year . max-year), or #f for an empty catalog.
;; (catalog-year-range sample) => (1937 . 1984)
(define (catalog-year-range catalog)
  (if (catalog-empty? catalog)
      #f
      (cons (book-year (catalog-oldest catalog))
            (book-year (catalog-newest catalog)))))

;; count-by-genre : Catalog -> (listof (Symbol . Integer))
;; How many books each genre has, genres in order of first appearance.
;; (count-by-genre sample) => ((sci-fi . 3) (cyberpunk . 1) (fantasy . 1))
;;
;; One fold-left pass; the accumulator is an association list that is rebuilt,
;; never mutated, at each step.
(define (count-by-genre catalog)
  (define (bump genre counts)
    (cond ((null? counts) (list (cons genre 1)))
          ((eq? (car (car counts)) genre)
           (cons (cons genre (+ (cdr (car counts)) 1)) (cdr counts)))
          (else (cons (car counts) (bump genre (cdr counts))))))
  (fold-left (lambda (counts b) (bump (book-genre b) counts))
             '()
             (catalog->list catalog)))


;;; ----------------------------------------------------------------------------
;;; Pipeline examples
;;; ----------------------------------------------------------------------------

;; recent-sci-fi-titles : Catalog Integer -> (listof String)
;; Titles of sci-fi books published in YEAR or later.
;; Pipeline: filter -> map.
;; (recent-sci-fi-titles sample 1951) => ("Foundation" "Dune")
(define (recent-sci-fi-titles catalog year)
  (my-map book-title
          (my-filter (p-and (by-genre 'sci-fi)
                            (lambda (b) (>= (book-year b) year)))
                     (catalog->list catalog))))

;; total-age : Catalog Integer -> Integer
;; Sum over all books of (REF-YEAR - year): the combined age of the catalog.
;; Pipeline: map -> fold.
;; (total-age (catalog-from-list (list dune)) 2025) => 60
(define (total-age catalog ref-year)
  (fold-left + 0 (my-map (lambda (b) (- ref-year (book-year b)))
                         (catalog->list catalog))))

;; genre-total-age : Catalog Symbol Integer -> Integer
;; total-age restricted to one GENRE.
;; Pipeline: filter -> map -> fold.
;; (genre-total-age sample 'fantasy 2025) => 88
(define (genre-total-age catalog genre ref-year)
  (fold-left +
             0
             (my-map (lambda (b) (- ref-year (book-year b)))
                     (my-filter (by-genre genre) (catalog->list catalog)))))
