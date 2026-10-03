# Project 4 — Functional Data Catalog

A library catalog built incrementally in Scheme, in a pure functional style.
The full specification is in
[PROJECT_4_Functional_Data_Catalog.md](PROJECT_4_Functional_Data_Catalog.md).

**Status: Iteration 4 of 8 complete** — object representation, the catalog as a
list of books, a single higher-order search engine, and hand-written
map / filter / fold with the domain aggregations built on them.

---

## Domain

The catalog holds **books**. A book has four fields:

| Field | Type | Example |
|---|---|---|
| title | `String` | `"Dune"` |
| author | `String` | `"Frank Herbert"` |
| year | `Integer` | `1965` |
| genre | `Symbol` | `sci-fi` |

`year` is the numeric field required for aggregation in Iteration 4; `genre` is
the categorical field required for grouping in Iteration 5 and for indexing in
Iteration 6.

---

## Representation choice

A book is a **tagged list**:

```scheme
(book "Dune" "Frank Herbert" 1965 sci-fi)
```

The specification offers three options — nested pairs, a tagged list, and a
message-passing closure. The tagged list was chosen for three reasons:

1. **It is self-identifying.** The `book` tag lets `book?` be a *total*
   predicate: it can recognize a book without being told what it is looking at.
   This matters in Iteration 5, where a category node must hold a mixed list of
   sub-categories and books and tell the two apart with `book?` and
   `category?`. Nested pairs offer nothing to dispatch on, so the tree would
   need a second, redundant tagging scheme layered on top.

2. **It has a printable external representation.** In Iteration 7 the
   persistence layer serializes with `write` and parses with `read`, which are
   inverses for ordinary lists of strings, numbers, and symbols. The file format
   therefore needs no parser. A message-passing closure cannot be written at
   all — a procedure has no external representation — so it would force an
   explicit `book->sexp` conversion with no corresponding benefit here.

3. **It is extensible.** Adding an `isbn` field later means extending the list
   and the length check in `book?`; every caller above the barrier is unaffected.

The cost of the choice is that selection is `list-ref`, which is O(k) in the
field index rather than O(1). With four fields this is irrelevant, and the
abstraction barrier means it can be revisited without touching any caller.

### The barrier

`src/book.scm` is the only file permitted to know any of the above. The contract
that defines a book is:

```
(book-title  (make-book t a y g)) = t
(book-author (make-book t a y g)) = a
(book-year   (make-book t a y g)) = y
(book-genre  (make-book t a y g)) = g
```

Any representation satisfying it is correct. To verify the barrier holds,
replace the body of `make-book` and the four selectors with the nested-pair
version from the specification and re-run the tests: they must pass unmodified.

---

## Layering

Each file may depend only on files to its left. Bracketed entries are not yet
implemented.

```
book  <-  catalog  <-  search  <-  pipeline  <-  [tree]
                                                    |
                               [index]  <-  [sort]  <-  [io]  <-  [main]
```

---

## Running

No `#lang` line is used, so the sources are plain R5RS/R7RS-compatible Scheme
and load in any conforming implementation. Run **from the project root** — the
paths in `test/run-all.scm` are relative to the working directory, not to the
file.

```sh
guile -l test/run-all.scm
chez --script test/run-all.scm
mit-scheme --quiet < test/run-all.scm
chibi-scheme test/run-all.scm
```

Under Racket, either run the sources through the R5RS reader:

```sh
racket -I r5rs -f test/run-all.scm
```

or add `#lang r5rs` as the first line of each file.

Expected output:

```
== Iteration 1 — book
  PASS  book-title returns the title
  ...
   38/38 passed

== Iteration 2 — catalog
  PASS  a new catalog is empty
  ...
   17/17 passed

== Iteration 3 — search
  PASS  search by genre finds 3 sci-fi books
  ...
   20/20 passed

== Iteration 4 — pipeline
  PASS  my-map applies the function to every element
  ...
   19/19 passed

TOTAL FAILURES: 0
```

> The sources are UTF-8. `book->string` uses an em dash (`—`), so an
> implementation reading source as Latin-1 will render that byte pair oddly on
> the console. It does not affect the tests, which compare strings from the same
> encoding.

### Verification status

The full suite (94 checks) runs under Chez Scheme with `chez --script
test/run-all.scm` and reports `TOTAL FAILURES: 0`.

---

## Files

```
src/book.scm             Iteration 1 — the Book record
src/catalog.scm          Iteration 2 — the catalog, a list of Books
src/search.scm           Iteration 3 — higher-order search and predicates
src/pipeline.scm         Iteration 4 — map / filter / fold, aggregations
test/test-framework.scm  purely functional test harness
test/test-book.scm       38 checks over Iteration 1
test/test-catalog.scm    17 checks over Iteration 2
test/test-search.scm     20 checks over Iteration 3
test/test-pipeline.scm   19 checks over Iteration 4
test/run-all.scm         loader and runner
```

---

## Iteration 1 — what was implemented

| Procedure | Contract |
|---|---|
| `make-book` | `String String Integer Symbol -> Book` |
| `book-title` | `Book -> String` |
| `book-author` | `Book -> String` |
| `book-year` | `Book -> Integer` |
| `book-genre` | `Book -> Symbol` |
| `book?` | `Any -> Boolean` (total) |
| `book=?` | `Book Book -> Boolean` (structural) |
| `book-with-genre` | `Book Symbol -> Book` (persistent) |
| `book-with-year` | `Book Integer -> Book` (persistent) |
| `book->string` | `Book -> String` |

### Design notes

* **`book=?` uses three different equality operators** — `string=?` for the two
  string fields, `=` for the year, `eq?` for the genre symbol. `eq?` on strings
  is *unspecified* in Scheme and is never used for them here.

* **`book?` guards with `list?` before calling `length`.** `length` raises an
  error on an improper list such as `(book . 3)`, so the guard is what makes the
  predicate total rather than merely usually-correct. This is tested.

* **`book?` uses `integer?`, not `exact-integer?`.** `exact-integer?` is R7RS
  and absent from R5RS; `integer?` keeps the file portable, at the cost of
  accepting an inexact year such as `1965.0`. Noted as a deliberate trade-off.

* **`book->string` returns a string rather than printing one.** Printing is a
  side effect and belongs in the presentation layer (`main.scm`, Iteration 8).
  A procedure that prints cannot be composed or tested by value.

* **No mutation anywhere.** `book-with-genre` and `book-with-year` construct a
  new book from the selectors of the old one, so they are written entirely above
  the barrier and would survive a change of representation untouched.

---

## Iteration 2 — what was implemented

| Procedure | Contract |
|---|---|
| `empty-catalog` | `-> Catalog` |
| `catalog-empty?` | `Catalog -> Boolean` |
| `catalog-add` | `Book Catalog -> Catalog` (persistent) |
| `catalog-count` | `Catalog -> Integer` (tail recursive) |
| `catalog-find-by-title` | `String Catalog -> Book \| #f` |
| `catalog-contains?` | `String Catalog -> Boolean` |
| `catalog-remove-by-title` | `String Catalog -> Catalog` (persistent) |
| `catalog-titles` | `Catalog -> (listof String)` |
| `catalog-from-list` | `(listof Book) -> Catalog` |
| `catalog->list` | `Catalog -> (listof Book)` |

### Design notes

* **`catalog-find-by-title` returns the book, not `#t`.** A procedure that
  returns the thing you were looking for composes with other code; one that
  returns a boolean forces the caller to search again.

* **"Not found" is `#f`, never `'()`.** In Scheme only `#f` is false, so
  returning `'()` would make `(if (catalog-find-by-title ...) ...)` always take
  the true branch.

* **`catalog-count` is tail recursive.** The accumulator carries the answer
  forward, so the loop runs in constant space instead of building a chain of
  pending additions.

* **`catalog-add` conses onto the front**, which is O(1) and leaves the old
  catalog valid. Books therefore come out in reverse insertion order — the tests
  assume this.

* **`catalog-remove-by-title` shares structure.** Only the prefix up to the
  removed book is rebuilt; the rest of the list is shared with the original.
  That is why persistence is cheap rather than a copy of everything.

* **`catalog-from-list` and `catalog->list` are the identity** today, since a
  Catalog *is* a list. They are named anyway so the representation can change
  later without touching callers.

---

## Iteration 3 — what was implemented

| Procedure | Contract |
|---|---|
| `search-catalog` | `(Book -> Boolean) Catalog -> (listof Book)` |
| `find-first` | `(Book -> Boolean) Catalog -> Book \| #f` |
| `count-matching` | `(Book -> Boolean) Catalog -> Integer` |
| `any-match?` | `(Book -> Boolean) Catalog -> Boolean` |
| `all-match?` | `(Book -> Boolean) Catalog -> Boolean` |
| `by-title`, `by-author` | `String -> (Book -> Boolean)` |
| `by-genre` | `Symbol -> (Book -> Boolean)` |
| `by-year` | `Integer -> (Book -> Boolean)` |
| `year-between` | `Integer Integer -> (Book -> Boolean)` |
| `title-contains` | `String -> (Book -> Boolean)` |
| `p-and`, `p-or` | two predicates `-> (Book -> Boolean)` |
| `p-not` | `(Book -> Boolean) -> (Book -> Boolean)` |

### Design notes

* **One engine, many queries.** `catalog-find-by-title` and
  `catalog-find-by-author` differed only in their test, so the test became a
  parameter. Any new criterion now needs no new procedure at all — an inline
  `lambda` is enough, and the tests demonstrate that.

* **The predicate builders return procedures.** `(by-genre 'sci-fi)` *is* the
  predicate; it is handed to `search-catalog`, never called directly. Each
  captures its argument in a closure.

* **`p-and` / `p-or` take exactly two predicates**, not a variable number. The
  specification permits fixed arity if documented; nesting covers three
  (`(p-and p1 (p-and p2 p3))`) and the two-argument version is far easier to
  read. They short-circuit, because Scheme's `and` and `or` do.

* **`all-match?` is true for an empty catalog** — there is no book there that
  breaks the rule. Written as a direct recursion rather than derived from
  `any-match?` via De Morgan, because the base case then states the rule plainly.

* **`string-contains?` is hand-written**, since Scheme has no standard substring
  search. It slides a window with `substring` and `string=?`, which allocates a
  little but is much clearer than a character-by-character double loop.

* **Iteration 2's searches were rewritten as one-liners** at the end of
  `search.scm`, as the specification requires. Because `search.scm` loads after
  `catalog.scm`, those definitions replace the earlier recursions — and the
  unchanged Iteration 2 suite becomes the regression test proving the rewrite
  behaves identically.

---

## Iteration 4 — what was implemented

| Procedure | Contract |
|---|---|
| `my-map` | `(A -> B) (listof A) -> (listof B)` |
| `my-filter` | `(A -> Boolean) (listof A) -> (listof A)` |
| `fold-right` | `(A B -> B) B (listof A) -> B` |
| `fold-left` | `(B A -> B) B (listof A) -> B` (tail recursive) |
| `flat-map` | `(A -> (listof B)) (listof A) -> (listof B)` |
| `unique` | `(listof A) -> (listof A)` (order-preserving) |
| `catalog-titles` | `Catalog -> (listof String)` (now via `my-map`) |
| `catalog-authors` | `Catalog -> (listof String)` |
| `catalog-genres` | `Catalog -> (listof Symbol)` |
| `catalog-year-sum` | `Catalog -> Integer` |
| `catalog-average-year` | `Catalog -> Real \| #f` |
| `catalog-oldest`, `catalog-newest` | `Catalog -> Book \| #f` |
| `catalog-year-range` | `Catalog -> (Integer . Integer) \| #f` |
| `count-by-genre` | `Catalog -> (listof (Symbol . Integer))` |
| `recent-sci-fi-titles` | `Catalog Integer -> (listof String)` — filter → map |
| `total-age` | `Catalog Integer -> Integer` — map → fold |
| `genre-total-age` | `Catalog Symbol Integer -> Integer` — filter → map → fold |

### Design notes

* **The generic layer knows nothing about books.** `my-map`, `my-filter`, the
  folds, `flat-map` and `unique` work on any list; the domain layer supplies the
  book-specific functions. `fold-left` and `fold-right` take their arguments in
  the R6RS order, so they shadow the built-ins of implementations that have them
  without changing behaviour.

* **`fold-left` is tail recursive, `fold-right` is not.** The left fold carries
  its result in the accumulator; the right fold must wait for the rest of the
  list. Aggregations that produce a scalar (`catalog-year-sum`,
  `count-matching`, `total-age`) therefore use `fold-left`.

* **`catalog-oldest` and `catalog-newest` share one helper**, `pipeline/pick`,
  a fold that keeps a "champion" and replaces it only when a book is strictly
  better. On a tie the earlier book wins; on an empty catalog the initial `#f`
  survives, so no special case is needed. `catalog-year-range` is derived from
  the two.

* **`catalog-average-year` returns an exact number.** `9787/5` loses nothing;
  the presentation layer converts with `exact->inexact` when it prints. An empty
  catalog gives `#f` rather than dividing by zero.

* **`count-by-genre` is a single `fold-left`** whose accumulator is an
  association list, rebuilt (never mutated) at each step. Genres appear in order
  of first occurrence.

* **`unique` uses `equal?`**, so two different string objects with the same
  characters are duplicates. It is O(n²), which is fine for the catalog sizes
  here; Iteration 6's indices are the place for anything faster.

* **Earlier procedures were rewritten on the new algebra.** `catalog-titles` is
  now `my-map`, `search-catalog` is `my-filter`, and `count-matching` is a
  `fold-left`. As in Iteration 3, the redefinitions in `pipeline.scm` replace
  the originals, and the unchanged Iteration 2 and 3 suites prove the behaviour
  is identical.
