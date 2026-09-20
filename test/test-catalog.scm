;;; ============================================================================
;;; test-catalog.scm — tests for Iteration 2 (src/catalog.scm)
;;; ============================================================================

(define (catalog-tests)
  (let* ((b1  (make-book "Dune" "Frank Herbert" 1965 'sci-fi))
         (b2  (make-book "Neuromancer" "William Gibson" 1984 'cyberpunk))
         (b3  (make-book "Foundation" "Isaac Asimov" 1951 'sci-fi))
         ;; added one at a time, so the newest book ends up first
         (cat (catalog-add b3 (catalog-add b2 (catalog-add b1 (empty-catalog))))))
    (list

     ;; empty catalog
     (check-true "a new catalog is empty" (catalog-empty? (empty-catalog)))
     (check "an empty catalog has 0 books" 0 (catalog-count (empty-catalog)))

     ;; adding
     (check "after adding 3 books the count is 3" 3 (catalog-count cat))
     (check-false "a catalog with books is not empty" (catalog-empty? cat))
     (check "adding does not change the old catalog" 0
            (catalog-count (empty-catalog)))
     (check "catalog-from-list keeps all the books" 3
            (catalog-count (catalog-from-list (list b1 b2 b3))))

     ;; searching
     (check "find gets the right book" "Frank Herbert"
            (book-author (catalog-find-by-title "Dune" cat)))
     (check-false "find returns #f when the title is not there"
                  (catalog-find-by-title "No Such Book" cat))
     (check-false "find on an empty catalog returns #f"
                  (catalog-find-by-title "Dune" (empty-catalog)))
     (check-true "contains? finds a book that is there"
                 (catalog-contains? "Neuromancer" cat))
     (check-false "contains? is false for a missing book"
                  (catalog-contains? "No Such Book" cat))

     ;; removing
     (check "removing one book leaves 2" 2
            (catalog-count (catalog-remove-by-title "Dune" cat)))
     (check-false "the removed book is really gone"
                  (catalog-contains? "Dune"
                                     (catalog-remove-by-title "Dune" cat)))
     (check "removing a title that is not there changes nothing" 3
            (catalog-count (catalog-remove-by-title "No Such Book" cat)))
     (check "the original catalog still has 3 books after removing" 3
            (catalog-count cat))

     ;; titles
     (check "titles are listed in catalog order"
            (list "Foundation" "Neuromancer" "Dune")
            (catalog-titles cat))
     (check "an empty catalog has no titles" '()
            (catalog-titles (empty-catalog))))))
