;;; test-pipeline.scm — тести І4 (src/pipeline.scm)
;;; Потрібні: book, catalog, pipeline, test-framework

(define (pipeline-tests)
  (let* ((b1  (make-book "Dune" "Frank Herbert" 1965 'sci-fi))
         (b2  (make-book "Neuromancer" "William Gibson" 1984 'cyberpunk))
         (b3  (make-book "Foundation" "Isaac Asimov" 1951 'sci-fi))
         (b4  (make-book "I, Robot" "Isaac Asimov" 1950 'sci-fi))
         (cat (catalog-from-list (list b1 b2 b3 b4))))
    (list

     (check "my-map підносить до квадрата" '(1 4 9)
            (my-map (lambda (x) (* x x)) '(1 2 3)))
     (check "my-filter лишає непарні" '(1 3)
            (my-filter odd? '(1 2 3 4)))
     (check "fold-left сумує" 6
            (fold-left + 0 '(1 2 3)))
     (check "fold-left на порожньому дає init" 0
            (fold-left + 0 '()))

     (check "catalog-titles у порядку каталогу"
            (list "Dune" "Neuromancer" "Foundation" "I, Robot")
            (catalog-titles cat))
     (check "порожній каталог — немає назв" '()
            (catalog-titles (empty-catalog)))

     (check "сума років" 7850 (catalog-year-sum cat))
     (check "середній рік" 3925/2 (catalog-average-year cat))
     (check-false "середнє порожнього каталогу — #f"
                  (catalog-average-year (empty-catalog)))

     (check "count-by-genre"
            '((sci-fi . 3) (cyberpunk . 1))
            (count-by-genre cat))
     (check "count-by-genre для порожнього" '()
            (count-by-genre (empty-catalog))))))