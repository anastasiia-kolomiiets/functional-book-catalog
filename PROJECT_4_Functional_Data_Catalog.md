# Project 4 — Functional Data Catalog

**Course:** Functional Programming
**Language:** Scheme (R7RS-small; R5RS-compatible subset — runnable under Racket, Guile, Chez, Chicken, MIT/GNU Scheme)
**Deliverable:** A modular, incrementally built functional information system
**Structure:** 8 graded iterations + final integration

---

## 1. Overview

In this project you will build a **data catalog** — a small, domain-driven information
system — entirely in Scheme, in a **pure functional** style.

The running domain used throughout this document is a **library catalog of books**, where
each book carries a *title*, *author*, *year*, and *genre*. You may substitute a different
domain (a music catalog, a film archive, a museum inventory, a parts catalog for a
warehouse), provided it has **at least four attributes**, of which at least one is
**numeric** (needed for aggregation in Iteration 4) and at least one is **categorical**
(needed for grouping and for the tree in Iteration 5).

The project is deliberately **incremental**. Each iteration adds exactly one new
abstraction, and — crucially — *each iteration is built on the **interface** of the
previous one, never on its **representation***. By the end you will have travelled the
full arc of functional data design:

```
   field  →  record  →  list  →  higher-order search  →  pipeline
                                        │
                                        ▼
                          tree  →  table/index  →  I/O  →  integrated system
```

### 1.1 Core concepts exercised

| Concept | Introduced in |
|---|---|
| Data abstraction; constructors, selectors, abstraction barriers | Iteration 1 |
| Structural recursion over lists; persistent (non-destructive) update | Iteration 2 |
| Higher-order procedures; procedures as first-class values; `lambda`; closures | Iteration 3 |
| `map` / `filter` / `fold` as the algebra of sequences | Iteration 4 |
| Recursive, non-linear data; mutual recursion over trees | Iteration 5 |
| Association lists and tables; keys, indices, and lookup cost | Iteration 6 |
| Ports; external representation; serialization round-trips | Iteration 7 |
| Procedure composition; layered architecture; modularity | Iteration 8 |

### 1.2 Learning outcomes

On completion you will be able to:

1. Design a data abstraction and defend its **abstraction barrier**.
2. Write structurally recursive procedures whose shape follows the shape of the data.
3. Replace a family of near-identical procedures with a single higher-order procedure.
4. Express collection processing as a **pipeline** of `map`, `filter`, and `fold`.
5. Generalize recursion from lists to trees.
6. Choose between linear search and an index, and articulate the trade-off.
7. Serialize and deserialize a data structure through Scheme ports.
8. Assemble all of the above into a layered program in which each layer depends only on
   the layer beneath it.

---

## 2. Ground Rules

These rules apply to **every** iteration and are part of the grade.

### R1 — Purity

Procedures must be **pure**: the same arguments always yield the same result, and no
observable side effect occurs. There are exactly three sanctioned exceptions:

* File I/O in Iteration 7, confined to `io.scm`.
* Printing in the user-facing layer of Iteration 8, confined to `main.scm`.
* `display` / `newline` inside the test runner.

### R2 — No mutation

`set!`, `set-car!`, `set-cdr!`, `string-set!`, `vector-set!`, and hash-table mutation
(`hash-table-set!`, `hash-set!`, …) are **forbidden** in the core layers
(`book.scm`, `catalog.scm`, `search.scm`, `pipeline.scm`, `tree.scm`, `index.scm`).

"Updating" a catalog means **returning a new catalog**. The old value remains valid:

```scheme
(define c1 (catalog-add b1 (empty-catalog)))
(define c2 (catalog-add b2 c1))
;; c1 is STILL a one-book catalog. Nothing was destroyed.
```

This property is called **persistence**, and it is the single most important habit this
project teaches. It is what makes the code trivially testable, trivially parallelizable,
and trivially undoable.

### R3 — Respect abstraction barriers

Above Iteration 1, the operators `car`, `cdr`, `cadr`, `caddr`, and `list-ref` must
**never** be applied to a book. Only `book-title`, `book-author`, … may be.

> **Grading note.** A grader will replace the internal representation of a book (for
> example, a list becomes a vector) by editing `book.scm` **only**, then re-run your
> Iteration 4 tests. They must still pass, unmodified. If they do not, you have leaked
> the representation.

### R4 — Naming conventions

| Form | Meaning | Example |
|---|---|---|
| `make-X` | constructor | `make-book` |
| `X-field` | selector | `book-year` |
| `X?` | predicate returning `#t`/`#f` | `book?`, `catalog-empty?` |
| `X->Y` | total conversion | `book->string`, `catalog->list` |
| `X-with-field` | persistent update, returns a new value | `book-with-genre` |
| `X/helper` | module-private helper | `catalog/insert-sorted` |

Use `kebab-case`. Never use `_` in identifiers. Name a predicate argument `pred`; a
procedural argument `proc`, `f`, or `key-fn`.

### R5 — Recursion discipline

* Prefer **structural recursion**: one clause per constructor of the data type — for
  lists, the empty case and the `cons` case.
* Prefer **tail recursion with an accumulator** where the result is a scalar (counts,
  sums, extrema) and where order does not matter.
* Use a **named `let`** for a local loop rather than a top-level helper that pollutes the
  namespace:

```scheme
(define (catalog-count catalog)
  (let loop ((items catalog) (n 0))
    (if (null? items)
        n
        (loop (cdr items) (+ n 1)))))
```

### R6 — Documentation

Every exported procedure carries a comment block giving a **contract** (types in, type
out), a **purpose** statement, and — where the behaviour is not obvious — an **example**:

```scheme
;; catalog-count : Catalog -> Integer
;; Returns the number of entries in CATALOG.
;; (catalog-count (list b1 b2)) => 2
```

Write the contract **before** the body. It is a design tool, not decoration.

---

## 3. Suggested Project File Structure

```
project4/
├── README.md                 ; how to build and run; domain description; design notes
├── src/
│   ├── book.scm              ; Iteration 1 — the domain record
│   ├── catalog.scm           ; Iteration 2 — list-based collection
│   ├── search.scm            ; Iteration 3 — higher-order search, predicate combinators
│   ├── pipeline.scm          ; Iteration 4 — map/filter/fold utilities, aggregations
│   ├── tree.scm              ; Iteration 5 — hierarchical category tree
│   ├── index.scm             ; Iteration 6 — association-list / table indices
│   ├── sort.scm              ; Iteration 8 — merge sort, grouping
│   ├── io.scm                ; Iteration 7 — persistence and reporting
│   └── main.scm              ; Iteration 8 — application layer, demo / menu
├── test/
│   ├── test-framework.scm    ; the tiny test harness (Section 5)
│   ├── test-book.scm
│   ├── test-catalog.scm
│   ├── test-search.scm
│   ├── test-pipeline.scm
│   ├── test-tree.scm
│   ├── test-index.scm
│   ├── test-io.scm
│   ├── test-main.scm
│   └── run-all.scm           ; loads every source file and every suite
└── data/
    ├── sample-catalog.txt    ; seed dataset (Appendix A)
    ├── catalog.db            ; produced by Iteration 7 — do not hand-edit
    └── report.txt            ; produced by Iteration 7/8
```

**Dependency rule (enforced at grading).** A file may `load` only files to its *left* in
this chain. A cycle is a design error.

```
book ← catalog ← search ← pipeline ← tree ← index ← sort ← io ← main
```

---

## 4. Environment and Running the Code

### 4.1 Racket

Put one of these at the top of each source file:

```scheme
#lang r7rs
(import (scheme base) (scheme write) (scheme file))
```

```scheme
#lang r5rs
```

Run a suite with:

```
racket test/run-all.scm
```

### 4.2 Guile, Chez, Chicken, MIT Scheme

Plain `load` is the most portable choice. `test/run-all.scm`:

```scheme
(load "src/book.scm")
(load "src/catalog.scm")
;; ... in dependency order ...
(load "test/test-framework.scm")
(load "test/test-book.scm")
(load "test/test-catalog.scm")
(run-all-suites)
```

```
guile  -l test/run-all.scm
chez   --script test/run-all.scm
mit-scheme --quiet < test/run-all.scm
```

### 4.3 Portability notes — read before writing a single line

Scheme is standardized but small. The following are **not** in R5RS / R7RS-small and must
be **implemented by you**, not imported. Implementing them *is* the exercise.

| Procedure | Status | Action |
|---|---|---|
| `filter` | SRFI-1 / Racket only | implement (Iteration 4) |
| `fold-left`, `fold-right` | R6RS / SRFI-1 | implement (Iteration 4) |
| `reduce`, `remove`, `delete` | SRFI-1 | implement |
| `sort` | implementation-specific | implement merge sort (Iteration 8) |
| `assoc` with a 3rd argument | R7RS only | write `assoc-by` yourself |
| `string-split`, `string-join` | not standard | implement in `io.scm` if you need them |
| hash tables | SRFI-69 / R6RS / host-specific | optional; association lists are the default |

`map`, `for-each`, `assoc`, `assq`, `member`, `memq`, `append`, `reverse`, `length`,
`list-tail`, `apply`, `number->string`, `string->number`, `read`, `write`, and `display`
**are** standard, and you may use them freely.

> If your Scheme already provides `filter` or `fold-left`, define yours under a prefixed
> name (`cat-filter`, `cat-fold-left`) to avoid clashing with the built-in, or wrap the
> definitions so the graders can see your implementation.

---

## 5. The Test Harness

Testing is graded. Write the tests for an iteration **before or alongside** the code.

Because Rule R2 forbids mutation, the harness does not accumulate pass/fail counts in a
mutable counter. Instead, each check **returns a result value**, and a fold reduces the
list of results to a summary. The harness is therefore itself a small exercise in the
style this project teaches.

Create `test/test-framework.scm`:

```scheme
;;; test-framework.scm — a small, purely functional test harness.
;;; A Result is (list name passed? expected actual).

;; check : String Any Any -> Result
;; Compares ACTUAL against EXPECTED using EQUAL?.
(define (check name expected actual)
  (list name (equal? expected actual) expected actual))

;; check-true : String Any -> Result
(define (check-true  name actual) (check name #t (if actual #t #f)))
;; check-false : String Any -> Result
(define (check-false name actual) (check name #f (if actual #t #f)))

(define (result-name     r) (car r))
(define (result-passed?  r) (cadr r))
(define (result-expected r) (caddr r))
(define (result-actual   r) (cadddr r))

;; report-result : Result -> unspecified   (the only impure procedure here)
(define (report-result r)
  (if (result-passed? r)
      (begin (display "  PASS  ") (display (result-name r)) (newline))
      (begin (display "  FAIL  ") (display (result-name r)) (newline)
             (display "        expected: ") (write (result-expected r)) (newline)
             (display "        actual:   ") (write (result-actual   r)) (newline))))

;; count-passed : (listof Result) -> Integer
(define (count-passed results)
  (let loop ((rs results) (n 0))
    (cond ((null? rs) n)
          ((result-passed? (car rs)) (loop (cdr rs) (+ n 1)))
          (else (loop (cdr rs) n)))))

;; run-suite : String (listof Result) -> Integer   ; returns the number of failures
(define (run-suite title results)
  (display "== ") (display title) (newline)
  (for-each report-result results)
  (let ((total (length results))
        (passed (count-passed results)))
    (display "   ") (display passed) (display "/") (display total)
    (display " passed") (newline) (newline)
    (- total passed)))
```

A suite is then simply a **list of results** — data, not statements:

```scheme
;;; test/test-book.scm
(define (book-tests)
  (let ((b (make-book "Dune" "Frank Herbert" 1965 'sci-fi)))
    (list (check "title"  "Dune"          (book-title  b))
          (check "author" "Frank Herbert" (book-author b))
          (check "year"   1965            (book-year   b))
          (check "genre"  'sci-fi         (book-genre  b))
          (check-true  "book? accepts a book"   (book? b))
          (check-false "book? rejects a string" (book? "Dune")))))
```

and `test/run-all.scm` ends with:

```scheme
(define (run-all-suites)
  (let ((failures (+ (run-suite "Iteration 1 — book"     (book-tests))
                     (run-suite "Iteration 2 — catalog"  (catalog-tests))
                     (run-suite "Iteration 3 — search"   (search-tests))
                     (run-suite "Iteration 4 — pipeline" (pipeline-tests))
                     (run-suite "Iteration 5 — tree"     (tree-tests))
                     (run-suite "Iteration 6 — index"    (index-tests))
                     (run-suite "Iteration 7 — io"       (io-tests))
                     (run-suite "Iteration 8 — system"   (system-tests)))))
    (display "TOTAL FAILURES: ") (display failures) (newline)))
```

**Testing requirement for every iteration:** at least **six checks**, covering
(a) the ordinary case, (b) the **empty** case, (c) the **absent / not-found** case, and
(d) one **boundary** case (a single element, duplicate keys, the deepest tree node, …).

---

# Iteration 1 — Object Representation (Data Abstraction)

## 1.1 Goal and Core Concepts

**Goal.** Model one domain entity — a *book* — as an abstract data type, so that every
later iteration manipulates books through named operations and never through `car`/`cdr`.

**Core concepts.** Pairs and `cons`; compound data; constructors and selectors; the
**abstraction barrier**; tagged data; total vs. partial procedures.

The central idea of this iteration is due to Abelson & Sussman: a data abstraction is
defined not by how it is stored, but by the **contract between its constructor and its
selectors**. That contract is:

> For any `t`, `a`, `y`, `g`, if `b` is `(make-book t a y g)`, then
> `(book-title b)` is `t`, `(book-author b)` is `a`, `(book-year b)` is `y`, and
> `(book-genre b)` is `g`.

Anything satisfying that contract is a correct implementation. Nothing else about the
representation may be relied upon anywhere else in the program.

## 1.2 Detailed Instructions

Create `src/book.scm`. Implement the following, in this order.

### Required procedures

```scheme
;; make-book : String String Integer Symbol -> Book
(make-book title author year genre)

;; book-title  : Book -> String
;; book-author : Book -> String
;; book-year   : Book -> Integer
;; book-genre  : Book -> Symbol
(book-title  b)
(book-author b)
(book-year   b)
(book-genre  b)

;; book? : Any -> Boolean
;;   Recognizes values produced by MAKE-BOOK. Must not raise an error on any input.
(book? x)

;; book=? : Book Book -> Boolean
;;   Structural equality on all four fields.
(book=? b1 b2)

;; book->string : Book -> String
;;   A single-line human-readable rendering.
(book->string b)

;; book-with-genre : Book Symbol -> Book
;; book-with-year  : Book Integer -> Book
;;   Persistent update: returns a NEW book; the argument is unchanged.
(book-with-genre b g)
(book-with-year  b y)
```

### Step 1 — choose a representation

Three representations are acceptable. Pick one and justify it in `README.md`.

**(a) Nested pairs.** Closest to the primitives; good for showing you understand `cons`.

```scheme
(define (make-book title author year genre)
  (cons (cons title author) (cons year genre)))

(define (book-title  b) (car (car b)))
(define (book-author b) (cdr (car b)))
(define (book-year   b) (car (cdr b)))
(define (book-genre  b) (cdr (cdr b)))
```

**(b) Tagged list — recommended.** Extensible, printable, and directly serializable in
Iteration 7.

```scheme
(define book-tag 'book)

;; make-book : String String Integer Symbol -> Book
;; Builds a book record.
(define (make-book title author year genre)
  (list book-tag title author year genre))

(define (book-title  b) (list-ref b 1))
(define (book-author b) (list-ref b 2))
(define (book-year   b) (list-ref b 3))
(define (book-genre  b) (list-ref b 4))
```

**(c) Message-passing closure.** The most "functional" of the three: the record *is* a
procedure. Note that it cannot be `write`n directly, so Iteration 7 will need an explicit
`book->sexp` conversion.

```scheme
(define (make-book title author year genre)
  (lambda (field)
    (cond ((eq? field 'title)  title)
          ((eq? field 'author) author)
          ((eq? field 'year)   year)
          ((eq? field 'genre)  genre)
          (else (error "make-book: unknown field" field)))))

(define (book-title b) (b 'title))
```

### Step 2 — write the recognizer

`book?` must be **total**: it returns `#f` rather than raising an error for *any* input,
including `'()`, a number, a string, or a two-element list. With representation (b):

```scheme
;; book? : Any -> Boolean
;; True exactly for values produced by MAKE-BOOK.
(define (book? x)
  (and (pair? x)
       (list? x)
       (= (length x) 5)
       (eq? (car x) book-tag)
       (string? (list-ref x 1))
       (string? (list-ref x 2))
       (integer? (list-ref x 3))
       (symbol? (list-ref x 4))))
```

### Step 3 — persistent update

Note that `book-with-genre` is written **entirely in terms of the interface**. It would
survive a change of representation untouched:

```scheme
;; book-with-genre : Book Symbol -> Book
;; Returns a copy of B whose genre is G. B itself is unchanged.
(define (book-with-genre b g)
  (make-book (book-title b) (book-author b) (book-year b) g))
```

### Step 4 — rendering

```scheme
;; book->string : Book -> String
;; "Dune — Frank Herbert (1965) [sci-fi]"
(define (book->string b)
  (string-append (book-title b)
                 " — " (book-author b)
                 " (" (number->string (book-year b)) ")"
                 " [" (symbol->string (book-genre b)) "]"))
```

## 1.3 Example Usage

```scheme
(define dune (make-book "Dune" "Frank Herbert" 1965 'sci-fi))

(book-title dune)                       ; => "Dune"
(book-year  dune)                       ; => 1965
(book? dune)                            ; => #t
(book? "Dune")                          ; => #f
(book? '())                             ; => #f

(define dune2 (book-with-genre dune 'classic))
(book-genre dune2)                      ; => classic
(book-genre dune)                       ; => sci-fi     <- unchanged: persistence
(book=? dune dune2)                     ; => #f

(display (book->string dune))
;; Dune — Frank Herbert (1965) [sci-fi]
```

## 1.4 Acceptance Criteria

| # | Criterion |
|---|---|
| 1.1 | `make-book` and all four selectors exist and satisfy the constructor/selector contract for arbitrary field values. |
| 1.2 | `book?` is total: it returns `#f`, never an error, for `'()`, `42`, `"x"`, `'(1 2 3)`, `#t`. |
| 1.3 | `book=?` is reflexive, symmetric, and false for books differing in any single field. |
| 1.4 | `book-with-genre` / `book-with-year` return new books and leave the original unchanged (verified by a test that inspects the original afterwards). |
| 1.5 | `book->string` includes all four fields. |
| 1.6 | No code outside `book.scm` uses `car`, `cdr`, or `list-ref` on a book. |
| 1.7 | Every exported procedure carries a contract comment (Rule R6). |
| 1.8 | `test-book.scm` contains at least 6 checks and all pass. |

**Self-check.** Swap representation (b) for representation (a) in `book.scm` alone.
If `test-book.scm` still passes without edits, your barrier is sound.

## 1.5 Common Pitfalls

* **Leaking the representation** by writing `(cadr b)` in `catalog.scm`. This is the most
  commonly lost mark in the entire project.
* Making `book?` partial — `(length x)` raises an error on an improper list, so guard with
  `list?` first.
* Using `eq?` to compare strings. `(eq? "Dune" "Dune")` is **unspecified** in Scheme. Use
  `string=?` for strings, `eq?` for symbols, `=` for numbers, `equal?` for structures.

---

# Iteration 2 — Object Collection

## 2.1 Goal and Core Concepts

**Goal.** Represent the whole catalog as a list of books, and implement the four basic
collection operations — add, find, remove, count — by **structural recursion**.

**Core concepts.** Lists as recursively defined data; the two-case recursion template;
persistent (non-destructive) insertion and deletion; tail recursion and accumulators;
linear-time search.

A list obeys the grammar

```
<list-of-Book> ::= ()                                 ; the empty list
                 | (cons <Book> <list-of-Book>)       ; a book followed by a list
```

and therefore **every** procedure over a list has the same skeleton — one clause per
production:

```scheme
(define (proc-over-list lst)
  (if (null? lst)
      <answer-for-the-empty-list>
      <combine (car lst) with (proc-over-list (cdr lst))>))
```

Internalize this template. Iterations 2, 4, and 5 are all instances of it.

## 2.2 Detailed Instructions

Create `src/catalog.scm`, which `load`s `book.scm`.

### Required procedures

```scheme
;; empty-catalog : -> Catalog
(empty-catalog)

;; catalog-empty? : Catalog -> Boolean
(catalog-empty? catalog)

;; catalog-add : Book Catalog -> Catalog
;;   Returns a new catalog containing BOOK in addition to the entries of CATALOG.
(catalog-add book catalog)

;; catalog-count : Catalog -> Integer
;;   Number of entries. Must be tail-recursive.
(catalog-count catalog)

;; catalog-find-by-title : String Catalog -> Book | #f
;;   The first book whose title matches; #f when absent.
(catalog-find-by-title title catalog)

;; catalog-contains? : String Catalog -> Boolean
(catalog-contains? title catalog)

;; catalog-remove-by-title : String Catalog -> Catalog
;;   A new catalog without any book of that title. Removing an absent title is a no-op.
(catalog-remove-by-title title catalog)

;; catalog-titles : Catalog -> (listof String)
(catalog-titles catalog)

;; catalog-from-list : (listof Book) -> Catalog
(catalog-from-list books)

;; catalog->list : Catalog -> (listof Book)
(catalog->list catalog)
```

### Step 1 — constructor and recognizer

Keep them trivial but *named*. Naming them is what lets you change the representation
later (to a sorted list, a tree, or a record holding a list plus a cached count) without
touching any caller.

```scheme
;; empty-catalog : -> Catalog
(define (empty-catalog) '())

;; catalog-empty? : Catalog -> Boolean
(define (catalog-empty? catalog) (null? catalog))
```

### Step 2 — insertion

Insertion at the front is O(1) and is the natural functional choice:

```scheme
;; catalog-add : Book Catalog -> Catalog
;; Returns a new catalog with BOOK added. CATALOG is unchanged.
(define (catalog-add book catalog)
  (cons book catalog))
```

If you prefer to keep the catalog sorted by title, write `catalog-add` recursively
instead — this is the standard persistent-insertion pattern, and note how the `cons` on
the way *out* of the recursion rebuilds only the prefix of the list:

```scheme
(define (catalog-add book catalog)
  (cond ((catalog-empty? catalog) (list book))
        ((string<? (book-title book) (book-title (car catalog)))
         (cons book catalog))
        (else
         (cons (car catalog) (catalog-add book (cdr catalog))))))
```

### Step 3 — counting (tail recursive)

```scheme
;; catalog-count : Catalog -> Integer
;; Number of books in CATALOG.
(define (catalog-count catalog)
  (let loop ((items catalog) (n 0))
    (if (null? items)
        n
        (loop (cdr items) (+ n 1)))))
```

The accumulator `n` carries the answer *forward*, so the recursive call is in tail
position and the process runs in constant space. Contrast with the non-tail version
`(+ 1 (catalog-count (cdr catalog)))`, which builds a chain of pending additions.

### Step 4 — search

Return the book itself, not `#t`. A procedure that returns *the thing you were looking
for* composes; one that returns a boolean does not. Use `#f` as the "absent" answer —
the standard Scheme idiom, and safe here because a book is never `#f`.

```scheme
;; catalog-find-by-title : String Catalog -> Book | #f
;; The first book in CATALOG titled TITLE, or #f if none.
(define (catalog-find-by-title title catalog)
  (cond ((catalog-empty? catalog) #f)
        ((string=? title (book-title (car catalog))) (car catalog))
        (else (catalog-find-by-title title (cdr catalog)))))

;; catalog-contains? : String Catalog -> Boolean
(define (catalog-contains? title catalog)
  (if (catalog-find-by-title title catalog) #t #f))
```

### Step 5 — removal

Removal is the canonical demonstration of persistence: the result **shares** the tail of
the original list from the removal point onwards, and copies only the prefix.

```scheme
;; catalog-remove-by-title : String Catalog -> Catalog
;; A new catalog with every book titled TITLE omitted.
(define (catalog-remove-by-title title catalog)
  (cond ((catalog-empty? catalog) (empty-catalog))
        ((string=? title (book-title (car catalog)))
         (catalog-remove-by-title title (cdr catalog)))
        (else
         (cons (car catalog)
               (catalog-remove-by-title title (cdr catalog))))))
```

### Step 6 — projection

```scheme
;; catalog-titles : Catalog -> (listof String)
(define (catalog-titles catalog)
  (if (catalog-empty? catalog)
      '()
      (cons (book-title (car catalog))
            (catalog-titles (cdr catalog)))))
```

Write this one by hand now. In Iteration 4 you will delete the body and replace it with
`(map book-title catalog)` — and you should be able to explain precisely why the two are
the same computation.

## 2.3 Example Usage

```scheme
(define b1 (make-book "Dune"            "Frank Herbert"   1965 'sci-fi))
(define b2 (make-book "Neuromancer"     "William Gibson"  1984 'cyberpunk))
(define b3 (make-book "Foundation"      "Isaac Asimov"    1951 'sci-fi))

(define cat0 (empty-catalog))
(define cat1 (catalog-add b1 cat0))
(define cat2 (catalog-add b2 cat1))
(define cat3 (catalog-add b3 cat2))

(catalog-count cat3)                                 ; => 3
(catalog-count cat1)                                 ; => 1   <- cat1 was not mutated
(catalog-empty? cat0)                                ; => #t

(book-author (catalog-find-by-title "Dune" cat3))    ; => "Frank Herbert"
(catalog-find-by-title "Missing" cat3)               ; => #f
(catalog-contains? "Neuromancer" cat3)               ; => #t

(catalog-count (catalog-remove-by-title "Dune" cat3))          ; => 2
(catalog-count (catalog-remove-by-title "Nothing Here" cat3))  ; => 3
(catalog-count cat3)                                           ; => 3  <- still intact

(catalog-titles cat3)
;; => ("Foundation" "Neuromancer" "Dune")
```

## 2.4 Acceptance Criteria

| # | Criterion |
|---|---|
| 2.1 | All ten listed procedures are implemented with contract comments. |
| 2.2 | Every procedure handles the empty catalog correctly without error. |
| 2.3 | `catalog-add` and `catalog-remove-by-title` are non-destructive — a test must confirm the original catalog is unchanged afterwards. |
| 2.4 | `catalog-count` is tail recursive (a named `let` or a helper with an accumulator). |
| 2.5 | `catalog-find-by-title` returns `#f`, not an error, for an absent title. |
| 2.6 | Removing an absent title returns an equal catalog. |
| 2.7 | Nothing in `catalog.scm` accesses a book except through Iteration 1 selectors. |
| 2.8 | `test-catalog.scm` contains at least 6 checks — including empty, absent, and single-element cases — and all pass. |

## 2.5 Common Pitfalls

* **Losing the result.** `(catalog-add b c)` does nothing on its own; you must bind or use
  its value. Students accustomed to imperative languages write `(catalog-add b c)` as a
  statement and then wonder why `c` is unchanged. In this language, *the value is the
  update*.
* Forgetting the `cons` in the `else` branch of `catalog-remove-by-title`, which silently
  drops every book before the match.
* Returning `'()` instead of `#f` from `catalog-find-by-title`. `'()` is truthy in Scheme —
  **only `#f` is false** — so `(if (catalog-find-by-title …) …)` would then always take the
  true branch.

---

# Iteration 3 — Search as a Higher-Order Function

## 3.1 Goal and Core Concepts

**Goal.** Collapse the growing family of `catalog-find-by-title`,
`catalog-find-by-author`, `catalog-find-by-year`, … into **one** search procedure
parameterized by a predicate.

**Core concepts.** Procedures as first-class values; higher-order procedures; `lambda`;
**closures** (a lambda capturing a free variable from its enclosing scope); combinator
design.

Look hard at the two procedures below:

```scheme
(define (catalog-find-by-title title catalog)
  (cond ((null? catalog) #f)
        ((string=? title (book-title (car catalog))) (car catalog))
        (else (catalog-find-by-title title (cdr catalog)))))

(define (catalog-find-by-author author catalog)
  (cond ((null? catalog) #f)
        ((string=? author (book-author (car catalog))) (car catalog))
        (else (catalog-find-by-author author (cdr catalog)))))
```

They are identical except for one expression: the **test**. In a language with
first-class procedures, whatever differs can be made a parameter. That is the whole
content of this iteration — and it is the same insight that produces `map`, `filter`,
`fold`, and every design pattern named after it in other languages.

## 3.2 Detailed Instructions

Create `src/search.scm`.

### Required procedures

```scheme
;; search-catalog : (Book -> Boolean) Catalog -> (listof Book)
;;   ALL books satisfying PRED, in original order.
(search-catalog pred catalog)

;; find-first : (Book -> Boolean) Catalog -> Book | #f
(find-first pred catalog)

;; count-matching : (Book -> Boolean) Catalog -> Integer
(count-matching pred catalog)

;; any-match? : (Book -> Boolean) Catalog -> Boolean
;; all-match? : (Book -> Boolean) Catalog -> Boolean
(any-match? pred catalog)
(all-match? pred catalog)

;;; --- predicate constructors (each RETURNS a predicate) ---
;; by-author : String -> (Book -> Boolean)
;; by-genre  : Symbol -> (Book -> Boolean)
;; by-year   : Integer -> (Book -> Boolean)
;; year-between : Integer Integer -> (Book -> Boolean)
;; title-contains : String -> (Book -> Boolean)
(by-author author)
(by-genre  genre)
(by-year   year)
(year-between from to)
(title-contains substring)

;;; --- predicate combinators (each TAKES and RETURNS predicates) ---
;; p-and : (Book -> Boolean) ... -> (Book -> Boolean)
;; p-or  : (Book -> Boolean) ... -> (Book -> Boolean)
;; p-not : (Book -> Boolean) -> (Book -> Boolean)
(p-and p1 p2 ...)
(p-or  p1 p2 ...)
(p-not p)
```

### Step 1 — the generic search

```scheme
;; search-catalog : (Book -> Boolean) Catalog -> (listof Book)
;; Every book in CATALOG for which (PRED book) is true, in order.
;; (search-catalog (by-genre 'sci-fi) cat) => (b1 b3)
(define (search-catalog pred catalog)
  (cond ((null? catalog) '())
        ((pred (car catalog))
         (cons (car catalog) (search-catalog pred (cdr catalog))))
        (else
         (search-catalog pred (cdr catalog)))))
```

Observe: `pred` is *called* as a procedure in the test position. Nothing else changed
from Iteration 2. You have just written `filter`, specialized to books — which is why
Iteration 4 will generalize it one step further.

### Step 2 — the rest of the search family

```scheme
;; find-first : (Book -> Boolean) Catalog -> Book | #f
(define (find-first pred catalog)
  (cond ((null? catalog) #f)
        ((pred (car catalog)) (car catalog))
        (else (find-first pred (cdr catalog)))))

;; count-matching : (Book -> Boolean) Catalog -> Integer
(define (count-matching pred catalog)
  (let loop ((items catalog) (n 0))
    (cond ((null? items) n)
          ((pred (car items)) (loop (cdr items) (+ n 1)))
          (else (loop (cdr items) n)))))

;; any-match? : (Book -> Boolean) Catalog -> Boolean
(define (any-match? pred catalog)
  (if (find-first pred catalog) #t #f))

;; all-match? : (Book -> Boolean) Catalog -> Boolean
;; Vacuously true for the empty catalog.
(define (all-match? pred catalog)
  (not (any-match? (lambda (b) (not (pred b))) catalog)))
```

Note that `all-match?` is defined by De Morgan's law over `any-match?` — no new recursion
is needed. Prefer this kind of derivation to a fresh loop.

### Step 3 — predicate constructors (closures)

Each of these **returns a procedure**. The returned lambda captures the argument of the
outer procedure: that captured binding is the *closure*.

```scheme
;; by-author : String -> (Book -> Boolean)
;; Builds a predicate true of books written by AUTHOR.
(define (by-author author)
  (lambda (b) (string=? (book-author b) author)))

;; by-genre : Symbol -> (Book -> Boolean)
(define (by-genre genre)
  (lambda (b) (eq? (book-genre b) genre)))

;; by-year : Integer -> (Book -> Boolean)
(define (by-year year)
  (lambda (b) (= (book-year b) year)))

;; year-between : Integer Integer -> (Book -> Boolean)
;; Inclusive on both ends.
(define (year-between from to)
  (lambda (b) (and (>= (book-year b) from)
                   (<= (book-year b) to))))
```

`title-contains` needs a substring test, which is not standard. Implement it:

```scheme
;; string-prefix-at? : String String Integer -> Boolean
(define (string-prefix-at? needle haystack i)
  (let ((n (string-length needle)))
    (let loop ((k 0))
      (cond ((= k n) #t)
            ((char=? (string-ref needle k) (string-ref haystack (+ i k)))
             (loop (+ k 1)))
            (else #f)))))

;; string-contains? : String String -> Boolean
(define (string-contains? haystack needle)
  (let ((h (string-length haystack)) (n (string-length needle)))
    (let loop ((i 0))
      (cond ((> (+ i n) h) #f)
            ((string-prefix-at? needle haystack i) #t)
            (else (loop (+ i 1)))))))

;; title-contains : String -> (Book -> Boolean)
(define (title-contains sub)
  (lambda (b) (string-contains? (book-title b) sub)))
```

### Step 4 — combinators

Combinators take predicates and build predicates. Variadic versions using `fold` over the
argument list are elegant; a fixed-arity version is acceptable if you document it.

```scheme
;; p-not : (Book -> Boolean) -> (Book -> Boolean)
(define (p-not p)
  (lambda (b) (not (p b))))

;; p-and : (Book -> Boolean) ... -> (Book -> Boolean)
;; True of a book when EVERY argument predicate is true of it.
;; The empty conjunction is true.
(define (p-and . preds)
  (lambda (b)
    (let loop ((ps preds))
      (cond ((null? ps) #t)
            ((not ((car ps) b)) #f)
            (else (loop (cdr ps)))))))

;; p-or : (Book -> Boolean) ... -> (Book -> Boolean)
;; The empty disjunction is false.
(define (p-or . preds)
  (lambda (b)
    (let loop ((ps preds))
      (cond ((null? ps) #f)
            (((car ps) b) #t)
            (else (loop (cdr ps)))))))
```

Note that the loops above **short-circuit**: `p-and` stops at the first false predicate.

## 3.3 Example Usage

```scheme
(define catalog (catalog-from-list (list b1 b2 b3 b4 b5)))

;; one engine, many queries
(search-catalog (by-genre 'sci-fi) catalog)
(search-catalog (by-author "Isaac Asimov") catalog)
(search-catalog (year-between 1950 1970) catalog)
(search-catalog (title-contains "Found") catalog)

;; an ad-hoc criterion needs no new procedure at all
(search-catalog (lambda (b) (even? (book-year b))) catalog)

;; composed criteria
(define classic-sci-fi (p-and (by-genre 'sci-fi) (year-between 1940 1970)))
(map book-title (search-catalog classic-sci-fi catalog))
;; => ("Dune" "Foundation")

(map book-title
     (search-catalog (p-or (by-genre 'cyberpunk) (by-author "Frank Herbert"))
                     catalog))
;; => ("Dune" "Neuromancer")

(count-matching (by-genre 'sci-fi) catalog)            ; => 2
(any-match? (by-year 1984) catalog)                    ; => #t
(all-match? (lambda (b) (> (book-year b) 1900)) catalog) ; => #t
(all-match? (by-genre 'sci-fi) (empty-catalog))        ; => #t   (vacuously)
(search-catalog (by-genre 'romance) catalog)           ; => ()
```

## 3.4 Acceptance Criteria

| # | Criterion |
|---|---|
| 3.1 | `search-catalog` takes the predicate as its **first** argument and returns a list, preserving original order. |
| 3.2 | At least **five** predicate constructors are implemented, each returning a `lambda`. |
| 3.3 | `p-and`, `p-or`, `p-not` are implemented and short-circuit where applicable. |
| 3.4 | A test demonstrates a query using an inline `lambda` that no named constructor covers. |
| 3.5 | `search-catalog` on the empty catalog returns `'()`; a no-match query returns `'()`; `find-first` returns `#f`. |
| 3.6 | `all-match?` returns `#t` for the empty catalog, and this is tested explicitly. |
| 3.7 | The by-title/by-author/by-year procedures from Iteration 2 are either removed or re-expressed as one-line wrappers over `search-catalog` / `find-first`. |
| 3.8 | `test-search.scm` contains at least 6 checks and all pass. |

> **Criterion 3.7 matters.** The point of this iteration is *removing* code. If
> `catalog.scm` still contains three hand-written search loops, the abstraction has not
> been adopted. The wrapper should read:
> ```scheme
> (define (catalog-find-by-title title catalog)
>   (find-first (lambda (b) (string=? (book-title b) title)) catalog))
> ```

## 3.5 Common Pitfalls

* Writing `(search-catalog (by-genre 'sci-fi catalog))` — the parenthesis is misplaced.
  `by-genre` takes one argument and returns a procedure; `search-catalog` takes two.
* Writing `(by-genre 'sci-fi)` where a predicate is expected but *calling* it: remember
  `(by-genre 'sci-fi)` **is** the predicate; you do not call it yourself.
* Confusing `pred` with its result — `(if pred …)` is always true, since a procedure
  object is a truthy value. You want `(if (pred b) …)`.

---

# Iteration 4 — Functional Collection Processing

## 4.1 Goal and Core Concepts

**Goal.** Implement the three universal sequence operations — `map`, `filter`, `fold` —
and rewrite the catalog's reporting and statistics as **pipelines** built from them.

**Core concepts.** `map` (transform), `filter` (select), `fold` (accumulate) as a complete
algebra of list processing; `fold-left` vs `fold-right`; the "signal-flow" view of a
program; point-free composition.

Abelson & Sussman call this the *conventional interface*. Almost every list computation
you will ever write decomposes into:

```
   source  ──filter──▶  ──map──▶  ──fold──▶  result
   (list)    (select)   (transform) (accumulate)
```

`fold` is the most general of the three: **`map` and `filter` can both be written as folds**,
and you will be asked to do exactly that.

## 4.2 Detailed Instructions

Create `src/pipeline.scm`.

### Required procedures — generic layer

```scheme
;; my-map : (A -> B) (listof A) -> (listof B)
(my-map f lst)

;; my-filter : (A -> Boolean) (listof A) -> (listof A)
(my-filter pred lst)

;; fold-right : (A B -> B) B (listof A) -> B
;;   (fold-right f z '(a b c)) = (f a (f b (f c z)))
(fold-right f init lst)

;; fold-left : (B A -> B) B (listof A) -> B
;;   (fold-left f z '(a b c)) = (f (f (f z a) b) c)
(fold-left f init lst)

;; my-length, my-reverse, my-append : via folds
;; flat-map : (A -> (listof B)) (listof A) -> (listof B)
(flat-map f lst)

;; unique : (listof A) -> (listof A)        ; order-preserving duplicate removal
(unique lst)
```

### Required procedures — domain layer

```scheme
;; catalog-titles      : Catalog -> (listof String)
;; catalog-authors     : Catalog -> (listof String)   ; unique
;; catalog-genres      : Catalog -> (listof Symbol)   ; unique
;; catalog-total-books : Catalog -> Integer
;; catalog-year-sum    : Catalog -> Integer
;; catalog-average-year: Catalog -> Real | #f         ; #f for the empty catalog
;; catalog-oldest      : Catalog -> Book | #f
;; catalog-newest      : Catalog -> Book | #f
;; catalog-year-range  : Catalog -> (cons Integer Integer) | #f
;; count-by-genre      : Catalog -> (listof (cons Symbol Integer))
```

### Step 1 — the three operations, by hand

```scheme
;; my-map : (A -> B) (listof A) -> (listof B)
;; Applies F to every element, preserving order and length.
(define (my-map f lst)
  (if (null? lst)
      '()
      (cons (f (car lst))
            (my-map f (cdr lst)))))

;; my-filter : (A -> Boolean) (listof A) -> (listof A)
;; Keeps exactly the elements satisfying PRED, preserving order.
(define (my-filter pred lst)
  (cond ((null? lst) '())
        ((pred (car lst)) (cons (car lst) (my-filter pred (cdr lst))))
        (else (my-filter pred (cdr lst)))))
```

`my-filter` is `search-catalog` with the type generalized. Once it exists, redefine
Iteration 3's search in one line:

```scheme
(define (search-catalog pred catalog) (my-filter pred catalog))
```

### Step 2 — the two folds

Get the argument orders right; they differ, and this trips up nearly everyone.

```scheme
;; fold-right : (A B -> B) B (listof A) -> B
;; Combines from the RIGHT.  (fold-right cons '() lst) is a copy of lst.
(define (fold-right f init lst)
  (if (null? lst)
      init
      (f (car lst) (fold-right f init (cdr lst)))))

;; fold-left : (B A -> B) B (listof A) -> B
;; Combines from the LEFT; tail recursive, constant space.
;; (fold-left (lambda (acc x) (cons x acc)) '() lst) reverses lst.
(define (fold-left f init lst)
  (if (null? lst)
      init
      (fold-left f (f init (car lst)) (cdr lst))))
```

| | first argument of `f` | recursion | space | preserves order |
|---|---|---|---|---|
| `fold-right` | the element | non-tail | O(n) stack | yes, naturally |
| `fold-left`  | the accumulator | tail | O(1) stack | reverses unless you compensate |

**Rule of thumb.** Building a *list* → `fold-right`. Building a *number, string, or
table* → `fold-left`.

### Step 3 — derive everything else from the folds

This is a required exercise; each of these must be a one-liner:

```scheme
;; my-length : (listof A) -> Integer
(define (my-length lst)
  (fold-left (lambda (acc x) (+ acc 1)) 0 lst))

;; my-reverse : (listof A) -> (listof A)
(define (my-reverse lst)
  (fold-left (lambda (acc x) (cons x acc)) '() lst))

;; my-append : (listof A) (listof A) -> (listof A)
(define (my-append a b)
  (fold-right cons b a))

;; map, expressed as a fold
(define (map-via-fold f lst)
  (fold-right (lambda (x acc) (cons (f x) acc)) '() lst))

;; filter, expressed as a fold
(define (filter-via-fold pred lst)
  (fold-right (lambda (x acc) (if (pred x) (cons x acc) acc)) '() lst))

;; flat-map : (A -> (listof B)) (listof A) -> (listof B)
(define (flat-map f lst)
  (fold-right (lambda (x acc) (my-append (f x) acc)) '() lst))
```

### Step 4 — order-preserving `unique`

```scheme
;; member-by : (A A -> Boolean) A (listof A) -> Boolean
(define (member-by same? x lst)
  (cond ((null? lst) #f)
        ((same? x (car lst)) #t)
        (else (member-by same? x (cdr lst)))))

;; unique : (listof A) -> (listof A)
;; Removes later duplicates (EQUAL?), preserving first-occurrence order.
(define (unique lst)
  (my-reverse
   (fold-left (lambda (acc x)
                (if (member-by equal? x acc) acc (cons x acc)))
              '()
              lst)))
```

### Step 5 — the domain pipelines

Now express the catalog statistics purely as pipelines. Each should be short enough to
read aloud as a sentence.

```scheme
;; catalog-titles : Catalog -> (listof String)
(define (catalog-titles catalog)
  (my-map book-title catalog))

;; catalog-authors : Catalog -> (listof String)  ; each author once
(define (catalog-authors catalog)
  (unique (my-map book-author catalog)))

;; catalog-genres : Catalog -> (listof Symbol)
(define (catalog-genres catalog)
  (unique (my-map book-genre catalog)))

;; catalog-year-sum : Catalog -> Integer
(define (catalog-year-sum catalog)
  (fold-left (lambda (acc b) (+ acc (book-year b))) 0 catalog))

;; catalog-average-year : Catalog -> Real | #f
;; #f for an empty catalog — there is no average of nothing.
(define (catalog-average-year catalog)
  (let ((n (catalog-count catalog)))
    (if (= n 0)
        #f
        (/ (catalog-year-sum catalog) n))))

;; catalog-oldest : Catalog -> Book | #f
;; The book with the smallest year; ties resolved toward the earlier entry.
(define (catalog-oldest catalog)
  (if (catalog-empty? catalog)
      #f
      (fold-left (lambda (best b)
                   (if (< (book-year b) (book-year best)) b best))
                 (car catalog)
                 (cdr catalog))))

;; catalog-newest : Catalog -> Book | #f
(define (catalog-newest catalog)
  (if (catalog-empty? catalog)
      #f
      (fold-left (lambda (best b)
                   (if (> (book-year b) (book-year best)) b best))
                 (car catalog)
                 (cdr catalog))))

;; catalog-year-range : Catalog -> (cons Integer Integer) | #f
(define (catalog-year-range catalog)
  (if (catalog-empty? catalog)
      #f
      (cons (book-year (catalog-oldest catalog))
            (book-year (catalog-newest catalog)))))
```

### Step 6 — a grouped count

This anticipates Iteration 6: the accumulator is an **association list**, built purely.

```scheme
;; bump : Symbol (listof (cons Symbol Integer)) -> (listof (cons Symbol Integer))
;; Increments the tally for KEY, inserting it with 1 if absent.
(define (bump key tally)
  (cond ((null? tally) (list (cons key 1)))
        ((eq? key (car (car tally)))
         (cons (cons key (+ 1 (cdr (car tally)))) (cdr tally)))
        (else (cons (car tally) (bump key (cdr tally))))))

;; count-by-genre : Catalog -> (listof (cons Symbol Integer))
;; (count-by-genre cat) => ((sci-fi . 2) (cyberpunk . 1))
(define (count-by-genre catalog)
  (fold-left (lambda (tally b) (bump (book-genre b) tally))
             '()
             catalog))
```

### Step 7 — a pipeline demonstration (required)

Write at least one procedure that visibly chains all three operations:

```scheme
;; recent-sci-fi-titles : Catalog Integer -> (listof String)
;; Titles of sci-fi books published in or after SINCE, newest data first.
(define (recent-sci-fi-titles catalog since)
  (my-map book-title
          (my-filter (p-and (by-genre 'sci-fi)
                            (lambda (b) (>= (book-year b) since)))
                     catalog)))

;; total-age : Catalog Integer -> Integer
;; Sum of the ages of all books relative to NOW — filter, map, fold in sequence.
(define (total-age catalog now)
  (fold-left +
             0
             (my-map (lambda (b) (- now (book-year b)))
                     (my-filter (lambda (b) (<= (book-year b) now))
                                catalog))))
```

## 4.3 Example Usage

```scheme
(my-map    book-year catalog)                        ; => (1965 1984 1951)
(my-filter (by-genre 'sci-fi) catalog)               ; => (<book> <book>)
(fold-left + 0 (my-map book-year catalog))           ; => 5900

(catalog-authors catalog)
;; => ("Frank Herbert" "William Gibson" "Isaac Asimov")

(catalog-average-year catalog)                       ; => 5900/3  (exact rational)
(exact->inexact (catalog-average-year catalog))      ; => 1966.66...
(catalog-average-year (empty-catalog))               ; => #f

(book-title (catalog-oldest catalog))                ; => "Foundation"
(catalog-year-range catalog)                         ; => (1951 . 1984)

(count-by-genre catalog)
;; => ((sci-fi . 2) (cyberpunk . 1))

(recent-sci-fi-titles catalog 1960)                  ; => ("Dune")

;; map and filter rewritten as folds agree with the direct versions
(equal? (my-map book-title catalog) (map-via-fold book-title catalog))   ; => #t
```

## 4.4 Acceptance Criteria

| # | Criterion |
|---|---|
| 4.1 | `my-map`, `my-filter`, `fold-left`, `fold-right` are implemented from scratch with correct argument orders. |
| 4.2 | `my-length`, `my-reverse`, `my-append`, `map-via-fold`, `filter-via-fold` are each derived as a **single** fold expression. |
| 4.3 | A test asserts `(equal? (my-map f l) (map-via-fold f l))` and the analogous filter identity. |
| 4.4 | At least **five** domain statistics are implemented as pipelines with no hand-written recursion. |
| 4.5 | Aggregations over the empty catalog return a documented sentinel (`0`, `'()`, or `#f`) and never raise an error. |
| 4.6 | `catalog-oldest` / `catalog-newest` are folds, not sorts. |
| 4.7 | At least one procedure chains `filter` → `map` → `fold` in a single expression. |
| 4.8 | `unique` preserves first-occurrence order, and this is tested. |
| 4.9 | `test-pipeline.scm` contains at least 6 checks and all pass. |

## 4.5 Common Pitfalls

* **Swapped fold arguments.** In `fold-right` the *element* comes first; in `fold-left`
  the *accumulator* comes first. Writing `(lambda (b acc) …)` for a `fold-left` produces
  a baffling type error deep in the recursion. Write the contract first, every time.
* **Using `fold-left` to build a list and forgetting to reverse.** The result comes out
  backwards. Either reverse at the end, or use `fold-right`.
* **`(/ sum n)` returning a rational.** `5900/3` is the *exact* answer and is correct
  Scheme; use `exact->inexact` only at the printing boundary, never inside a computation.
* **Re-implementing `catalog-count` recursively** when `(fold-left (lambda (a x) (+ a 1)) 0 c)`
  is available. This iteration is about *not* writing loops.

---

# Iteration 5 — Hierarchical Catalog Structure

## 5.1 Goal and Core Concepts

**Goal.** Organize the flat catalog into a **category tree** — Fiction → Science Fiction →
Cyberpunk → *books* — and implement insertion, search, and traversal over it.

**Core concepts.** Recursively defined non-linear data; trees as lists of subtrees;
**mutual recursion** between a node procedure and a forest procedure; flattening a tree to
a list; paths.

Everything you learned about lists transfers, with one twist: a list has *one* recursive
field (the `cdr`), so recursion is linear; a tree node has *many* children, so the node
case recurses over a **list of subtrees**. The clean way to write this is two mutually
recursive procedures — one for a node, one for a forest.

### The data definition

Write this grammar into `tree.scm` as a comment before you write any code. Design in
Scheme starts with the data definition.

```
<Node>   ::= (category <name:String> <Forest>)
<Forest> ::= ( <Element> ... )
<Element>::= <Node> | <Book>
```

A category node holds a name and a list of children; each child is either another
category node or a book. Books are already self-identifying (tagged `book` from
Iteration 1), so the two kinds of element are distinguishable with `book?` and
`category?` — no extra machinery is needed. This is the payoff of tagging.

## 5.2 Detailed Instructions

Create `src/tree.scm`.

### Required procedures

```scheme
;;; --- constructors and selectors ---
;; make-category : String (listof Element) -> Node
;; category-name     : Node -> String
;; category-children : Node -> (listof Element)
;; category?         : Any -> Boolean
(make-category name children)
(category-name node)
(category-children node)
(category? x)

;;; --- construction ---
;; empty-tree : String -> Node                        ; a named root with no children
;; tree-add-book : Node (listof String) Book -> Node
;;   Inserts BOOK at the category PATH (a list of names, relative to the root),
;;   creating any missing intermediate categories.
;; tree-add-category : Node (listof String) String -> Node
(empty-tree root-name)
(tree-add-book tree path book)
(tree-add-category tree path new-name)

;;; --- traversal ---
;; tree-books : Node -> (listof Book)                 ; all books, any depth
;; tree-count : Node -> Integer
;; tree-depth : Node -> Integer                       ; root alone = 1
;; tree-categories : Node -> (listof String)
;; tree-map-books : (Book -> Book) Node -> Node       ; structure-preserving
;; tree-filter-books : (Book -> Boolean) Node -> Node
;; tree-search : (Book -> Boolean) Node -> (listof Book)
;; tree-find-category : Node (listof String) -> Node | #f
;; tree-path-of : Node String -> (listof String) | #f ; path to the book with that title
;; tree->catalog : Node -> Catalog                    ; the bridge back to Iteration 2
;; tree-display : Node -> unspecified                 ; indented rendering (main.scm only)
```

### Step 1 — the node abstraction

```scheme
(define category-tag 'category)

;; make-category : String (listof Element) -> Node
(define (make-category name children)
  (list category-tag name children))

;; category-name : Node -> String
(define (category-name node) (list-ref node 1))

;; category-children : Node -> (listof Element)
(define (category-children node) (list-ref node 2))

;; category? : Any -> Boolean   (total)
(define (category? x)
  (and (pair? x) (list? x) (= (length x) 3) (eq? (car x) category-tag)))

;; empty-tree : String -> Node
(define (empty-tree name) (make-category name '()))
```

### Step 2 — traversal by mutual recursion

This is the heart of the iteration. Read the shape of the two procedures against the
grammar above: `tree-books` handles `<Node>`, `forest-books` handles `<Forest>`, and the
`cond` inside `forest-books` handles the two alternatives of `<Element>`.

```scheme
;; tree-books : Node -> (listof Book)
;; Every book anywhere in TREE, in left-to-right depth-first order.
(define (tree-books node)
  (forest-books (category-children node)))

;; forest-books : (listof Element) -> (listof Book)
(define (forest-books elements)
  (cond ((null? elements) '())
        ((book? (car elements))
         (cons (car elements) (forest-books (cdr elements))))
        ((category? (car elements))
         (append (tree-books (car elements))
                 (forest-books (cdr elements))))
        (else (error "forest-books: malformed element" (car elements)))))
```

Once `tree-books` exists, **every list operation you already own applies to trees**:

```scheme
;; tree->catalog : Node -> Catalog
(define (tree->catalog node) (tree-books node))

;; tree-search : (Book -> Boolean) Node -> (listof Book)
(define (tree-search pred node)
  (search-catalog pred (tree-books node)))

;; tree-count : Node -> Integer
(define (tree-count node) (length (tree-books node)))
```

That is the reward for the layering discipline: Iteration 5 gets a full query language
for free, in three lines.

### Step 3 — depth and category listing

```scheme
;; tree-depth : Node -> Integer
;; Depth in categories; a root with no sub-categories has depth 1.
(define (tree-depth node)
  (let ((subs (my-filter category? (category-children node))))
    (if (null? subs)
        1
        (+ 1 (fold-left (lambda (m c) (max m (tree-depth c))) 0 subs)))))

;; tree-categories : Node -> (listof String)
;; All category names, root first, depth-first.
(define (tree-categories node)
  (cons (category-name node)
        (flat-map tree-categories
                  (my-filter category? (category-children node)))))
```

### Step 4 — persistent insertion along a path

Insertion is the hardest procedure in the project, and the one worth the most thought.
The rule is the same as for `catalog-remove-by-title`: **rebuild only the spine you
descend, share everything else.**

```scheme
;; tree-add-book : Node (listof String) Book -> Node
;; Returns a new tree with BOOK placed in the category named by PATH
;; (a list of category names, relative to but not including the root).
;; Missing intermediate categories are created.
;;   (tree-add-book root '("Fiction" "Sci-Fi") dune)
(define (tree-add-book node path book)
  (if (null? path)
      ;; base case: we have arrived — add the book to this node's children
      (make-category (category-name node)
                     (cons book (category-children node)))
      ;; recursive case: descend into (car path), creating it if needed
      (make-category (category-name node)
                     (children-add-book (category-children node)
                                        (car path) (cdr path) book))))

;; children-add-book : (listof Element) String (listof String) Book -> (listof Element)
;; Finds the child category named HEAD and recurses; creates it when absent.
(define (children-add-book elements head rest book)
  (cond ((null? elements)
         ;; not found: build the missing branch
         (list (tree-add-book (empty-tree head) rest book)))
        ((and (category? (car elements))
              (string=? (category-name (car elements)) head))
         (cons (tree-add-book (car elements) rest book)
               (cdr elements)))
        (else
         (cons (car elements)
               (children-add-book (cdr elements) head rest book)))))
```

Trace `(tree-add-book root '("Fiction" "Sci-Fi") dune)` on paper before running it. Note
that the *other* children of `Fiction` are not copied — the `cdr` in the second `cond`
clause is shared with the original tree. That is structural sharing, and it is why
persistent data structures are cheap.

`tree-add-category` follows the same shape; write it yourself.

### Step 5 — navigation and paths

```scheme
;; tree-find-category : Node (listof String) -> Node | #f
;; The sub-node at PATH, or #f when no such path exists.
(define (tree-find-category node path)
  (if (null? path)
      node
      (let loop ((elements (category-children node)))
        (cond ((null? elements) #f)
              ((and (category? (car elements))
                    (string=? (category-name (car elements)) (car path)))
               (tree-find-category (car elements) (cdr path)))
              (else (loop (cdr elements)))))))

;; tree-path-of : Node String -> (listof String) | #f
;; The category path leading to the book titled TITLE, root name included.
(define (tree-path-of node title)
  (let ((here (my-filter (lambda (e)
                           (and (book? e) (string=? (book-title e) title)))
                         (category-children node))))
    (if (not (null? here))
        (list (category-name node))
        (let loop ((subs (my-filter category? (category-children node))))
          (cond ((null? subs) #f)
                ((tree-path-of (car subs) title)
                 => (lambda (p) (cons (category-name node) p)))
                (else (loop (cdr subs))))))))
```

The `=>` form in a `cond` clause passes the value of the test to the following procedure —
exactly the idiom for "if the recursive search succeeded, use what it found". It is
standard R5RS/R7RS and worth adding to your vocabulary.

### Step 6 — structure-preserving transformations

```scheme
;; tree-map-books : (Book -> Book) Node -> Node
;; Applies F to every book, leaving the category structure intact.
(define (tree-map-books f node)
  (make-category
   (category-name node)
   (my-map (lambda (e) (if (book? e) (f e) (tree-map-books f e)))
           (category-children node))))

;; tree-filter-books : (Book -> Boolean) Node -> Node
;; Keeps only books satisfying PRED; categories are preserved even if emptied.
(define (tree-filter-books pred node)
  (make-category
   (category-name node)
   (my-map (lambda (e) (if (book? e) e (tree-filter-books pred e)))
           (my-filter (lambda (e) (or (category? e) (pred e)))
                      (category-children node)))))
```

### Step 7 — indented display

Rendering is I/O, so keep it out of the pure layer; place it in `main.scm`, or define it
here but call it only from `main.scm`.

```scheme
;; tree-display : Node -> unspecified
(define (tree-display node)
  (define (indent n)
    (if (> n 0) (begin (display "  ") (indent (- n 1)))))
  (define (walk e level)
    (cond ((book? e)
           (indent level) (display "- ") (display (book->string e)) (newline))
          ((category? e)
           (indent level) (display "+ ") (display (category-name e)) (newline)
           (for-each (lambda (c) (walk c (+ level 1))) (category-children e)))))
  (walk node 0))
```

## 5.3 Example Usage

```scheme
(define tree
  (tree-add-book
   (tree-add-book
    (tree-add-book
     (tree-add-book (empty-tree "Library")
                    '("Fiction" "Sci-Fi") dune)
     '("Fiction" "Sci-Fi") foundation)
    '("Fiction" "Cyberpunk") neuromancer)
   '("Non-Fiction" "History") sapiens))

(tree-count tree)                       ; => 4
(tree-depth tree)                       ; => 3
(tree-categories tree)
;; => ("Library" "Fiction" "Sci-Fi" "Cyberpunk" "Non-Fiction" "History")

(map book-title (tree-books tree))
;; => ("Foundation" "Dune" "Neuromancer" "Sapiens")

;; the Iteration 3 query language works unchanged on a tree
(map book-title (tree-search (by-genre 'sci-fi) tree))
;; => ("Foundation" "Dune")

(category-name (tree-find-category tree '("Fiction" "Sci-Fi")))   ; => "Sci-Fi"
(tree-find-category tree '("Fiction" "Poetry"))                   ; => #f

(tree-path-of tree "Neuromancer")       ; => ("Library" "Fiction" "Cyberpunk")
(tree-path-of tree "Nothing")           ; => #f

(tree-count (tree-filter-books (by-genre 'sci-fi) tree))   ; => 2
(tree-count tree)                                          ; => 4   <- unchanged

(tree-display tree)
;; + Library
;;   + Fiction
;;     + Sci-Fi
;;       - Foundation — Isaac Asimov (1951) [sci-fi]
;;       - Dune — Frank Herbert (1965) [sci-fi]
;;     + Cyberpunk
;;       - Neuromancer — William Gibson (1984) [cyberpunk]
;;   + Non-Fiction
;;     + History
;;       - Sapiens — Yuval Noah Harari (2011) [history]
```

## 5.4 Acceptance Criteria

| # | Criterion |
|---|---|
| 5.1 | The data definition for `Node` / `Forest` / `Element` appears as a comment at the top of `tree.scm`. |
| 5.2 | `category?` is total, and a book is never mistaken for a category (nor the reverse). |
| 5.3 | `tree-books` is written as a pair of mutually recursive procedures (node / forest). |
| 5.4 | `tree-add-book` creates missing intermediate categories and is **persistent** — a test confirms the original tree still has its original count. |
| 5.5 | `tree-search` is defined by reusing `search-catalog` over `tree-books` rather than by a fresh traversal. |
| 5.6 | `tree-depth` on a childless root returns 1; `tree-books` on a childless root returns `'()`. |
| 5.7 | `tree-find-category` and `tree-path-of` return `#f` for an absent path/title. |
| 5.8 | `tree-map-books` / `tree-filter-books` preserve category structure (verified by comparing `tree-categories` before and after). |
| 5.9 | `test-tree.scm` contains at least 6 checks, including a three-level-deep tree, and all pass. |

## 5.5 Common Pitfalls

* **Using `cons` where `append` is needed.** In `forest-books`, a book contributes one
  element (`cons`) but a sub-category contributes a *list* (`append`). Mixing them yields
  a nested mess.
* **Mutating during insertion.** `set-cdr!` on the children list is forbidden and also
  wrong: it would corrupt every tree sharing that node.
* **An ambiguous representation.** If category names and book titles were both bare
  strings with no tag, `book?` could not tell them apart. Tagging in Iteration 1 is what
  makes Iteration 5 tractable — a good illustration of how an early representation choice
  pays off or costs later.
* **Infinite recursion** from a path argument that is never shortened. Each recursive call
  must pass `(cdr path)`.

---

# Iteration 6 — Key-Value / Table Representation

## 6.1 Goal and Core Concepts

**Goal.** Build **indices**: tables mapping a key to a book or to a list of books, so that
repeated lookups no longer scan the whole catalog.

**Core concepts.** Association lists; keys and buckets; one-to-one vs one-to-many indices;
building a table with `fold`; the time/space trade-off; (optional) hash tables and why
they sit uneasily with immutability.

An association list is simply a list of pairs:

```scheme
'(("978-0441013593" . <book>)
  ("978-0441569595" . <book>))
```

`assoc` searches it in O(n), so a single lookup is no faster than `find-first`. The win
appears when you build the table **once** and query it **many** times — and, more
importantly for this course, when the table lets you express *grouping* naturally.

> **Honest framing.** An alist index is not asymptotically faster than a linear scan for a
> one-off query. What it buys you is (a) amortization across many queries, (b) a
> one-to-many grouping structure, and (c) a representation that a real hash table can
> replace behind the same interface. State this trade-off in your `README.md`; a claim
> that alists are "fast" without qualification will cost marks.

## 6.2 Detailed Instructions

Create `src/index.scm`.

### Required procedures

```scheme
;;; --- generic table layer ---
;; empty-table : -> Table
;; table-put : Key Value Table -> Table          ; replaces any existing entry
;; table-get : Key Table -> Value | #f
;; table-has? : Key Table -> Boolean
;; table-remove : Key Table -> Table
;; table-keys : Table -> (listof Key)
;; table-values : Table -> (listof Value)
;; table-size : Table -> Integer
;; table->list : Table -> (listof (cons Key Value))
;; table-add-to-bucket : Key Value Table -> Table  ; one-to-many: prepends to a list

;;; --- catalog indices ---
;; build-index : (Book -> Key) Catalog -> Table    ; one-to-many, generic
;; index-by-author : Catalog -> Table              ; String -> (listof Book)
;; index-by-genre  : Catalog -> Table              ; Symbol -> (listof Book)
;; index-by-year   : Catalog -> Table              ; Integer -> (listof Book)
;; index-by-isbn   : Catalog -> Table              ; String -> Book   (one-to-one)
;; index-lookup : Key Table -> (listof Book)       ; '() when absent
;; index-count : Key Table -> Integer
;; index-summary : Table -> (listof (cons Key Integer))
```

### Step 1 — the generic table

Keep the table abstraction *separate* from the catalog. It should not mention books at
all; that is what makes it reusable for the genre index, the author index, and the
statistics in Iteration 8.

```scheme
;; empty-table : -> Table
(define (empty-table) '())

;; table-get : Key Table -> Value | #f
;; The value stored under KEY, or #f when absent.
(define (table-get key table)
  (let ((entry (assoc key table)))
    (if entry (cdr entry) #f)))

;; table-has? : Key Table -> Boolean
(define (table-has? key table)
  (if (assoc key table) #t #f))

;; table-put : Key Value Table -> Table
;; A new table in which KEY maps to VALUE, replacing any previous entry.
(define (table-put key value table)
  (cond ((null? table) (list (cons key value)))
        ((equal? key (car (car table)))
         (cons (cons key value) (cdr table)))
        (else
         (cons (car table) (table-put key value (cdr table))))))

;; table-remove : Key Table -> Table
(define (table-remove key table)
  (my-filter (lambda (entry) (not (equal? key (car entry)))) table))

;; table-keys   : Table -> (listof Key)
(define (table-keys   table) (my-map car table))
;; table-values : Table -> (listof Value)
(define (table-values table) (my-map cdr table))
;; table-size   : Table -> Integer
(define (table-size   table) (length table))
;; table->list  : Table -> (listof (cons Key Value))
(define (table->list  table) table)
```

Note that `table-put` **replaces** rather than shadowing. Prepending `(cons key value)`
without removing the old entry would also "work" — `assoc` finds the first match — but it
leaks memory and makes `table-keys` report duplicates. Replace properly.

### Step 2 — one-to-many buckets

```scheme
;; table-add-to-bucket : Key Value Table -> Table
;; Adds VALUE to the list stored under KEY, creating the bucket if needed.
(define (table-add-to-bucket key value table)
  (let ((bucket (table-get key table)))
    (table-put key (cons value (if bucket bucket '())) table)))
```

### Step 3 — the generic index builder

One procedure, parameterized by a **key function** — the same higher-order move as
Iteration 3, applied to table construction:

```scheme
;; build-index : (Book -> Key) Catalog -> Table
;; Groups the books of CATALOG into buckets keyed by (KEY-FN book).
;; Books within a bucket appear in reverse catalog order.
(define (build-index key-fn catalog)
  (fold-left (lambda (table b)
               (table-add-to-bucket (key-fn b) b table))
             (empty-table)
             catalog))

;; index-by-author : Catalog -> Table
(define (index-by-author catalog) (build-index book-author catalog))
;; index-by-genre : Catalog -> Table
(define (index-by-genre  catalog) (build-index book-genre  catalog))
;; index-by-year : Catalog -> Table
(define (index-by-year   catalog) (build-index book-year   catalog))
```

Three indices, three lines. If you find yourself writing a separate recursion for each,
stop and re-read Iteration 3.

For a **one-to-one** index (an ISBN identifies exactly one book), use `table-put`
directly. Add an `isbn` field to your book in Iteration 1, or use the title as a
surrogate key and say so:

```scheme
;; index-by-isbn : Catalog -> Table
;; String -> Book. A later duplicate ISBN overwrites an earlier one.
(define (index-by-isbn catalog)
  (fold-left (lambda (table b) (table-put (book-isbn b) b table))
             (empty-table)
             catalog))
```

### Step 4 — the query layer

`index-lookup` returns `'()` rather than `#f` for an absent key, so that its result can be
fed straight into `my-map` or `fold-left` without a null check. Choosing the sentinel that
composes is a real design decision — record it in your contract.

```scheme
;; index-lookup : Key Table -> (listof Book)
;; The bucket under KEY, or '() when KEY is absent.
(define (index-lookup key table)
  (let ((bucket (table-get key table)))
    (if bucket bucket '())))

;; index-count : Key Table -> Integer
(define (index-count key table)
  (length (index-lookup key table)))

;; index-summary : Table -> (listof (cons Key Integer))
;; How many books sit under each key.
(define (index-summary table)
  (my-map (lambda (entry) (cons (car entry) (length (cdr entry))))
          table))
```

### Step 5 (optional, for extra credit) — hash tables

If your Scheme provides SRFI-69 or R6RS hash tables, add a **parallel implementation**
behind the *same* interface (`table-get`, `table-put`, …) in a file `hash-index.scm`, and
write a short note in `README.md` comparing the two. Two points to address:

1. A mutable hash table breaks persistence: `table-put` would have to copy the whole table
   to keep the old one valid, which destroys the O(1) advantage.
2. The honest functional answer to this problem is a *balanced tree* or a *hash array
   mapped trie*, which gives O(log n) persistent update. You are not asked to implement
   one — only to explain why it is the right answer.

This discussion, done well, is worth more than the code.

## 6.3 Example Usage

```scheme
(define by-author (index-by-author catalog))
(define by-genre  (index-by-genre  catalog))

(table-size by-genre)                              ; => 3
(table-keys by-genre)                              ; => (history cyberpunk sci-fi)

(map book-title (index-lookup 'sci-fi by-genre))   ; => ("Foundation" "Dune")
(index-lookup 'romance by-genre)                   ; => ()
(index-count 'sci-fi by-genre)                     ; => 2
(index-count 'romance by-genre)                    ; => 0

(map book-title (index-lookup "Isaac Asimov" by-author))
;; => ("Foundation")

(index-summary by-genre)
;; => ((history . 1) (cyberpunk . 1) (sci-fi . 2))

;; the generic table is not book-specific
(define t (table-put 'b 2 (table-put 'a 1 (empty-table))))
(table-get 'a t)                                   ; => 1
(table-get 'z t)                                   ; => #f
(table-size (table-put 'a 99 t))                   ; => 2   <- replaced, not appended
(table-get 'a (table-put 'a 99 t))                 ; => 99
(table-get 'a t)                                   ; => 1   <- original intact

;; an index built from any key function at all
(define by-decade
  (build-index (lambda (b) (* 10 (quotient (book-year b) 10))) catalog))
(index-count 1960 by-decade)                       ; => 1
```

## 6.4 Acceptance Criteria

| # | Criterion |
|---|---|
| 6.1 | The generic table layer (`table-put`, `table-get`, `table-remove`, …) contains **no reference to books**. |
| 6.2 | `table-put` replaces an existing key rather than shadowing it; `table-size` is unchanged by a replacement, and this is tested. |
| 6.3 | All table operations are persistent; a test confirms the original table survives a `table-put`. |
| 6.4 | `build-index` is generic in the key function, and at least three named indices are one-line applications of it. |
| 6.5 | `index-lookup` returns `'()` for an absent key and the contract says so. |
| 6.6 | At least one **one-to-one** index (`index-by-isbn` or equivalent) exists, with documented duplicate-key behaviour. |
| 6.7 | `README.md` states the complexity of `table-get` for your representation and the conditions under which indexing pays off. |
| 6.8 | `test-index.scm` contains at least 6 checks — including absent key, duplicate key, and empty catalog — and all pass. |

## 6.5 Common Pitfalls

* **`assq` vs `assoc`.** `assq` compares with `eq?` and works for symbols but **not** for
  strings or numbers reliably. Use `assoc` (which uses `equal?`) unless every key is a
  symbol and you have said so.
* **Stale indices.** An index built from `catalog` is a *snapshot*. After
  `(catalog-add b catalog)`, the old index does not contain `b`. This is not a bug — it is
  the consequence of immutability — but you must document it, and in Iteration 8 you must
  rebuild the index whenever the catalog changes.
* **Bucket order.** `build-index` with `fold-left` yields buckets in reverse catalog
  order. Either document that, or `my-reverse` each bucket at the end. Do not leave it
  unspecified.

---

# Iteration 7 — File I/O and Persistence

## 7.1 Goal and Core Concepts

**Goal.** Save the catalog to a file and read it back, so that data survives between runs;
and generate a formatted report file.

**Core concepts.** Ports; the **external representation** of a datum; `write` vs
`display`; `read` and `eof-object?`; serialization round-trips; isolating effects at the
program's boundary.

Scheme has an advantage here that most languages lack: **`write` and `read` are inverses**.
`write` emits a datum in a form that `read` will parse back into an equal datum. Because
your books are ordinary lists of strings, numbers, and symbols, serialization is nearly
free — no parser to write, no format to invent.

```scheme
(write '(book "Dune" "Frank Herbert" 1965 sci-fi) port)
;; the file now contains:  (book "Dune" "Frank Herbert" 1965 sci-fi)
;; and (read port) returns an EQUAL? list.
```

`display` would **not** work: it prints strings without quotation marks, so `read` could
not recover them. Understanding exactly why is the point of this iteration.

## 7.2 Detailed Instructions

Create `src/io.scm`. **All** file effects live here and nowhere else.

### Required procedures

```scheme
;;; --- serialization (pure: no I/O) ---
;; book->sexp : Book -> SExp
;; sexp->book : SExp -> Book | #f
;; catalog->sexp : Catalog -> SExp
;; sexp->catalog : SExp -> Catalog
;; tree->sexp : Node -> SExp          ; optional
;; sexp->tree : SExp -> Node          ; optional

;;; --- file layer (impure) ---
;; save-catalog : Catalog String -> Boolean
;; load-catalog : String -> Catalog             ; '() if the file is missing
;; append-book  : Book String -> Boolean        ; optional
;; file-exists-safe? : String -> Boolean

;;; --- reporting (impure) ---
;; write-report : Catalog String -> Boolean
;; catalog->report-lines : Catalog -> (listof String)   ; PURE — the testable part
```

### Step 1 — separate the pure part from the effectful part

This is the architectural lesson of the iteration. Serialization (value → s-expression)
and report formatting (catalog → list of strings) are **pure** and therefore testable
without touching the disk. Only the last step — writing a list of strings to a port — is
impure.

```scheme
;; book->sexp : Book -> SExp
;; The external representation of B.
(define (book->sexp b)
  (list 'book (book-title b) (book-author b) (book-year b) (book-genre b)))

;; sexp->book : SExp -> Book | #f
;; Parses an external representation; #f if malformed.
(define (sexp->book s)
  (if (and (list? s) (= (length s) 5) (eq? (car s) 'book))
      (make-book (list-ref s 1) (list-ref s 2) (list-ref s 3) (list-ref s 4))
      #f))

;; catalog->sexp : Catalog -> SExp
(define (catalog->sexp catalog)
  (my-map book->sexp catalog))

;; sexp->catalog : SExp -> Catalog
;; Silently discards malformed entries.
(define (sexp->catalog s)
  (my-filter (lambda (b) (if b #t #f)) (my-map sexp->book s)))
```

If you chose the tagged-list representation in Iteration 1, `book->sexp` may be the
identity. **Write it anyway.** It is the seam that lets you change the internal
representation without changing the file format, and a grader will test exactly that.

### Step 2 — writing

```scheme
;; save-catalog : Catalog String -> Boolean
;; Writes CATALOG to FILENAME, one book per line. Returns #t on completion.
(define (save-catalog catalog filename)
  (call-with-output-file filename
    (lambda (port)
      (for-each (lambda (b)
                  (write (book->sexp b) port)
                  (newline port))
                catalog)))
  #t)
```

`call-with-output-file` opens the port, applies the procedure, and closes the port even on
a normal return — the functional way to manage a resource. Do not use bare
`open-output-file` unless you also close the port.

> **Portability.** In some Schemes `call-with-output-file` raises an error if the file
> already exists; in others it truncates. Racket and Guile truncate. If yours errors,
> delete the file first with `(delete-file filename)` guarded by an existence check.

### Step 3 — reading

The read loop is the one place a non-structural recursion is unavoidable: the number of
data is not known in advance, and `read` is effectful. Use a named `let` with an
accumulator, terminating on `eof-object?`.

```scheme
;; read-all : Port -> (listof SExp)
;; Reads every datum from PORT until end of file, in order.
(define (read-all port)
  (let loop ((acc '()))
    (let ((datum (read port)))
      (if (eof-object? datum)
          (my-reverse acc)
          (loop (cons datum acc))))))

;; load-catalog : String -> Catalog
;; Reads a catalog from FILENAME; returns the empty catalog when the file is absent.
(define (load-catalog filename)
  (if (not (file-exists-safe? filename))
      (empty-catalog)
      (call-with-input-file filename
        (lambda (port) (sexp->catalog (read-all port))))))
```

`file-exists?` is in R7RS `(scheme file)` and in most implementations, but not in R5RS.
Wrap it:

```scheme
;; file-exists-safe? : String -> Boolean
(define (file-exists-safe? filename)
  (call-with-current-continuation
   (lambda (k)
     (with-exception-handler
      (lambda (e) (k #f))
      (lambda ()
        (let ((port (open-input-file filename)))
          (close-input-port port)
          #t))))))
```

If your Scheme lacks `with-exception-handler`, use its native `file-exists?` and note the
dependency in `README.md`.

### Step 4 — the report

Build the report as a **list of strings** first. That procedure is pure, so you can test
the entire report content without writing a single file.

```scheme
;; repeat-string : String Integer -> String
(define (repeat-string s n)
  (if (= n 0) "" (string-append s (repeat-string s (- n 1)))))

;; catalog->report-lines : Catalog -> (listof String)
;; The full text of the summary report, one string per line. PURE.
(define (catalog->report-lines catalog)
  (let ((n     (catalog-count catalog))
        (avg   (catalog-average-year catalog))
        (range (catalog-year-range catalog)))
    (append
     (list "CATALOG SUMMARY REPORT"
           (repeat-string "=" 60)
           (string-append "Total books:   " (number->string n))
           (string-append "Total authors: "
                          (number->string (length (catalog-authors catalog))))
           (string-append "Average year:  "
                          (if avg
                              (number->string (exact->inexact avg))
                              "n/a"))
           (string-append "Year range:    "
                          (if range
                              (string-append (number->string (car range))
                                             "–"
                                             (number->string (cdr range)))
                              "n/a"))
           ""
           "BOOKS BY GENRE"
           (repeat-string "-" 60))
     (my-map (lambda (entry)
               (string-append "  " (symbol->string (car entry))
                              ": " (number->string (cdr entry))))
             (count-by-genre catalog))
     (list ""
           "ALL ENTRIES"
           (repeat-string "-" 60))
     (my-map (lambda (b) (string-append "  " (book->string b))) catalog))))

;; write-lines : (listof String) Port -> unspecified
(define (write-lines lines port)
  (for-each (lambda (line) (display line port) (newline port)) lines))

;; write-report : Catalog String -> Boolean
;; Writes the summary report for CATALOG to FILENAME.
(define (write-report catalog filename)
  (call-with-output-file filename
    (lambda (port) (write-lines (catalog->report-lines catalog) port)))
  #t)
```

Note the use of `display` here, not `write`: the report is for **humans**, so strings
should appear without quotation marks. `catalog.db` uses `write` because it is for
**`read`**. Being able to state that distinction crisply is an acceptance criterion.

### Step 5 — the round-trip test

The essential test of any serializer:

```scheme
(define (io-tests)
  (let* ((original (catalog-from-list (list b1 b2 b3)))
         (path     "data/test-roundtrip.db"))
    (save-catalog original path)
    (let ((restored (load-catalog path)))
      (list (check "round-trip preserves count"
                   (catalog-count original) (catalog-count restored))
            (check "round-trip preserves titles"
                   (catalog-titles original) (catalog-titles restored))
            (check "round-trip preserves everything"
                   (catalog->sexp original) (catalog->sexp restored))
            (check "missing file yields empty catalog"
                   '() (load-catalog "data/no-such-file.db"))
            (check "empty catalog round-trips"
                   '() (begin (save-catalog '() path) (load-catalog path)))
            (check-true "report has a header line"
                        (member "CATALOG SUMMARY REPORT"
                                (catalog->report-lines original)))))))
```

## 7.3 Example Usage

```scheme
(save-catalog catalog "data/catalog.db")            ; => #t

;; data/catalog.db now contains:
;; (book "Foundation" "Isaac Asimov" 1951 sci-fi)
;; (book "Neuromancer" "William Gibson" 1984 cyberpunk)
;; (book "Dune" "Frank Herbert" 1965 sci-fi)

(define restored (load-catalog "data/catalog.db"))
(catalog-count restored)                            ; => 3
(equal? (catalog->sexp catalog) (catalog->sexp restored))   ; => #t

(load-catalog "data/does-not-exist.db")             ; => ()

(write-report catalog "data/report.txt")            ; => #t

;; data/report.txt:
;; CATALOG SUMMARY REPORT
;; ============================================================
;; Total books:   3
;; Total authors: 3
;; Average year:  1966.6666666666667
;; Year range:    1951–1984
;;
;; BOOKS BY GENRE
;; ------------------------------------------------------------
;;   sci-fi: 2
;;   cyberpunk: 1
;;
;; ALL ENTRIES
;; ------------------------------------------------------------
;;   Foundation — Isaac Asimov (1951) [sci-fi]
;;   Neuromancer — William Gibson (1984) [cyberpunk]
;;   Dune — Frank Herbert (1965) [sci-fi]
```

## 7.4 Acceptance Criteria

| # | Criterion |
|---|---|
| 7.1 | `save-catalog` followed by `load-catalog` yields a catalog equal to the original — the **round-trip property**, tested explicitly. |
| 7.2 | `load-catalog` on a missing file returns the empty catalog rather than raising an error. |
| 7.3 | An empty catalog round-trips correctly. |
| 7.4 | Serialization (`book->sexp` / `sexp->book`) is a **separate, pure** layer, testable without file access. |
| 7.5 | `sexp->book` returns `#f` for a malformed datum, and a malformed line in the file does not crash `load-catalog`. |
| 7.6 | `write` is used for the data file and `display` for the report, and `README.md` explains why. |
| 7.7 | Ports are opened with `call-with-output-file` / `call-with-input-file`, or are explicitly closed on every path. |
| 7.8 | `catalog->report-lines` is pure and tested without touching the disk; the report contains a total, an average, a per-genre breakdown, and a full listing. |
| 7.9 | All file effects are confined to `io.scm`. |
| 7.10 | `test-io.scm` contains at least 6 checks and all pass. |

## 7.5 Common Pitfalls

* **Using `display` to save data.** `(display "Dune" port)` writes `Dune`; `read` then
  returns the *symbol* `Dune`, not the string `"Dune"`, and your round-trip test fails in
  a confusing way. Use `write`.
* **Forgetting `(newline port)`.** `write` does not emit one. Without it the file is a
  single long line — which `read` actually handles fine, since whitespace is not
  significant, but which is unreadable to a human debugging it.
* **Relative paths.** `"data/catalog.db"` is relative to the *working directory*, not the
  source file. Run your tests from the project root and say so in `README.md`.
* **Leaving a port open** after an error, exhausting file descriptors across a test run.
  `call-with-*-file` avoids this.
* **Letting I/O leak upward.** If `catalog.scm` starts calling `display`, the layering has
  broken. Effects belong at the edges.

---

# Iteration 8 — Complete Integrated Functional Information System

## 8.1 Goal and Core Concepts

**Goal.** Assemble everything — records, lists, higher-order search, pipelines, trees,
indices, persistence — into one coherent application, and add the pieces that only make
sense once the parts exist: **sorting**, **grouping**, **statistics**, and **composition**.

**Core concepts.** Procedure composition (`compose`, `pipe`); the functional
representation of an application **state** as an immutable value; merge sort on lists;
grouping as an index in disguise; layered architecture; separating computation from
presentation.

The intellectual content of this iteration is **not** new syntax. It is *organization*: a
program is well designed when each layer speaks only to the layer below, and when the
top layer reads as a description of what the program does rather than how.

## 8.2 Detailed Instructions

Create `src/sort.scm` and `src/main.scm`.

### Required procedures

```scheme
;;; --- composition (sort.scm or pipeline.scm) ---
;; compose : (B -> C) (A -> B) -> (A -> C)
;; pipe : (A -> B) ... -> (A -> ?)        ; left-to-right composition
;; identity : A -> A

;;; --- sorting (sort.scm) ---
;; merge-sorted : (A A -> Boolean) (listof A) (listof A) -> (listof A)
;; merge-sort : (A A -> Boolean) (listof A) -> (listof A)
;; sort-by : (A -> Key) (Key Key -> Boolean) (listof A) -> (listof A)
;; catalog-sort-by-year   : Catalog -> Catalog
;; catalog-sort-by-title  : Catalog -> Catalog
;; catalog-sort-by-author : Catalog -> Catalog

;;; --- grouping and statistics (sort.scm, or a new stats.scm loaded after it) ---
;; group-by : (Book -> Key) Catalog -> (listof (cons Key (listof Book)))
;; catalog-statistics : Catalog -> Table
;; top-n : Integer (listof (cons Key Integer)) -> (listof (cons Key Integer))
;; most-prolific-author : Catalog -> String | #f
;; books-per-decade : Catalog -> (listof (cons Integer Integer))

;;; --- the application state (main.scm) ---
;; make-app : Catalog Node -> App
;; app-catalog : App -> Catalog
;; app-tree : App -> Node
;; app-author-index : App -> Table
;; app-genre-index : App -> Table
;; app-add-book : App (listof String) Book -> App     ; rebuilds derived data
;; app-remove-book : App String -> App
;; app-query : App (Book -> Boolean) -> (listof Book)
;; app-load : String -> App
;; app-save : App String -> Boolean
;; run-demo : -> unspecified
```

### Step 1 — composition

```scheme
;; identity : A -> A
(define (identity x) x)

;; compose : (B -> C) (A -> B) -> (A -> C)
;; Right-to-left composition: ((compose f g) x) = (f (g x))
(define (compose f g)
  (lambda (x) (f (g x))))

;; pipe : (A -> B) ... -> (A -> ?)
;; Left-to-right composition, the reading order of a data pipeline:
;; ((pipe f g h) x) = (h (g (f x)))
(define (pipe . fs)
  (lambda (x)
    (fold-left (lambda (acc f) (f acc)) x fs)))
```

`pipe` lets a query read in the order it executes — which is how you want a data pipeline
to read:

```scheme
(define recent-titles-sorted
  (pipe (lambda (c) (my-filter (year-between 1980 2030) c))
        catalog-sort-by-year
        (lambda (c) (my-map book-title c))))

(recent-titles-sorted catalog)   ; => ("Neuromancer" "Sapiens")
```

### Step 2 — merge sort

A stable, O(n log n), purely functional sort. It is the canonical demonstration that
divide-and-conquer needs no mutation.

```scheme
;; split-list : (listof A) -> (cons (listof A) (listof A))
;; Splits LST into two halves of near-equal length.
(define (split-list lst)
  (let loop ((slow lst) (fast lst) (left '()))
    (if (or (null? fast) (null? (cdr fast)))
        (cons (my-reverse left) slow)
        (loop (cdr slow) (cdr (cdr fast)) (cons (car slow) left)))))

;; merge-sorted : (A A -> Boolean) (listof A) (listof A) -> (listof A)
;; Merges two lists already sorted by LESS?. Stable: ties keep A before B.
(define (merge-sorted less? a b)
  (cond ((null? a) b)
        ((null? b) a)
        ((less? (car b) (car a))
         (cons (car b) (merge-sorted less? a (cdr b))))
        (else
         (cons (car a) (merge-sorted less? (cdr a) b)))))

;; merge-sort : (A A -> Boolean) (listof A) -> (listof A)
;; A new list containing the elements of LST in LESS? order. Stable.
(define (merge-sort less? lst)
  (if (or (null? lst) (null? (cdr lst)))
      lst
      (let ((halves (split-list lst)))
        (merge-sorted less?
                      (merge-sort less? (car halves))
                      (merge-sort less? (cdr halves))))))
```

Study the third `cond` clause of `merge-sorted`: the test is `(less? (car b) (car a))`,
**not** `(less? (car a) (car b))`. Taking from `a` whenever `b` is not strictly smaller is
what makes the sort **stable** — equal elements keep their original relative order. Show
that you know this by testing it.

### Step 3 — sorting by a key (higher-order again)

```scheme
;; sort-by : (A -> Key) (Key Key -> Boolean) (listof A) -> (listof A)
;; Sorts by comparing the KEY-FN of each element.
(define (sort-by key-fn key<? lst)
  (merge-sort (lambda (x y) (key<? (key-fn x) (key-fn y))) lst))

;; catalog-sort-by-year   : Catalog -> Catalog
(define (catalog-sort-by-year   c) (sort-by book-year   <        c))
;; catalog-sort-by-title  : Catalog -> Catalog
(define (catalog-sort-by-title  c) (sort-by book-title  string<? c))
;; catalog-sort-by-author : Catalog -> Catalog
(define (catalog-sort-by-author c) (sort-by book-author string<? c))
```

Again: one general procedure, three one-line specializations. This pattern — *generalize,
then specialize by partial application* — is the whole method of the course.

### Step 4 — grouping

Grouping **is** indexing; reuse Iteration 6 rather than writing it again.
Because these procedures need both `build-index` (Iteration 6) and `sort-by`
(this iteration), they belong in `sort.scm` or in a `stats.scm` loaded after it —
not in `pipeline.scm`, which sits below `index.scm` in the dependency chain.

```scheme
;; group-by : (Book -> Key) Catalog -> (listof (cons Key (listof Book)))
;; Partitions CATALOG into buckets keyed by KEY-FN, each bucket in catalog order.
(define (group-by key-fn catalog)
  (my-map (lambda (entry) (cons (car entry) (my-reverse (cdr entry))))
          (build-index key-fn catalog)))

;; books-per-decade : Catalog -> (listof (cons Integer Integer))
(define (books-per-decade catalog)
  (sort-by car <
           (index-summary
            (build-index (lambda (b) (* 10 (quotient (book-year b) 10)))
                         catalog))))
```

### Step 5 — statistics

Return statistics as a **table**, not as printed text. Computation produces data;
presentation is a separate concern that happens later, in `main.scm`. This separation is
graded.

```scheme
;; top-n : Integer (listof (cons Key Integer)) -> (listof (cons Key Integer))
;; The N entries with the largest counts, descending.
(define (top-n n entries)
  (let loop ((sorted (sort-by cdr > entries)) (k n) (acc '()))
    (if (or (= k 0) (null? sorted))
        (my-reverse acc)
        (loop (cdr sorted) (- k 1) (cons (car sorted) acc)))))

;; most-prolific-author : Catalog -> String | #f
(define (most-prolific-author catalog)
  (let ((ranked (top-n 1 (index-summary (index-by-author catalog)))))
    (if (null? ranked) #f (car (car ranked)))))

;; catalog-statistics : Catalog -> Table
;; A table of named summary figures. Pure; no printing.
(define (catalog-statistics catalog)
  (fold-left (lambda (t kv) (table-put (car kv) (cdr kv) t))
             (empty-table)
             (list (cons 'total-books    (catalog-count catalog))
                   (cons 'total-authors  (length (catalog-authors catalog)))
                   (cons 'total-genres   (length (catalog-genres catalog)))
                   (cons 'average-year   (catalog-average-year catalog))
                   (cons 'year-range     (catalog-year-range catalog))
                   (cons 'by-genre       (count-by-genre catalog))
                   (cons 'by-decade      (books-per-decade catalog))
                   (cons 'top-authors    (top-n 3 (index-summary
                                                   (index-by-author catalog))))
                   (cons 'oldest         (catalog-oldest catalog))
                   (cons 'newest         (catalog-newest catalog)))))
```

### Step 6 — the application state

Here is the central idea of a functional application: **the state is a value**. There is
no global variable, no `set!`. An operation takes a state and returns a *new* state; the
top-level loop threads states through operations. The catalog is the source of truth; the
tree and the indices are **derived** and are rebuilt whenever the catalog changes.

```scheme
;; An App bundles the catalog with everything derived from it.
;; make-app : Catalog Node -> App
(define (make-app catalog tree)
  (list 'app
        catalog
        tree
        (index-by-author catalog)      ; derived
        (index-by-genre  catalog)))    ; derived

(define (app-catalog      app) (list-ref app 1))
(define (app-tree         app) (list-ref app 2))
(define (app-author-index app) (list-ref app 3))
(define (app-genre-index  app) (list-ref app 4))

;; app-add-book : App (listof String) Book -> App
;; Adds BOOK to the catalog and to the tree at PATH, rebuilding the indices.
(define (app-add-book app path book)
  (make-app (catalog-add book (app-catalog app))
            (tree-add-book (app-tree app) path book)))

;; app-remove-book : App String -> App
(define (app-remove-book app title)
  (let ((catalog (catalog-remove-by-title title (app-catalog app))))
    (make-app catalog
              (tree-filter-books
               (lambda (b) (not (string=? (book-title b) title)))
               (app-tree app)))))

;; app-query : App (Book -> Boolean) -> (listof Book)
(define (app-query app pred)
  (search-catalog pred (app-catalog app)))

;; app-load : String -> App
(define (app-load filename)
  (let ((catalog (load-catalog filename)))
    (make-app catalog (catalog->tree catalog))))

;; app-save : App String -> Boolean
(define (app-save app filename)
  (save-catalog (app-catalog app) filename))

;; catalog->tree : Catalog -> Node
;; Rebuilds a two-level genre tree from a flat catalog.
(define (catalog->tree catalog)
  (fold-left (lambda (tree b)
               (tree-add-book tree (list (symbol->string (book-genre b))) b))
             (empty-tree "Library")
             catalog))
```

Note `app-add-book`: rebuilding both indices on every insertion is O(n). Say so in your
`README.md`, and state what you would do instead in a production system (incremental
index update, or a persistent balanced-tree index). Recognizing the cost of a design is
worth as much as avoiding it.

### Step 7 — the presentation layer

`main.scm` is the **only** place that prints. Everything below it returns values.

```scheme
;;; main.scm — presentation and the demo driver. The only printing layer.

(define (print-line s) (display s) (newline))

;; print-books : (listof Book) -> unspecified
(define (print-books books)
  (if (null? books)
      (print-line "  (no matches)")
      (for-each (lambda (b) (print-line (string-append "  " (book->string b))))
                books)))

;; print-section : String -> unspecified
(define (print-section title)
  (newline) (print-line title) (print-line (repeat-string "-" 60)))

;; print-statistics : Table -> unspecified
(define (print-statistics stats)
  (print-section "STATISTICS")
  (for-each (lambda (key)
              (display "  ") (display key) (display ": ")
              (write (table-get key stats)) (newline))
            (table-keys stats)))

;; run-demo : -> unspecified
;; Exercises every iteration end to end.
(define (run-demo)
  (let* ((app0 (app-load "data/sample-catalog.txt"))
         (app  (app-add-book app0 (list "Fiction" "Sci-Fi")
                             (make-book "Hyperion" "Dan Simmons" 1989 'sci-fi))))

    (print-section "1-2. CATALOG")
    (print-books (app-catalog app))

    (print-section "3. SEARCH — sci-fi published 1950-1970")
    (print-books (app-query app (p-and (by-genre 'sci-fi)
                                       (year-between 1950 1970))))

    (print-section "4. PIPELINE — titles, sorted by year")
    (for-each print-line
              ((pipe catalog-sort-by-year
                     (lambda (c) (my-map book->string c)))
               (app-catalog app)))

    (print-section "5. TREE")
    (tree-display (app-tree app))

    (print-section "6. INDEX — books per author")
    (for-each (lambda (e)
                (print-line (string-append "  " (car e) ": "
                                           (number->string (cdr e)))))
              (sort-by cdr > (index-summary (app-author-index app))))

    (print-statistics (catalog-statistics (app-catalog app)))

    (print-section "7. PERSISTENCE")
    (app-save app "data/catalog.db")
    (write-report (app-catalog app) "data/report.txt")
    (print-line "  saved data/catalog.db and data/report.txt")
    (print-line (string-append "  reloaded book count: "
                               (number->string
                                (catalog-count
                                 (load-catalog "data/catalog.db")))))

    (print-section "DONE")))
```

### Step 8 (optional) — an interactive loop

If you add a REPL-style menu, keep the state threading explicit. The loop parameter *is*
the state; there is still no `set!`.

```scheme
;; repl : App -> unspecified
(define (repl app)
  (display "catalog> ")
  (let ((command (read)))
    (cond ((or (eof-object? command) (eq? command 'quit))
           (print-line "bye"))
          ((eq? command 'list)
           (print-books (app-catalog app))
           (repl app))                                   ; state unchanged
          ((eq? command 'stats)
           (print-statistics (catalog-statistics (app-catalog app)))
           (repl app))
          ((eq? command 'save)
           (app-save app "data/catalog.db")
           (print-line "saved")
           (repl app))
          (else
           (print-line "commands: list stats save quit")
           (repl app)))))
```

## 8.3 Example Usage

```scheme
;; composition
((compose book-title catalog-newest) catalog)        ; => "Sapiens"
((pipe catalog-sort-by-year catalog-titles) catalog)
;; => ("Foundation" "Dune" "Neuromancer" "Sapiens")

;; sorting is persistent
(catalog-titles (catalog-sort-by-title catalog))
;; => ("Dune" "Foundation" "Neuromancer" "Sapiens")
(catalog-titles catalog)
;; => ("Foundation" "Neuromancer" "Dune" "Sapiens")   <- original order intact

;; grouping
(my-map car (group-by book-genre catalog))           ; => (history cyberpunk sci-fi)
(books-per-decade catalog)
;; => ((1950 . 1) (1960 . 1) (1980 . 1) (2010 . 1))

;; statistics as data
(define stats (catalog-statistics catalog))
(table-get 'total-books stats)                       ; => 4
(table-get 'top-authors stats)
;; => (("Isaac Asimov" . 1) ("Frank Herbert" . 1) ("William Gibson" . 1))
(most-prolific-author catalog)                       ; => "Isaac Asimov"

;; the application state threads through operations
(define app  (app-load "data/sample-catalog.txt"))
(define app2 (app-add-book app '("Fiction" "Sci-Fi")
                           (make-book "Hyperion" "Dan Simmons" 1989 'sci-fi)))
(catalog-count (app-catalog app))                    ; => 4
(catalog-count (app-catalog app2))                   ; => 5   <- app is untouched
(index-count 'sci-fi (app-genre-index app2))         ; => 3   <- index was rebuilt

(run-demo)
```

## 8.4 Acceptance Criteria

| # | Criterion |
|---|---|
| 8.1 | `compose` and `pipe` are implemented, and at least two operations in the system are expressed by composing existing procedures rather than by new recursion. |
| 8.2 | `merge-sort` is implemented from scratch, is **stable**, and stability is demonstrated by a test using two records with equal keys. |
| 8.3 | `sort-by` is generic in the key function; the three named sorts are one-line applications of it. |
| 8.4 | `group-by` reuses `build-index` from Iteration 6 rather than duplicating it. |
| 8.5 | `catalog-statistics` returns **data** (a table), not printed output, and contains at least six distinct figures. |
| 8.6 | The application state is an immutable value; `app-add-book` / `app-remove-book` return a new `App` and a test confirms the old one is unchanged. |
| 8.7 | Derived structures (tree, indices) are consistent with the catalog after every state transition, verified by a test. |
| 8.8 | **All** printing is confined to `main.scm`; `grep` for `display` in `src/` must find it only in `main.scm` (and in `io.scm`, where it writes to a file port). |
| 8.9 | `run-demo` executes end to end without error, exercising every iteration, and its output is reproduced in `README.md`. |
| 8.10 | The full test suite (`test/run-all.scm`) reports zero failures. |
| 8.11 | `README.md` documents the layer diagram, the complexity of the main operations, and at least two design trade-offs you made. |

## 8.5 Common Pitfalls

* **A global mutable `*catalog*`.** The commonest way to fail this iteration. If you find
  yourself reaching for `set!` to "keep the current catalog", thread the state through the
  loop instead — the `repl` above shows how.
* **Stale derived data.** Adding to the catalog without rebuilding the index leaves the
  index silently wrong. Either rebuild in one place (`make-app`), or compute indices
  lazily on demand — but never let them drift.
* **Printing inside a computation.** A `display` in `catalog-statistics` makes the
  procedure untestable and couples the model to the view.
* **An unstable sort.** Comparing with `(less? (car a) (car b))` in the merge breaks
  stability. This is subtle and is explicitly tested.
* **Copy-pasting `merge-sort` for each field.** Three sorts must be three one-liners over
  `sort-by`.

---

# 9. Code Style Guide

## 9.1 Formatting

* Two-space indentation. No tabs.
* Closing parentheses stack on the same line: `(cdr lst))))` — never on lines of their own.
* One blank line between top-level definitions; two between sections.
* Keep lines under 80 characters.
* Align the clauses of a `cond` and the bindings of a `let`:

```scheme
(cond ((null? lst)      init)
      ((pred (car lst)) (cons (car lst) (rest)))
      (else             (rest)))
```

## 9.2 Choosing a form

| Situation | Use | Not |
|---|---|---|
| Two-way branch | `if` | a one-armed `cond` |
| Three or more branches | `cond` | nested `if` |
| Dispatch on a symbol | `case` | a chain of `eq?` tests |
| Independent local bindings | `let` | nested `let`s |
| Bindings that refer to earlier ones | `let*` | `let` with an outer wrapper |
| A local loop | named `let` | a top-level helper |
| A helper used only inside one procedure | internal `define` | a top-level definition |
| Comparing structures | `equal?` | `eq?` |
| Comparing strings | `string=?` | `eq?` or `equal?` |
| Comparing numbers | `=` | `eqv?` |
| Comparing symbols | `eq?` | `equal?` |

## 9.3 Immutability checklist

Before submitting, search your `src/` directory for each of the following. Any hit outside
`main.scm` or `io.scm` must be justified in `README.md`:

```
set!   set-car!   set-cdr!   string-set!   vector-set!   hash-table-set!   define-record-type with mutable fields
```

```
grep -rn "set!" src/
```

## 9.4 Procedure design

* **One procedure, one job.** If the contract needs the word "and", split it.
* **Return values; do not print them.** A procedure that prints cannot be composed.
* **Make the general case a parameter.** Three near-identical procedures are a missing
  higher-order procedure.
* **Keep procedures short.** More than about fifteen lines usually means a helper is
  hiding inside.
* **Put the data argument last** in a curried-friendly position where you can — though
  Scheme convention (`map`, `filter`, `for-each`) puts the procedure first and the data
  last, so follow that: `(search-catalog pred catalog)`, not `(search-catalog catalog pred)`.

## 9.5 Error handling

Prefer **total** procedures that return a documented sentinel over procedures that raise:

| Situation | Return | Rationale |
|---|---|---|
| Item not found | `#f` | the standard Scheme idiom; composes with `if` and `cond =>` |
| No items matched | `'()` | composes with `map` / `fold` without a null check |
| Aggregate over nothing | `0`, `#f`, or `""` | document which, and be consistent |
| Genuinely malformed input | `(error "proc: message" datum)` | a programmer error, not a data condition |

Use `error` only for violated preconditions — a caller bug — never for ordinary "absent"
outcomes.

## 9.6 Testing practice

* Write the **contract** first, then a **test**, then the body. The contract tells you what
  the test should assert.
* Every procedure gets at least one test for the ordinary case and one for the boundary.
* The four boundaries that matter here: the **empty** collection, the **single-element**
  collection, the **absent** key, and the **duplicate** key.
* Test **properties**, not just examples:
  * round-trip: `(equal? c (sexp->catalog (catalog->sexp c)))`
  * persistence: the original is unchanged after an "update"
  * equivalence: `(equal? (my-map f l) (map-via-fold f l))`
  * invariant: `(= (catalog-count c) (tree-count (catalog->tree c)))`
* Never let a test depend on another test having run first. Each suite builds its own
  fixtures.
* A test that needs mutation to express itself is a sign the code under test is impure.

---

# 10. Assessment

## 10.1 Marking scheme

| Component | Weight |
|---|---|
| Iteration 1 — data abstraction | 8 % |
| Iteration 2 — collection and recursion | 10 % |
| Iteration 3 — higher-order search | 12 % |
| Iteration 4 — map / filter / fold | 14 % |
| Iteration 5 — tree | 14 % |
| Iteration 6 — indices | 10 % |
| Iteration 7 — persistence | 10 % |
| Iteration 8 — integration | 12 % |
| Tests (coverage, boundaries, properties) | 6 % |
| Style, documentation, `README.md` | 4 % |

## 10.2 Cross-cutting deductions

These are applied across the whole submission, not per iteration:

| Violation | Deduction |
|---|---|
| `set!` or a mutator in a core layer, unjustified | −10 % |
| A book accessed with `car`/`cdr` outside `book.scm` | −8 % |
| Duplicated code where a higher-order procedure was specified | −6 % |
| `display` in a pure layer | −4 % |
| Missing contract comments | −4 % |
| A procedure that raises where the spec requires `#f` or `'()` | −3 % |
| Test suite does not run | −10 % |

## 10.3 Grade bands

* **Pass (50–59).** Iterations 1–4 work. Recursion is correct. Some duplication remains.
* **Good (60–69).** All eight iterations work. Higher-order procedures are used where
  specified. Tests cover the ordinary cases.
* **Very good (70–79).** No duplication; generic procedures are genuinely generic. Layers
  are clean. Boundary cases are tested. `README.md` explains the design.
* **Excellent (80+).** Property-based tests. A defended representation choice. Complexity
  analysis. Extensions beyond the specification (see §12). Code that reads like an
  explanation of itself.

## 10.4 Submission checklist

- [ ] `src/` contains all eight (or nine) source files, each loadable independently in
      dependency order.
- [ ] `test/run-all.scm` runs from the project root and reports **0 failures**.
- [ ] Every exported procedure has a contract comment.
- [ ] `grep -rn "set!" src/` returns nothing outside `main.scm` / `io.scm`, or every hit is
      justified in `README.md`.
- [ ] No `car`/`cdr`/`cadr` applied to a book outside `book.scm`.
- [ ] `data/sample-catalog.txt` is present and `(run-demo)` works from a clean checkout.
- [ ] `README.md` contains: the chosen domain, the representation choice and its
      justification, the layer diagram, how to run the code and the tests, a complexity
      table, at least two design trade-offs, and the output of `(run-demo)`.
- [ ] The code runs on at least one named Scheme implementation, stated in `README.md`
      with its version.

---

# 11. Appendix A — Sample Dataset

Save as `data/sample-catalog.txt`. It is valid input for `load-catalog` exactly as
written — this is the payoff of using `write`/`read` for persistence.

```scheme
(book "Foundation" "Isaac Asimov" 1951 sci-fi)
(book "I, Robot" "Isaac Asimov" 1950 sci-fi)
(book "Dune" "Frank Herbert" 1965 sci-fi)
(book "Neuromancer" "William Gibson" 1984 cyberpunk)
(book "Snow Crash" "Neal Stephenson" 1992 cyberpunk)
(book "The Left Hand of Darkness" "Ursula K. Le Guin" 1969 sci-fi)
(book "A Wizard of Earthsea" "Ursula K. Le Guin" 1968 fantasy)
(book "The Hobbit" "J. R. R. Tolkien" 1937 fantasy)
(book "Sapiens" "Yuval Noah Harari" 2011 history)
(book "Structure and Interpretation of Computer Programs" "Harold Abelson" 1985 textbook)
(book "The Little Schemer" "Daniel P. Friedman" 1974 textbook)
(book "Gödel, Escher, Bach" "Douglas Hofstadter" 1979 philosophy)
```

This dataset is chosen to exercise the interesting cases: a **duplicate author** across
two books (Asimov, Le Guin — needed for `index-by-author` and `most-prolific-author`), an
author spanning **two genres** (Le Guin — needed for grouping), **adjacent years**
(1968/1969 — needed for sort stability), and a **wide year range** (1937–2011 — needed for
`books-per-decade`).

Corresponding fixture definitions for your test files:

```scheme
(define b-foundation  (make-book "Foundation"  "Isaac Asimov"   1951 'sci-fi))
(define b-irobot      (make-book "I, Robot"    "Isaac Asimov"   1950 'sci-fi))
(define b-dune        (make-book "Dune"        "Frank Herbert"  1965 'sci-fi))
(define b-neuromancer (make-book "Neuromancer" "William Gibson" 1984 'cyberpunk))
(define b-hobbit      (make-book "The Hobbit"  "J. R. R. Tolkien" 1937 'fantasy))

(define fixture-catalog
  (catalog-from-list (list b-foundation b-irobot b-dune b-neuromancer b-hobbit)))
```

---

# 12. Appendix B — Optional Extensions

Attempt these only after every acceptance criterion is met. Each is worth bonus credit if
documented in `README.md`.

| # | Extension | Concept exercised |
|---|---|---|
| B1 | **Streams.** Re-implement `search-catalog` over `delay`/`force` streams so an infinite catalog can be queried lazily. | Lazy evaluation, `cons-stream` |
| B2 | **A query DSL.** Represent a query as data — `'(and (genre sci-fi) (year > 1960))` — and write an evaluator that turns it into a predicate. | Metalinguistic abstraction; the data/program boundary |
| B3 | **A persistent balanced tree index.** Replace the alist table with an AVL or red-black tree offering O(log n) persistent insertion. | Persistent data structures; structural sharing |
| B4 | **Generic dispatch.** Make the catalog hold books *and* journals *and* films, dispatching selectors on the tag. | Data-directed programming; message passing |
| B5 | **CSV import/export.** Add a `csv->catalog` parser alongside the s-expression format. | Parsing; string processing without regular expressions |
| B6 | **Property-based testing.** Write a small random generator for books and assert the round-trip and sort-stability properties over 100 random catalogs. | Property-based testing; generators |
| B7 | **Undo history.** Since every state is a value, keep a list of past `App` states and implement `undo` in two lines. | The practical payoff of persistence |
| B8 | **Complexity measurement.** Instrument a counting wrapper around your comparison procedure and empirically confirm `merge-sort` is O(n log n). | Higher-order instrumentation; empirical complexity |

Extension **B7** deserves a closing remark. Undo, in a mutable design, is a substantial
engineering problem: you need a command log, inverse operations, and careful handling of
aliasing. In this design it is:

```scheme
;; undo : (listof App) -> (cons App (listof App))
(define (undo history)
  (if (null? (cdr history)) history (cdr history)))
```

Every constraint this project imposed — no `set!`, return new values, share structure —
was paying for that. That is the argument for functional programming, and you have now
built it rather than been told it.
