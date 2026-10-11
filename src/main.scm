(load "src/book.scm")
(load "src/catalog.scm")
(load "src/search.scm")
(load "src/pipeline.scm")
(load "src/tree.scm")

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
(define (make-state catalog tree)
  (list (cons 'catalog catalog)
        (cons 'tree tree)))

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

;; print-tree : Node Integer -> unspecified
(define (print-tree node indent)
  (display (make-string indent #\space))
  (display "+ ")
  (display (category-name node))
  (newline)
  (for-each
   (lambda (child)
     (if (book? child)
         (begin
           (display (make-string (+ indent 2) #\space))
           (display "- ")
           (display (book->string child))
           (newline))
         (print-tree child (+ indent 2))))
   (category-children node)))

;; read-path : -> (listof String)
;; Порожній рядок — корінь. Інакше імена через кому.
(define (read-path)
  (let ((line (prompt "Шлях категорій через кому (порожньо = корінь): ")))
    (if (string=? line "")
        '()
        (let loop ((chars (string->list line)) (word '()) (words '()))
          (cond ((null? chars)
                 (reverse (cons (list->string (reverse word)) words)))
                ((char=? (car chars) #\,)
                 (loop (cdr chars) '()
                       (cons (list->string (reverse word)) words)))
                ((and (char=? (car chars) #\space) (null? word))
                 (loop (cdr chars) word words))
                (else
                 (loop (cdr chars) (cons (car chars) word) words)))))))

(define sample-catalog
  (catalog-from-list
   (list
    (make-book "Foundation"  "Isaac Asimov"     1951 'sci-fi)
    (make-book "I, Robot"    "Isaac Asimov"     1950 'sci-fi)
    (make-book "Dune"        "Frank Herbert"    1965 'sci-fi)
    (make-book "Neuromancer" "William Gibson"   1984 'cyberpunk)
    (make-book "The Hobbit"  "J. R. R. Tolkien" 1937 'fantasy))))

(define sample-tree
  (let* ((t (empty-tree "Бібліотека"))
         (t (tree-add-category t '() "Художня"))
         (t (tree-add-category t '("Художня") "Фантастика"))
         (t (tree-add-book t '("Художня" "Фантастика")
                           (make-book "Dune" "Frank Herbert" 1965 'sci-fi)))
         (t (tree-add-book t '("Художня" "Фантастика")
                           (make-book "Foundation" "Isaac Asimov" 1951 'sci-fi))))
    t))

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
        (let* ((old-cat (state-ref state 'catalog))
               (new-cat (catalog-remove b old-cat))
               (new-tree (tree-remove-book (state-ref state 'tree) b)))
          (if (= (catalog-count old-cat) (catalog-count new-cat))
              (display "У списку такої книги немає.\n")
              (display "Видалено зі списку.\n"))
          (display "Дерево оновлено (усі збіги за полями прибрано).\n")
          (let* ((st (state-set state 'catalog new-cat))
                 (st (state-set st 'tree new-tree)))
            st))
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

(define (handle-show-tree state)
  (print-tree (state-ref state 'tree) 0)
  state)

(define (handle-add-category state)
  (let ((path (read-path))
        (name (prompt "Назва нової категорії: ")))
    (state-set state 'tree
               (tree-add-category (state-ref state 'tree) path name))))

;; list-ref-safe : list Integer -> Any | #f
;; n від 1. Поза діапазоном — #f.
(define (list-ref-safe lst n)
  (cond ((or (null? lst) (< n 1)) #f)
        ((= n 1) (car lst))
        (else (list-ref-safe (cdr lst) (- n 1)))))

;; handle-add-book-tree : State -> State
;; Книга береться з каталогу за номером, не створюється заново.
(define (handle-add-book-tree state)
  (let ((catalog (state-ref state 'catalog)))
    (if (catalog-empty? catalog)
        (begin
          (display "Каталог порожній — спочатку додайте книгу до списку.")
          (newline)
          state)
        (begin
          (display "Книги в каталозі:")
          (newline)
          (let loop ((books (catalog->list catalog)) (i 1))
            (if (null? books)
                #t
                (begin
                  (display "  ")
                  (display i)
                  (display ". ")
                  (display (book->string (car books)))
                  (newline)
                  (loop (cdr books) (+ i 1)))))
          (let* ((n (string->number (prompt "Номер книги: ")))
                 (b (and n (list-ref-safe (catalog->list catalog) n)))
                 (path (if b (read-path) '())))
            (if b
                (begin
                  (display "Додано в дерево.")
                  (newline)
                  (state-set state 'tree
                             (tree-add-book (state-ref state 'tree) path b)))
                (begin
                  (display "Некоректний номер.")
                  (newline)
                  state)))))))

(define (handle-remove-category state)
  (let ((path (read-path)))
    (if (null? path)
        (begin
          (display "Порожній шлях — корінь не видаляється.")
          (newline)
          state)
        (begin
          (display "Категорію (і все всередині) видалено з дерева.")
          (newline)
          (state-set state 'tree
                     (tree-remove-category (state-ref state 'tree)
                                           path))))))

(define (handle-tree-search state)
  (print-books
   (tree-search (by-genre (string->symbol (prompt "Жанр: ")))
                (state-ref state 'tree)))
  state)

;; menu-items : (listof (list String String (State -> State)))
(define menu-items
  (list
   (list "1" "Показати список"              handle-show)
   (list "2" "Додати книгу"                 handle-add)
   (list "3" "Видалити книгу"           handle-remove)
   (list "4" "Пошук: назва / автор / рік / жанр"    handle-search)
   (list "5" "Статистика (map/filter/fold)" handle-stats)
   (list "6"  "Показати дерево"              handle-show-tree)
   (list "7"  "Додати категорію"             handle-add-category)
   (list "8"  "Видалити категорію"           handle-remove-category)
   (list "9"  "Додати книгу в дерево"        handle-add-book-tree)
   (list "10" "Пошук у дереві за жанром"     handle-tree-search)))

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
(main-loop (make-state sample-catalog sample-tree))