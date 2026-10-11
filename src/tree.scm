;;; tree.scm — І5. Дерево категорій: додавання, пошук, обхід
;;; Вузол: (category name child ...). Дитина — книга або вузол.

;; make-category : String (listof Element) -> Node
(define (make-category name children)
  (cons 'category (cons name children)))

;; empty-tree : String -> Node
(define (empty-tree name)
  (make-category name '()))

;; category-name     : Node -> String
;; category-children : Node -> (listof Element)
(define (category-name node) (cadr node))
(define (category-children node) (cddr node))

;; category? : Any -> Boolean
(define (category? x)
  (and (pair? x)
       (eq? (car x) 'category)
       (pair? (cdr x))
       (string? (cadr x))
       (list? (cddr x))))

;; find-child : String (listof Element) -> Node | #f
(define (find-child name children)
  (cond ((null? children) #f)
        ((and (category? (car children))
              (string=? (category-name (car children)) name))
         (car children))
        (else (find-child name (cdr children)))))

;; replace-child : Node (listof Element) -> (listof Element)
(define (replace-child new-node children)
  (cond ((null? children) (list new-node))
        ((and (category? (car children))
              (string=? (category-name (car children))
                        (category-name new-node)))
         (cons new-node (cdr children)))
        (else
         (cons (car children)
               (replace-child new-node (cdr children))))))

;; tree-add-category : Node (listof String) String -> Node
;; path — імена категорій від цього вузла вниз.
(define (tree-add-category node path new-name)
  (if (null? path)
      (if (find-child new-name (category-children node))
          node
          (make-category (category-name node)
                         (append (category-children node)
                                 (list (empty-tree new-name)))))
      (let* ((step (car path))
             (child (find-child step (category-children node)))
             (child (if child child (empty-tree step)))
             (updated (tree-add-category child (cdr path) new-name)))
        (make-category (category-name node)
                       (replace-child updated
                                      (category-children node))))))

;; tree-add-book : Node (listof String) Book -> Node
(define (tree-add-book node path book)
  (if (null? path)
      (make-category (category-name node)
                     (append (category-children node) (list book)))
      (let* ((step (car path))
             (child (find-child step (category-children node)))
             (child (if child child (empty-tree step)))
             (updated (tree-add-book child (cdr path) book)))
        (make-category (category-name node)
                       (replace-child updated
                                      (category-children node))))))

;; tree-remove-book : Node Book -> Node
;; Прибирає з дерева всі книги, рівні book за book=?.
(define (tree-remove-book node book)
  (make-category
   (category-name node)
   (let loop ((children (category-children node)))
     (cond ((null? children) '())
           ((book? (car children))
            (if (book=? (car children) book)
                (loop (cdr children))
                (cons (car children) (loop (cdr children)))))
           (else
            (cons (tree-remove-book (car children) book)
                  (loop (cdr children))))))))

;; drop-category : String (listof Element) -> (listof Element)
;; Прибирає першу дочірню категорію з таким ім'ям.
(define (drop-category name children)
  (cond ((null? children) '())
        ((and (category? (car children))
              (string=? (category-name (car children)) name))
         (cdr children))
        (else
         (cons (car children)
               (drop-category name (cdr children))))))

;; tree-remove-category : Node (listof String) -> Node
;; path — шлях від цього вузла до категорії, яку треба прибрати.
;; Порожній path не змінює дерево (корінь не видаляємо).
(define (tree-remove-category node path)
  (cond ((null? path) node)
        ((null? (cdr path))
         (make-category (category-name node)
                        (drop-category (car path)
                                       (category-children node))))
        (else
         (let ((child (find-child (car path)
                                  (category-children node))))
           (if child
               (make-category
                (category-name node)
                (replace-child
                 (tree-remove-category child (cdr path))
                 (category-children node)))
               node)))))

;; tree-books : Node -> (listof Book)
;; Рекурсивний обхід: книги вузла і всіх підкатегорій.
(define (tree-books node)
  (let loop ((children (category-children node)))
    (cond ((null? children) '())
          ((book? (car children))
           (cons (car children) (loop (cdr children))))
          (else
           (append (tree-books (car children))
                   (loop (cdr children)))))))

;; tree-search : (Book -> Boolean) Node -> (listof Book)
(define (tree-search pred node)
  (my-filter pred (tree-books node)))

;; tree->catalog : Node -> Catalog
(define (tree->catalog node)
  (catalog-from-list (tree-books node)))