;;; pipeline.scm — І4. map, filter, fold і агрегування каталогу.

;; my-map : (A -> B) (listof A) -> (listof B)
(define (my-map f lst)
  (if (null? lst)
      '()
      (cons (f (car lst)) (my-map f (cdr lst)))))

;; my-filter : (A -> Boolean) (listof A) -> (listof A)
(define (my-filter pred lst)
  (cond ((null? lst) '())
        ((pred (car lst))
         (cons (car lst) (my-filter pred (cdr lst))))
        (else
         (my-filter pred (cdr lst)))))

;; fold-left : (B A -> B) B (listof A) -> B
(define (fold-left f init lst)
  (if (null? lst)
      init
      (fold-left f (f init (car lst)) (cdr lst))))

;; catalog-titles : Catalog -> (listof String)
(define (catalog-titles catalog)
  (my-map book-title (catalog->list catalog)))

;; catalog-year-sum : Catalog -> Integer
(define (catalog-year-sum catalog)
  (fold-left + 0 (my-map book-year (catalog->list catalog))))

;; catalog-average-year : Catalog -> Number | #f
(define (catalog-average-year catalog)
  (if (catalog-empty? catalog)
      #f
      (/ (catalog-year-sum catalog) (catalog-count catalog))))

;; count-by-genre : Catalog -> (listof (Symbol . Integer))
(define (count-by-genre catalog)
  (define (bump genre counts)
    (cond ((null? counts) (list (cons genre 1)))
          ((eq? (caar counts) genre)
           (cons (cons genre (+ (cdar counts) 1)) (cdr counts)))
          (else (cons (car counts) (bump genre (cdr counts))))))
  (fold-left (lambda (counts b) (bump (book-genre b) counts))
             '()
             (catalog->list catalog)))