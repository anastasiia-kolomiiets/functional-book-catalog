;;; book.scm — І1. Абстракція книги (пари, cons, селектори)
;;; Подання: (book title author year genre). Зовні — лише селектори.

;; make-book : String String Integer Symbol -> Book
(define (make-book title author year genre)
  (list 'book title author year genre))

;; book-title, book-author, book-year, book-genre : Book -> поле
(define (book-title b)  (cadr b))
(define (book-author b) (caddr b))
(define (book-year b)   (cadddr b))
(define (book-genre b)  (car (cddddr b)))

;; book? : Any -> Boolean
;; Потрібен, щоб у дереві відрізнити книгу від категорії.
(define (book? x)
  (and (list? x)
       (= (length x) 5)
       (eq? (car x) 'book)
       (string? (cadr x))
       (string? (caddr x))
       (integer? (cadddr x))
       (symbol? (car (cddddr x)))))

;; book=? : Book Book -> Boolean
(define (book=? a b)
  (and (string=? (book-title a) (book-title b))
       (string=? (book-author a) (book-author b))
       (= (book-year a) (book-year b))
       (eq? (book-genre a) (book-genre b))))

;; book->string : Book -> String
(define (book->string b)
  (string-append (book-title b)
                 " — " (book-author b)
                 " (" (number->string (book-year b)) ") ["
                 (symbol->string (book-genre b)) "]"))