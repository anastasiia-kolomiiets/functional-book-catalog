;;; index.scm — І6. Індекс «автор → список книг» (alist-таблиця)
;;; table: (listof (key . value)). value для індексу — (listof Book).

;; table-put : Any Any Table -> Table
;; Додає або замінює пару (key . value).
(define (table-put key value table)
  (cond ((null? table)
         (list (cons key value)))
        ((equal? (caar table) key)
         (cons (cons key value) (cdr table)))
        (else
         (cons (car table)
               (table-put key value (cdr table))))))

;; table-get : Any Table -> Any | #f
(define (table-get key table)
  (cond ((null? table) #f)
        ((equal? (caar table) key) (cdar table))
        (else (table-get key (cdr table)))))

;; table-keys : Table -> (listof Any)
(define (table-keys table)
  (if (null? table)
      '()
      (cons (caar table) (table-keys (cdr table)))))

;; index-by-author : Catalog -> Table
;; Ключ — рядок автора, значення — список його книг (порядок каталогу).
(define (index-by-author catalog)
  (fold-left
   (lambda (table book)
     (let* ((author (book-author book))
            (old (table-get author table))
            (books (if old
                       (append old (list book))
                       (list book))))
       (table-put author books table)))
   '()
   (catalog->list catalog)))

;; index-lookup : Table String -> (listof Book)
;; Немає автора в індексі — порожній список.
(define (index-lookup index author)
  (let ((books (table-get author index)))
    (if books books '())))