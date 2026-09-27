;;; ============================================================================
;;; search.scm — Iteration 3: Search as a Higher-Order Function
;;; ============================================================================
;;;
;;; A predicate is a procedure (Book -> Boolean).  Because a procedure can be
;;; passed as an argument, one search procedure can answer any question, and the
;;; separate find-by-title / find-by-author / find-by-year procedures disappear.
;;; ============================================================================


;;; ----------------------------------------------------------------------------
;;; The search engine
;;; ----------------------------------------------------------------------------

;; search-catalog : (Book -> Boolean) Catalog -> (listof Book)
;; All books for which PRED is true, in the original order.
;; PRED is called with (pred (car catalog)) — it is a procedure, not a value.
(define (search-catalog pred catalog)
  (cond ((null? catalog) '())
        ((pred (car catalog))
         (cons (car catalog) (search-catalog pred (cdr catalog))))
        (else
         (search-catalog pred (cdr catalog)))))

;; find-first : (Book -> Boolean) Catalog -> Book | #f
(define (find-first pred catalog)
  (cond ((null? catalog) #f)
        ((pred (car catalog)) (car catalog))
        (else (find-first pred (cdr catalog)))))

;; count-matching : (Book -> Boolean) Catalog -> Integer
(define (count-matching pred catalog)
  (let loop ((items catalog) (n 0))
    (cond ((null? items) n)
          ((pred (car items)) (loop (cdr items) (+ n 1)))
          (else (loop (cdr items) n)))))

;; any-match? : (Book -> Boolean) Catalog -> Boolean
(define (any-match? pred catalog)
  (if (find-first pred catalog) #t #f))

;; all-match? : (Book -> Boolean) Catalog -> Boolean
;; True for an empty catalog: there is no book there that breaks the rule.
(define (all-match? pred catalog)
  (cond ((null? catalog) #t)
        ((pred (car catalog)) (all-match? pred (cdr catalog)))
        (else #f)))


;;; ----------------------------------------------------------------------------
;;; Building predicates
;;; ----------------------------------------------------------------------------
;;;
;;; Each of these RETURNS a procedure.  (by-genre 'sci-fi) *is* the predicate —
;;; you hand it to search-catalog, you never call it yourself.

;; by-title : String -> (Book -> Boolean)
(define (by-title title)
  (lambda (b) (string=? (book-title b) title)))

;; by-author : String -> (Book -> Boolean)
(define (by-author author)
  (lambda (b) (string=? (book-author b) author)))

;; by-genre : Symbol -> (Book -> Boolean)
(define (by-genre genre)
  (lambda (b) (eq? (book-genre b) genre)))

;; by-year : Integer -> (Book -> Boolean)
(define (by-year year)
  (lambda (b) (= (book-year b) year)))

;; year-between : Integer Integer -> (Book -> Boolean)
;; Both ends are included.
(define (year-between from to)
  (lambda (b) (and (>= (book-year b) from)
                   (<= (book-year b) to))))

;; string-contains? : String String -> Boolean
;; True when NEEDLE appears anywhere inside HAYSTACK.  Scheme has no standard
;; substring search, so we slide a window along and compare.
(define (string-contains? haystack needle)
  (let ((h (string-length haystack))
        (n (string-length needle)))
    (let loop ((i 0))
      (cond ((> (+ i n) h) #f)
            ((string=? (substring haystack i (+ i n)) needle) #t)
            (else (loop (+ i 1)))))))

;; title-contains : String -> (Book -> Boolean)
(define (title-contains part)
  (lambda (b) (string-contains? (book-title b) part)))


;;; ----------------------------------------------------------------------------
;;; Combining predicates
;;; ----------------------------------------------------------------------------
;;;
;;; Two arguments each, to keep them simple.  For three, nest them:
;;;   (p-and p1 (p-and p2 p3))

;; p-and : (Book -> Boolean) (Book -> Boolean) -> (Book -> Boolean)
(define (p-and p1 p2)
  (lambda (b) (and (p1 b) (p2 b))))

;; p-or : (Book -> Boolean) (Book -> Boolean) -> (Book -> Boolean)
(define (p-or p1 p2)
  (lambda (b) (or (p1 b) (p2 b))))

;; p-not : (Book -> Boolean) -> (Book -> Boolean)
(define (p-not p)
  (lambda (b) (not (p b))))


;;; ----------------------------------------------------------------------------
;;; Iteration 2 searches, rewritten
;;; ----------------------------------------------------------------------------
;;;
;;; Same behaviour as the hand-written recursions in catalog.scm, now one line
;;; each.  search.scm is loaded after catalog.scm, so these definitions replace
;;; the earlier ones — and the Iteration 2 tests still pass, unchanged.

;; catalog-find-by-title : String Catalog -> Book | #f
(define (catalog-find-by-title title catalog)
  (find-first (by-title title) catalog))

;; catalog-contains? : String Catalog -> Boolean
(define (catalog-contains? title catalog)
  (any-match? (by-title title) catalog))
