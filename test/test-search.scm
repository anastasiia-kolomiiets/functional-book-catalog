;;; ============================================================================
;;; test-search.scm — tests for Iteration 3 (src/search.scm)
;;; ============================================================================

(define (search-tests)
  (let* ((b1  (make-book "Dune" "Frank Herbert" 1965 'sci-fi))
         (b2  (make-book "Neuromancer" "William Gibson" 1984 'cyberpunk))
         (b3  (make-book "Foundation" "Isaac Asimov" 1951 'sci-fi))
         (b4  (make-book "I, Robot" "Isaac Asimov" 1950 'sci-fi))
         (cat (catalog-from-list (list b1 b2 b3 b4))))
    (list

     ;; searching with different predicates
     (check "search by genre finds 3 sci-fi books" 3
            (length (search-catalog (by-genre 'sci-fi) cat)))
     (check "search by author finds 2 books" 2
            (length (search-catalog (by-author "Isaac Asimov") cat)))
     (check "search keeps the original order"
            (list "Dune" "Foundation" "I, Robot")
            (catalog-titles (search-catalog (by-genre 'sci-fi) cat)))
     (check "search with no matches gives an empty list" '()
            (search-catalog (by-genre 'romance) cat))
     (check "search on an empty catalog gives an empty list" '()
            (search-catalog (by-genre 'sci-fi) (empty-catalog)))

     ;; a predicate written on the spot, with no ready-made procedure for it
     (check "my own lambda works as a predicate" 2
            (length (search-catalog (lambda (b) (> (book-year b) 1960)) cat)))

     (check "year-between includes both ends" 2
            (length (search-catalog (year-between 1950 1951) cat)))
     (check "title-contains finds part of a title" "Foundation"
            (book-title (find-first (title-contains "ound") cat)))

     ;; find-first
     (check "find-first gives the first match" "Dune"
            (book-title (find-first (by-genre 'sci-fi) cat)))
     (check-false "find-first gives #f when nothing matches"
                  (find-first (by-genre 'romance) cat))

     ;; count-matching
     (check "count-matching counts the sci-fi books" 3
            (count-matching (by-genre 'sci-fi) cat))
     (check "count-matching is 0 when nothing matches" 0
            (count-matching (by-year 2000) cat))

     ;; any-match? and all-match?
     (check-true "any-match? is true when one book matches"
                 (any-match? (by-year 1984) cat))
     (check-false "any-match? is false when no book matches"
                  (any-match? (by-year 2000) cat))
     (check-true "all-match? is true when every book matches"
                 (all-match? (lambda (b) (> (book-year b) 1900)) cat))
     (check-false "all-match? is false when one book does not match"
                  (all-match? (by-genre 'sci-fi) cat))
     (check-true "all-match? on an empty catalog is true"
                 (all-match? (by-genre 'sci-fi) (empty-catalog)))

     ;; combining predicates
     (check "p-and needs both predicates to be true" 1
            (length (search-catalog (p-and (by-genre 'sci-fi)
                                           (year-between 1960 1970))
                                    cat)))
     (check "p-or needs only one predicate to be true" 2
            (length (search-catalog (p-or (by-genre 'cyberpunk)
                                          (by-year 1965))
                                    cat)))
     (check "p-not turns a predicate around" 1
            (length (search-catalog (p-not (by-genre 'sci-fi)) cat))))))
