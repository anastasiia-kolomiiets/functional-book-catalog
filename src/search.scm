;;; search.scm — І3. Один пошук, критерій передається як функція.

;; search-catalog : (Book -> Boolean) Catalog -> (listof Book)
(define (search-catalog pred catalog)
  (cond ((null? catalog) '())
        ((pred (car catalog))
         (cons (car catalog) (search-catalog pred (cdr catalog))))
        (else
         (search-catalog pred (cdr catalog)))))

;; by-author : String -> (Book -> Boolean)
(define (by-author name)
  (lambda (b) (string=? (book-author b) name)))

;; by-year : Integer -> (Book -> Boolean)
(define (by-year year)
  (lambda (b) (= (book-year b) year)))

;; by-genre : Symbol -> (Book -> Boolean)
;; «Категорія» з таблиці — це жанр книги.
(define (by-genre genre)
  (lambda (b) (eq? (book-genre b) genre)))