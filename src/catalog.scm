;;; catalog.scm — І2. Каталог як список. Додавання, пошук, видалення, підрахунок.
;;; Каталог — список книг. Зміни повертають новий список.

;; empty-catalog : -> Catalog
(define (empty-catalog) '())

;; catalog-empty? : Catalog -> Boolean
(define (catalog-empty? catalog)
  (null? catalog))

;; catalog-add : Book Catalog -> Catalog
(define (catalog-add book catalog)
  (cons book catalog))

;; catalog-from-list : (listof Book) -> Catalog
;; catalog->list     : Catalog -> (listof Book)
(define (catalog-from-list books) books)
(define (catalog->list catalog) catalog)

;; catalog-count : Catalog -> Integer
(define (catalog-count catalog)
  (let loop ((items catalog) (n 0))
    (if (null? items)
        n
        (loop (cdr items) (+ n 1)))))

;; catalog-find-by-title : String Catalog -> (listof Book)
(define (catalog-find-by-title title catalog)
  (cond ((null? catalog) '())
        ((string=? title (book-title (car catalog)))
         (cons (car catalog)
               (catalog-find-by-title title (cdr catalog))))
        (else
         (catalog-find-by-title title (cdr catalog)))))

;; catalog-remove : Book Catalog -> Catalog
;; Видаляє перший збіг за book=?; решту з такою ж назвою не чіпає.
(define (catalog-remove book catalog)
  (cond ((null? catalog) '())
        ((book=? book (car catalog))
         (cdr catalog))
        (else
         (cons (car catalog)
               (catalog-remove book (cdr catalog))))))