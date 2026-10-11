(load "src/book.scm")
(load "src/catalog.scm")
(load "src/search.scm")
(load "src/pipeline.scm")

;; read-line : -> String
(define (read-line)
  (let loop ((chars '()))
    (let ((c (read-char)))
      (cond ((eof-object? c)
             (if (null? chars) "" (list->string (reverse chars))))
            ((char=? c #\newline)
             (list->string (reverse chars)))
            ((char=? c #\return)
             (let ((n (peek-char)))
               (if (and (not (eof-object? n)) (char=? n #\newline))
                   (read-char)))
             (list->string (reverse chars)))
            (else (loop (cons c chars)))))))

;; prompt : String -> String
(define (prompt msg)
  (display msg)
  (flush-output-port (current-output-port))
  (read-line))

;; make-state : Catalog -> State
(define (make-state catalog)
  (list (cons 'catalog catalog)))

;; state-ref : State Symbol -> Any | #f
(define (state-ref state key)
  (let ((pair (assoc key state)))
    (if pair (cdr pair) #f)))

;; state-set : State Symbol Any -> State
(define (state-set state key value)
  (cond ((null? state)
         (list (cons key value)))
        ((eq? (caar state) key)
         (cons (cons key value) (cdr state)))
        (else
         (cons (car state)
               (state-set (cdr state) key value)))))

;; print-book : Book -> unspecified
(define (print-book b)
  (display "  ")
  (display (book->string b))
  (newline))

;; print-books : (listof Book) -> unspecified
(define (print-books books)
  (if (null? books)
      (begin (display "  (немає)") (newline))
      (for-each print-book books)))

;; print-catalog : Catalog -> unspecified
(define (print-catalog catalog)
  (display "Каталог (")
  (display (catalog-count catalog))
  (display "):")
  (newline)
  (print-books (catalog->list catalog)))

(define sample-catalog
  (catalog-from-list
   (list
    (make-book "Foundation"  "Isaac Asimov"     1951 'sci-fi)
    (make-book "I, Robot"    "Isaac Asimov"     1950 'sci-fi)
    (make-book "Dune"        "Frank Herbert"    1965 'sci-fi)
    (make-book "Neuromancer" "William Gibson"   1984 'cyberpunk)
    (make-book "The Hobbit"  "J. R. R. Tolkien" 1937 'fantasy))))

;; read-book : -> Book | #f
(define (read-book)
  (let* ((title  (prompt "Назва: "))
         (author (prompt "Автор: "))
         (year   (string->number (prompt "Рік: ")))
         (genre  (string->symbol (prompt "Жанр (напр. sci-fi): "))))
    (if (and (not (string=? title ""))
             (not (string=? author ""))
             (integer? year))
        (make-book title author year genre)
        #f)))

;; handle-* : State -> State

(define (handle-show state)
  (print-catalog (state-ref state 'catalog))
  state)

(define (handle-add state)
  (let ((b (read-book)))
    (if b
        (begin
          (display "Додано.")
          (newline)
          (state-set state 'catalog
                     (catalog-add b (state-ref state 'catalog))))
        (begin
          (display "Некоректні дані.")
          (newline)
          state))))

(define (handle-remove state)
  (display "Вкажіть книгу для видалення (усі поля).")
  (newline)
  (let ((b (read-book)))
    (if b
        (let* ((old (state-ref state 'catalog))
               (new (catalog-remove b old)))
          (if (= (catalog-count old) (catalog-count new))
              (display "Такої книги немає.\n")
              (display "Видалено.\n"))
          (state-set state 'catalog new))
        (begin
          (display "Некоректні дані.\n")
          state))))

(define (handle-search state)
  (let ((catalog (state-ref state 'catalog)))
    (display "  t - назва   a - автор   y - рік   g - жанр")
    (newline)
    (let ((kind (prompt "Критерій: ")))
      (cond
        ((string=? kind "t")
         (print-books
          (catalog-find-by-title (prompt "Назва: ") catalog)))
        ((string=? kind "a")
         (print-books
          (search-catalog (by-author (prompt "Автор: ")) catalog)))
        ((string=? kind "y")
         (let ((y (string->number (prompt "Рік: "))))
           (if y
               (print-books (search-catalog (by-year y) catalog))
               (display "Некоректний рік.\n"))))
        ((string=? kind "g")
         (print-books
          (search-catalog
           (by-genre (string->symbol (prompt "Жанр: ")))
           catalog)))
        (else
         (display "Невідомий критерій.\n")))))
  state)

(define (handle-stats state)
  (let ((catalog (state-ref state 'catalog)))
    (display "Книг: ")
    (display (catalog-count catalog))
    (newline)
    (display "Назви: ")
    (write (catalog-titles catalog))
    (newline)
    (let ((avg (catalog-average-year catalog)))
      (display "Середній рік: ")
      (if avg
          (display (exact->inexact avg))
          (display "немає"))
      (newline))
    (display "За жанрами: ")
    (write (count-by-genre catalog))
    (newline))
  state)

;; menu-items : (listof (list String String (State -> State)))
(define menu-items
  (list
   (list "1" "Показати список"              handle-show)
   (list "2" "Додати книгу"                 handle-add)
   (list "3" "Видалити книгу"           handle-remove)
   (list "4" "Пошук: назва / автор / рік / жанр"    handle-search)
   (list "5" "Статистика (map/filter/fold)" handle-stats)))

(define (show-menu items)
  (newline)
  (display "=== Каталог книг ===")
  (newline)
  (for-each
   (lambda (item)
     (display " ")
     (display (car item))
     (display "  ")
     (display (cadr item))
     (newline))
   items)
  (display " 0  Вихід")
  (newline))

;; find-handler : menu-items String -> (State -> State) | #f
(define (find-handler items code)
  (cond ((null? items) #f)
        ((string=? code (caar items)) (caddar items))
        (else (find-handler (cdr items) code))))

;; main-loop : State -> unspecified
(define (main-loop state)
  (show-menu menu-items)
  (let ((choice (prompt "Вибір: ")))
    (cond
      ((string=? choice "0")
       (display "До побачення.")
       (newline))
      (else
       (let ((handler (find-handler menu-items choice)))
         (if handler
             (main-loop (handler state))
             (begin
               (display "Невідома команда.")
               (newline)
               (main-loop state))))))))

(display "Старт із прикладом каталогу.")
(newline)
(main-loop (make-state sample-catalog))