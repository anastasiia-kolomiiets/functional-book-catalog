;;; test-catalog.scm — тести І2 (src/catalog.scm)
;;; Потрібні: src/book.scm, src/catalog.scm, test/test-framework.scm

(define (catalog-tests)
  (let* ((b1  (make-book "Dune" "Frank Herbert" 1965 'sci-fi))
         (b2  (make-book "Neuromancer" "William Gibson" 1984 'cyberpunk))
         (b3  (make-book "Foundation" "Isaac Asimov" 1951 'sci-fi))
         (b1b (make-book "Dune" "Other Author" 1970 'classic))
         (cat (catalog-add b3 (catalog-add b2 (catalog-add b1 (empty-catalog)))))
         (cat2 (catalog-add b1b cat)))
    (list

     ;; порожній каталог
     (check-true "новий каталог порожній"
                 (catalog-empty? (empty-catalog)))
     (check "у порожньому 0 книг" 0
            (catalog-count (empty-catalog)))

     ;; додавання
     (check "після 3 книг count = 3" 3 (catalog-count cat))
     (check-false "каталог із книгами не порожній" (catalog-empty? cat))
     (check "додавання не змінює старий каталог" 0
            (catalog-count (empty-catalog)))
     (check "catalog-from-list зберігає всі книги" 3
            (catalog-count (catalog-from-list (list b1 b2 b3))))

     ;; пошук за назвою — список усіх збігів
     (check "find за назвою знаходить одну книгу" 1
            (length (catalog-find-by-title "Dune" cat)))
     (check "find повертає правильного автора"
            "Frank Herbert"
            (book-author (car (catalog-find-by-title "Dune" cat))))
     (check "find за відсутньою назвою — порожній список" '()
            (catalog-find-by-title "No Such Book" cat))
     (check "find у порожньому каталозі — ()" '()
            (catalog-find-by-title "Dune" (empty-catalog)))
     (check "find збирає всі книги з однаковою назвою" 2
            (length (catalog-find-by-title "Dune" cat2)))

     ;; видалення за book=?
     (check "після remove однієї книги лишається 2" 2
            (catalog-count (catalog-remove b1 cat)))
     (check "видалена книга більше не знаходиться" '()
            (catalog-find-by-title "Dune" (catalog-remove b1 cat)))
     (check "remove відсутньої книги нічого не змінює" 3
            (catalog-count (catalog-remove
                            (make-book "No" "One" 2000 'x) cat)))
     (check "оригінал після remove лишається з 3 книгами" 3
            (catalog-count cat))
     (check "remove b1 лишає іншу книгу з назвою Dune" 1
            (length (catalog-find-by-title
                     "Dune"
                     (catalog-remove b1 cat2))))
     (check "після remove b1 у cat2 лишається Other Author"
            "Other Author"
            (book-author
             (car (catalog-find-by-title "Dune"
                                         (catalog-remove b1 cat2))))))))