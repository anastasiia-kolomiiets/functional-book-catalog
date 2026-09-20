;;; ============================================================================
;;; catalog.scm — Iteration 2: Object Collection
;;; ============================================================================
;;;
;;; A Catalog is a list of Books.  Nothing is ever modified: every operation
;;; that "changes" a catalog returns a new one.
;;; ============================================================================


;;; ----------------------------------------------------------------------------
;;; Constructors
;;; ----------------------------------------------------------------------------

;; empty-catalog : -> Catalog
(define (empty-catalog) '())

;; catalog-empty? : Catalog -> Boolean
(define (catalog-empty? catalog)
  (null? catalog))

;; catalog-add : Book Catalog -> Catalog
;; Adds BOOK to the front.  CATALOG is unchanged.
(define (catalog-add book catalog)
  (cons book catalog))

;; catalog-from-list : (listof Book) -> Catalog
;; catalog->list : Catalog -> (listof Book)
;; Both are the identity today, because a Catalog IS a list.  They exist so the
;; representation can change later without touching any caller.
(define (catalog-from-list books) books)
(define (catalog->list catalog) catalog)


;;; ----------------------------------------------------------------------------
;;; Counting
;;; ----------------------------------------------------------------------------

;; catalog-count : Catalog -> Integer
;; Tail recursive: N carries the answer forward, so nothing is left pending and
;; the loop runs in constant space.
(define (catalog-count catalog)
  (let loop ((items catalog) (n 0))
    (if (null? items)
        n
        (loop (cdr items) (+ n 1)))))


;;; ----------------------------------------------------------------------------
;;; Searching
;;; ----------------------------------------------------------------------------

;; catalog-find-by-title : String Catalog -> Book | #f
;; Returns the book itself, not #t, so the result is directly usable.
;; #f means "not found" — '() would not work, because '() is true in Scheme.
(define (catalog-find-by-title title catalog)
  (cond ((catalog-empty? catalog) #f)
        ((string=? title (book-title (car catalog))) (car catalog))
        (else (catalog-find-by-title title (cdr catalog)))))

;; catalog-contains? : String Catalog -> Boolean
(define (catalog-contains? title catalog)
  (if (catalog-find-by-title title catalog) #t #f))


;;; ----------------------------------------------------------------------------
;;; Removing
;;; ----------------------------------------------------------------------------

;; catalog-remove-by-title : String Catalog -> Catalog
;; A new catalog without any book of that title.  Removing an absent title
;; returns an equal catalog.
;;
;; The else branch must cons the kept book back on; forgetting it silently
;; drops every book before the match.
(define (catalog-remove-by-title title catalog)
  (cond ((catalog-empty? catalog) (empty-catalog))
        ((string=? title (book-title (car catalog)))
         (catalog-remove-by-title title (cdr catalog)))
        (else
         (cons (car catalog)
               (catalog-remove-by-title title (cdr catalog))))))


;;; ----------------------------------------------------------------------------
;;; Projection
;;; ----------------------------------------------------------------------------

;; catalog-titles : Catalog -> (listof String)
;; Written by hand here to practise the recursion template.  Iteration 4
;; replaces the body with (map book-title catalog).
(define (catalog-titles catalog)
  (if (catalog-empty? catalog)
      '()
      (cons (book-title (car catalog))
            (catalog-titles (cdr catalog)))))
