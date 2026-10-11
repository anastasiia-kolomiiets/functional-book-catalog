;;; test-book.scm — тести І1 (src/book.scm)
;;; Потрібні: src/book.scm, test/test-framework.scm

(define (book-tests)
  (let* ((dune      (make-book "Dune" "Frank Herbert" 1965 'sci-fi))
         (dune-copy (make-book "Dune" "Frank Herbert" 1965 'sci-fi))
         (empties   (make-book "" "" 0 'unknown))
         (ancient   (make-book "The Iliad" "Homer" -750 'epic)))
    (list

     ;; конструктор і селектори
     (check "book-title повертає назву"   "Dune"          (book-title  dune))
     (check "book-author повертає автора" "Frank Herbert" (book-author dune))
     (check "book-year повертає рік"      1965            (book-year   dune))
     (check "book-genre повертає жанр"    'sci-fi         (book-genre  dune))

     ;; book?: #t для книги, #f для іншого (без помилки)
     (check-true  "book? приймає книгу"              (book? dune))
     (check-false "book? відхиляє рядок"             (book? "Dune"))
     (check-false "book? відхиляє порожній список"   (book? '()))
     (check-false "book? відхиляє число"             (book? 42))
     (check-false "book? відхиляє булеве"            (book? #t))
     (check-false "book? відхиляє символ"            (book? 'book))
     (check-false "book? відхиляє неправильний список"
                  (book? (cons 'book 3)))
     (check-false "book? відхиляє короткий список"
                  (book? (list 'book "t" "a")))
     (check-false "book? відхиляє довгий список"
                  (book? (list 'book "t" "a" 1 'g 'extra)))
     (check-false "book? відхиляє чужий тег"
                  (book? (list 'film "t" "a" 1 'g)))
     (check-false "book? відхиляє не-рядок у назві"
                  (book? (list 'book 7 "a" 1 'g)))
     (check-false "book? відхиляє не-цілий рік"
                  (book? (list 'book "t" "a" "1965" 'g)))
     (check-false "book? відхиляє не-символ у жанрі"
                  (book? (list 'book "t" "a" 1 "g")))

     ;; book=? — за полями, не за ідентичністю об'єкта
     (check-true  "book=? рефлексивне"           (book=? dune dune))
     (check-true  "book=? порівнює поля"         (book=? dune dune-copy))
     (check-true  "book=? симетричне"            (book=? dune-copy dune))
     (check-false "book=? різне за назвою"
                  (book=? dune (make-book "Done" "Frank Herbert" 1965 'sci-fi)))
     (check-false "book=? різне за автором"
                  (book=? dune (make-book "Dune" "F. Herbert" 1965 'sci-fi)))
     (check-false "book=? різне за роком"
                  (book=? dune (make-book "Dune" "Frank Herbert" 1966 'sci-fi)))
     (check-false "book=? різне за жанром"
                  (book=? dune (make-book "Dune" "Frank Herbert" 1965 'classic)))

     ;; порожні та крайні значення — звичайні дані
     (check "порожня назва"   ""     (book-title empties))
     (check "порожній автор"  ""     (book-author empties))
     (check "рік нуль"        0      (book-year empties))
     (check-true "книга з порожніми полями все ще книга" (book? empties))
     (check "від'ємний рік"   -750   (book-year ancient))

     ;; book->string
     (check "book->string містить усі поля"
            "Dune — Frank Herbert (1965) [sci-fi]"
            (book->string dune))
     (check "book->string з від'ємним роком"
            "The Iliad — Homer (-750) [epic]"
            (book->string ancient)))))