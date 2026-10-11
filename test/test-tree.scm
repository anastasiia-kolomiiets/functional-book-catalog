;;; test-tree.scm — тести І5 (src/tree.scm)
;;; Потрібні: book, catalog, pipeline, tree, test-framework

(define (tree-tests)
  (let* ((dune   (make-book "Dune" "Frank Herbert" 1965 'sci-fi))
         (found  (make-book "Foundation" "Isaac Asimov" 1951 'sci-fi))
         (hobbit (make-book "The Hobbit" "J. R. R. Tolkien" 1937 'fantasy))
         (root   (empty-tree "Бібліотека"))
         (t1     (tree-add-category root '() "Художня"))
         (t2     (tree-add-category t1 '("Художня") "Фантастика"))
         (t3     (tree-add-book t2 '("Художня" "Фантастика") dune))
         (t4     (tree-add-book t3 '("Художня" "Фантастика") found))
         (t5     (tree-add-book t4 '() hobbit)))
    (list

     ;; порожнє дерево
     (check "ім'я кореня" "Бібліотека" (category-name root))
     (check "у порожнього дерева немає дітей" '()
            (category-children root))
     (check-true "empty-tree дає category?" (category? root))
     (check "у порожнього дерева немає книг" '()
            (tree-books root))

     ;; category?
     (check-false "category? відхиляє книгу" (category? dune))
     (check-false "category? відхиляє рядок" (category? "Бібліотека"))
     (check-false "category? відхиляє порожній список" (category? '()))

     ;; додавання категорій
     (check-true "після add-category є підкатегорія Художня"
                 (category?
                  (find-child "Художня" (category-children t1))))
     (check "повторне додавання тієї ж категорії не дублює"
            1
            (length
             (my-filter
              (lambda (c)
                (and (category? c)
                     (string=? (category-name c) "Художня")))
              (category-children
               (tree-add-category t1 '() "Художня")))))

     ;; додавання книг і обхід
     (check "tree-books збирає книги з піддерева" 2
            (length (tree-books t4)))
     (check "порядок обходу: спочатку глибші, потім у порядку дітей"
            (list "Dune" "Foundation")
            (map book-title (tree-books t4)))
     (check "книга в корені теж у tree-books" 3
            (length (tree-books t5)))
     (check "The Hobbit є серед книг t5" "The Hobbit"
            (book-title
             (car (my-filter
                   (lambda (b) (string=? (book-title b) "The Hobbit"))
                   (tree-books t5)))))

     ;; оригінал не змінюється
     (check "add-book не змінює попереднє дерево" 2
            (length (tree-books t4)))
     (check "t3 має лише Dune" 1
            (length (tree-books t3)))

     ;; tree-search
     (check "tree-search за жанром sci-fi" 2
            (length (tree-search (by-genre 'sci-fi) t5)))
     (check "tree-search fantasy" 1
            (length (tree-search (by-genre 'fantasy) t5)))
     (check "tree-search без збігів" '()
            (tree-search (by-genre 'romance) t5))

     ;; tree->catalog
     (check "tree->catalog дає стільки ж книг" 3
            (catalog-count (tree->catalog t5)))
     (check "tree->catalog містить Foundation"
            1
            (length (catalog-find-by-title
                     "Foundation"
                     (tree->catalog t5))))

    (check "tree-remove-book прибирає книгу"
            1
            (length (tree-books (tree-remove-book t4 dune))))
    (check "після remove Dune лишається Foundation"
            "Foundation"
            (book-title (car (tree-books (tree-remove-book t4 dune)))))
    (check "remove відсутньої книги не змінює кількість" 2
            (length (tree-books
                    (tree-remove-book t4 hobbit))))
    (check "оригінал t4 після remove без змін" 2
            (length (tree-books t4)))
    (check "remove з кореня прибирає книгу на верхньому рівні" 2
            (length (tree-books (tree-remove-book t5 hobbit))))

    (check "remove-category прибирає підкатегорію"
            #f
            (find-child "Фантастика"
                   (category-children
                    (find-child "Художня"
                                (category-children
                                 (tree-remove-category
                                  t4 '("Художня" "Фантастика")))))))

    (check "після remove Фантастика книги з неї зникають" 0
            (length
                (tree-books
                (tree-remove-category t4 '("Художня" "Фантастика")))))

    (check "порожній path не змінює дерево" 2
            (length (tree-books (tree-remove-category t4 '()))))

    (check "неіснуючий path не ламає дерево" 2
            (length (tree-books
                    (tree-remove-category t4 '("Немає")))))

    (check "оригінал t4 після remove без змін" 2
            (length (tree-books t4)))

     ;; шлях створюється, якщо проміжних вузлів ще немає
     (check "add-book створює проміжні категорії" 1
            (length
                    (tree-books
                    (tree-add-book root '("А" "Б") dune)))))))