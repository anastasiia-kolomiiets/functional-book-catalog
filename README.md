# Project 4 — Functional Data Catalog

A library catalog built incrementally in Scheme, in a pure functional style.
The full specification is in
[PROJECT_4_Functional_Data_Catalog.md](PROJECT_4_Functional_Data_Catalog.md).

**Status: Iteration 1 of 8 complete** — object representation (data abstraction).

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
book  <-  [catalog]  <-  [search]  <-  [pipeline]  <-  [tree]
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

TOTAL FAILURES: 0
```

> The sources are UTF-8. `book->string` uses an em dash (`—`), so an
> implementation reading source as Latin-1 will render that byte pair oddly on
> the console. It does not affect the tests, which compare strings from the same
> encoding.

### Verification status

No Scheme implementation is installed on the machine where this was written, so
**the suite has not been executed**. What has been checked mechanically:

* parenthesis balance in all four files, with string literals, character
  literals, and comments handled correctly;
* top-level form counts matching the declared procedure lists;
* no `set!` or other mutator anywhere in `src/`;
* no `car` / `cdr` / `list-ref` applied to a book outside `src/book.scm`.

Run the suite on a machine with Guile, Chez, Chibi, or Racket before submitting.

---

## Files

```
src/book.scm             Iteration 1 — the Book record
test/test-framework.scm  purely functional test harness
test/test-book.scm       38 checks over Iteration 1
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
