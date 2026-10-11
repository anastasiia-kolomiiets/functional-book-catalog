;;; test-search.scm — тести І3 (src/search.scm)
;;; Потрібні: src/book.scm, src/catalog.scm, src/search.scm, test/test-framework.scm

(define (search-tests)
  (let* ((b1  (make-book "Dune" "Frank Herbert" 1965 'sci-fi))
         (b2  (make-book "Neuromancer" "William Gibson" 1984 'cyberpunk))
         (b3  (make-book "Foundation" "Isaac Asimov" 1951 'sci-fi))
         (b4  (make-book "I, Robot" "Isaac Asimov" 1950 'sci-fi))
         (cat (catalog-from-list (list b1 b2 b3 b4))))
    (list

     (check "пошук за жанром знаходить 3 sci-fi" 3
            (length (search-catalog (by-genre 'sci-fi) cat)))
     (check "пошук за автором знаходить 2 книги" 2
            (length (search-catalog (by-author "Isaac Asimov") cat)))
     (check "пошук за роком знаходить 1 книгу" 1
            (length (search-catalog (by-year 1965) cat)))
     (check "порядок збігів як у каталозі"
            (list "Dune" "Foundation" "I, Robot")
            (map book-title
                 (search-catalog (by-genre 'sci-fi) cat)))
     (check "немає збігів — порожній список" '()
            (search-catalog (by-genre 'romance) cat))
     (check "порожній каталог — порожній список" '()
            (search-catalog (by-genre 'sci-fi) (empty-catalog)))

     (check "власна lambda як предикат" 2
            (length (search-catalog
                     (lambda (b) (> (book-year b) 1960))
                     cat)))

     (check-true  "by-author істинний для свого автора"
                  ((by-author "Frank Herbert") b1))
     (check-false "by-author хибний для іншого автора"
                  ((by-author "Isaac Asimov") b1))
     (check-true  "by-year істинний для свого року"
                  ((by-year 1965) b1))
     (check-false "by-year хибний для іншого року"
                  ((by-year 1951) b1))
     (check-true  "by-genre істинний для свого жанру"
                  ((by-genre 'sci-fi) b1))
     (check-false "by-genre хибний для іншого жанру"
                  ((by-genre 'cyberpunk) b1)))))