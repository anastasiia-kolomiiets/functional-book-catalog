;;; test-index.scm — тести І6 (src/index.scm)
;;; Потрібні: book, catalog, pipeline, index, test-framework

(define (index-tests)
  (let* ((b1  (make-book "Dune" "Frank Herbert" 1965 'sci-fi))
         (b2  (make-book "Neuromancer" "William Gibson" 1984 'cyberpunk))
         (b3  (make-book "Foundation" "Isaac Asimov" 1951 'sci-fi))
         (b4  (make-book "I, Robot" "Isaac Asimov" 1950 'sci-fi))
         (cat (catalog-from-list (list b1 b2 b3 b4)))
         (idx (index-by-author cat))
         (empty-idx (index-by-author (empty-catalog))))
    (list

     ;; порожня таблиця / порожній каталог
     (check "індекс порожнього каталогу не має ключів" '()
            (table-keys empty-idx))
     (check "lookup у порожньому індексі — ()" '()
            (index-lookup empty-idx "Anyone"))

     ;; table-put / table-get / table-keys
     (check "table-get знаходить значення" 'v
            (table-get 'k (table-put 'k 'v '())))
     (check "table-get відсутнього ключа — #f" #f
            (table-get 'x '()))
     (check "table-put замінює значення за ключем" 'new
            (table-get 'k (table-put 'k 'new (table-put 'k 'old '()))))
     (check "table-keys після двох put" '(a b)
            (table-keys (table-put 'b 2 (table-put 'a 1 '()))))

     ;; index-by-author
     (check "у індексі 3 автори" 3
            (length (table-keys idx)))
     (check "Asimov має 2 книги" 2
            (length (index-lookup idx "Isaac Asimov")))
     (check "Herbert має 1 книгу" 1
            (length (index-lookup idx "Frank Herbert")))
     (check "невідомий автор — порожній список" '()
            (index-lookup idx "No Such Author"))
     (check "порядок книг Asimov як у каталозі"
            (list "Foundation" "I, Robot")
            (map book-title (index-lookup idx "Isaac Asimov")))
     (check "Gibson: назва Neuromancer"
            "Neuromancer"
            (book-title (car (index-lookup idx "William Gibson"))))

     ;; індекс не змінює каталог
     (check "після index-by-author у каталозі ті самі 4 книги" 4
            (catalog-count cat)))))