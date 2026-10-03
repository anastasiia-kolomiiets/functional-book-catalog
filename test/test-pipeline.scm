;;; ============================================================================
;;; test-pipeline.scm — tests for Iteration 4 (src/pipeline.scm)
;;; ============================================================================

(define (pipeline-tests)
  (let* ((b1  (make-book "Dune" "Frank Herbert" 1965 'sci-fi))
         (b2  (make-book "Neuromancer" "William Gibson" 1984 'cyberpunk))
         (b3  (make-book "Foundation" "Isaac Asimov" 1951 'sci-fi))
         (b4  (make-book "I, Robot" "Isaac Asimov" 1950 'sci-fi))
         (cat (catalog-from-list (list b1 b2 b3 b4))))
    (list

     ;; map, filter, fold on plain lists
     (check "my-map squares numbers" '(1 4 9)
            (my-map (lambda (x) (* x x)) '(1 2 3)))
     (check "my-filter keeps odd numbers" '(1 3)
            (my-filter odd? '(1 2 3 4)))
     (check "fold-left adds numbers" 6 (fold-left + 0 '(1 2 3)))
     (check "fold-right with cons gives the same list" '(1 2 3)
            (fold-right cons '() '(1 2 3)))
     (check "flat-map joins the lists" '(1 1 2 2)
            (flat-map (lambda (x) (list x x)) '(1 2)))
     (check "unique removes repeats" '(a b c) (unique '(a b a c b)))

     ;; authors and genres
     (check "authors are listed once each"
            (list "Frank Herbert" "William Gibson" "Isaac Asimov")
            (catalog-authors cat))
     (check "genres are listed once each" '(sci-fi cyberpunk)
            (catalog-genres cat))

     ;; years
     (check "sum of years" 7850 (catalog-year-sum cat))
     (check "average year" 3925/2 (catalog-average-year cat))
     (check-false "average of an empty catalog is #f"
                  (catalog-average-year (empty-catalog)))
     (check "oldest book" "I, Robot" (book-title (catalog-oldest cat)))
     (check "newest book" "Neuromancer" (book-title (catalog-newest cat)))
     (check-false "oldest of an empty catalog is #f"
                  (catalog-oldest (empty-catalog)))
     (check "year range" '(1950 . 1984) (catalog-year-range cat))

     ;; counting by genre
     (check "count by genre" '((sci-fi . 3) (cyberpunk . 1))
            (count-by-genre cat))

     ;; pipelines
     (check "sci-fi titles from 1951" (list "Dune" "Foundation")
            (recent-sci-fi-titles cat 1951))
     (check "total age in 2025" 101
            (total-age (catalog-from-list (list b1 b2)) 2025))
     (check "total age of sci-fi in 2025" 209
            (genre-total-age cat 'sci-fi 2025)))))
