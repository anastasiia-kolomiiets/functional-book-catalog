# Project 4 — Functional Data Catalog

**Course:** Functional Programming  
**Language:** Scheme (R7RS-small; R5RS-compatible subset — runnable under Racket, Guile, Chez, Chicken, MIT/GNU Scheme)  
**Deliverable:** A modular, incrementally built functional information system  
**Structure:** 8 graded iterations + final integration

---

## 1. Overview

In this project you will build a **data catalog** — a small, domain-driven information system — entirely in Scheme, in a **pure functional** style.

The running domain used throughout this document is a **library catalog of books**, where each book carries a *title*, *author*, *year*, and *genre*. You may substitute a different domain (a music catalog, a film archive, a museum inventory, a parts catalog for a warehouse), provided it has **at least four attributes**, of which at least one is **numeric** (needed for aggregation in Iteration 4) and at least one is **categorical** (needed for grouping and for the tree in Iteration 5).

The project is deliberately **incremental**. Each iteration adds exactly one new abstraction, and — crucially — *each iteration is built on the **interface** of the previous one, never on its **representation***. By the end you will have travelled the full arc of functional data design:

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
8. Assemble all of the above into a layered program in which each layer depends only on the layer beneath it.

---

## 2. Ground Rules

These rules apply to **every** iteration and are part of the grade.

### R1 — Purity

Procedures must be **pure**: the same arguments always yield the same result, and no observable side effect occurs. There are exactly three sanctioned exceptions:

* File I/O in Iteration 7, confined to `io.scm`.
* Printing in the user-facing layer of Iteration 8, confined to `main.scm`.
* `display` / `newline` inside the test runner.

### R2 — No mutation

`set!`, `set-car!`, `set-cdr!`, `string-set!`, `vector-set!`, and hash-table mutation are **forbidden** in the core layers (`book.scm`, `catalog.scm`, `search.scm`, `pipeline.scm`, `tree.scm`, `index.scm`).

"Updating" a catalog means **returning a new catalog**. The old value remains valid. This property is called **persistence**.

### R3 — Respect abstraction barriers

Above Iteration 1, the operators `car`, `cdr`, `cadr`, `caddr`, and `list-ref` must **never** be applied to a book. Only the selectors of the book abstraction may be used.

A grader will replace the internal representation of a book (for example, a list becomes a vector) by editing `book.scm` only, then re-run your tests. If they still pass, the barrier was respected.

### R4 — Naming conventions

| Pattern | Meaning | Examples |
|---|---|---|
| `make-X` | constructor | `make-book`, `make-category` |
| `X?` | type predicate (total) | `book?`, `category?` |
| `X-field` | selector | `book-title`, `category-name` |
| `X-with-field` | persistent update | `book-with-genre` |
| `X->Y` | total conversion | `book->string`, `catalog->list` |
| `X/helper` | module-private helper | (kept local) |

Use `kebab-case`. Never use `_` in identifiers.

### R5 — Recursion discipline

* Prefer **structural recursion**: one clause per constructor of the data type.
* Prefer **tail recursion with an accumulator** where the result is a scalar and order does not matter.
* Use a named `let` for a local loop rather than a top-level helper that pollutes the namespace.

### R6 — Documentation

Every exported procedure carries a comment block giving a **contract** (types in, type out), a **purpose** statement, and — where the behaviour is not obvious — an **example**.

---

## 3. Suggested Project File Structure

```
functional-book-catalog/
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
│   ├── test-framework.scm
│   ├── test-book.scm
│   ├── test-catalog.scm
│   ├── test-search.scm
│   ├── test-pipeline.scm
│   ├── test-tree.scm
│   ├── test-index.scm
│   ├── test-io.scm
│   ├── test-system.scm
│   └── run-all.scm
├── data/
│   ├── sample-catalog.txt
│   ├── catalog.db            ; produced by Iteration 7
│   └── report.txt            ; produced by Iteration 7/8
├── PROJECT_4_Functional_Data_Catalog.md
└── README.md
```

---

## 4. Environment and Running the Code

The code must run under at least one of: Racket, Guile, Chez Scheme, Chicken, or MIT/GNU Scheme, using a portable R5RS/R7RS-small subset.

Portability notes:

* Prefer standard procedures; avoid implementation-specific extensions.
* Implement `filter`, `fold-left`, `fold-right` yourself (Iteration 4).
* Implement merge sort yourself (Iteration 8).

---

## 5. The Test Harness

A minimal pure test framework is provided / expected:

* `check` — compare expected and actual values
* `check-true` / `check-false`
* `report-result`
* `count-passed`
* `run-suite`

Each iteration supplies its own test suite. `run-all.scm` runs every suite and reports the total number of failures.

Tests must be pure where possible and must not depend on the order of other tests.

---

# Iteration 1 — Object Representation (Data Abstraction)

## 1.1 Goal and Core Concepts

Introduce a self-contained data type for a book. Clients must never depend on the internal representation.

## 1.2 Required procedures

| Procedure | Contract | Purpose |
|---|---|---|
| `make-book` | String × String × Integer × Symbol → Book | Constructor |
| `book-title` | Book → String | Selector |
| `book-author` | Book → String | Selector |
| `book-year` | Book → Integer | Selector |
| `book-genre` | Book → Symbol | Selector |
| `book?` | Any → Boolean | Total type predicate |
| `book=?` | Book × Book → Boolean | Structural equality |
| `book-with-genre` | Book × Symbol → Book | Persistent update of genre |
| `book-with-year` | Book × Integer → Book | Persistent update of year |
| `book->string` | Book → String | Human-readable rendering |

## 1.3 Design notes (pseudocode)

```
make-book(title, author, year, genre) =
  a tagged record that carries all four fields

book?(x) =
  true only for values produced by make-book;
  must return false (never raise) for any other input

book-with-genre(b, g) =
  a new book that is identical to b except for the genre field;
  the original book is left unchanged

book->string(b) =
  a single-line string containing title, author, year and genre
```

## 1.4 Acceptance criteria

* All selectors recover the values given to the constructor.
* `book?` is total.
* Persistent updates leave the original book unchanged.
* `book=?` compares structure, not identity.
* Rendering includes every field.

---

# Iteration 2 — Object Collection

## 2.1 Goal and Core Concepts

A Catalog is an immutable collection of books. Every operation that “changes” the catalog returns a new catalog.

## 2.2 Required procedures

| Procedure | Contract | Purpose |
|---|---|---|
| `empty-catalog` | → Catalog | The empty collection |
| `catalog-empty?` | Catalog → Boolean | Emptiness test |
| `catalog-add` | Book × Catalog → Catalog | Prepend a book (persistent) |
| `catalog-count` | Catalog → Integer | Number of books (tail-recursive) |
| `catalog-find-by-title` | String × Catalog → Book \| #f | Linear search by title |
| `catalog-contains?` | String × Catalog → Boolean | Convenience predicate |
| `catalog-remove-by-title` | String × Catalog → Catalog | Persistent removal of all matching titles |
| `catalog-titles` | Catalog → list of String | Projection of titles |
| `catalog-from-list` | list of Book → Catalog | Conversion (identity today) |
| `catalog->list` | Catalog → list of Book | Conversion (identity today) |

`catalog-from-list` and `catalog->list` exist so that the representation of Catalog can change later without touching callers.

## 2.3 Design notes (pseudocode)

```
catalog-add(book, catalog) =
  a new catalog that contains book at the front;
  the original catalog is unchanged

catalog-count(catalog) =
  count the books using a tail-recursive accumulator

catalog-find-by-title(title, catalog) =
  the first book whose title equals the given string,
  or #f if none exists

catalog-remove-by-title(title, catalog) =
  a new catalog without any book of that title;
  removing an absent title yields an equal catalog

catalog-titles(catalog) =
  the list of titles in catalog order
  (implement by structural recursion; later rewrite with map)
```

## 2.4 Acceptance criteria

* Adding and removing never mutate the original catalog.
* `catalog-count` is tail-recursive.
* Search and removal behave correctly on empty catalogs and missing titles.
* Projection preserves order.

---

# Iteration 3 — Search as a Higher-Order Function

## 3.1 Goal and Core Concepts

Replace a family of almost-identical search procedures with a single higher-order search that takes a predicate. Introduce predicate constructors and combinators.

## 3.2 Required procedures

### Generic search family

| Procedure | Contract | Purpose |
|---|---|---|
| `search-catalog` | (Book → Boolean) × Catalog → list of Book | All matching books, in order |
| `find-first` | (Book → Boolean) × Catalog → Book \| #f | First match or #f |
| `count-matching` | (Book → Boolean) × Catalog → Integer | How many match |
| `any-match?` | (Book → Boolean) × Catalog → Boolean | At least one match |
| `all-match?` | (Book → Boolean) × Catalog → Boolean | Every book matches (vacuously true for empty) |

### Predicate constructors (each returns a predicate)

| Procedure | Contract |
|---|---|
| `by-author` | String → (Book → Boolean) |
| `by-genre` | Symbol → (Book → Boolean) |
| `by-year` | Integer → (Book → Boolean) |
| `year-between` | Integer × Integer → (Book → Boolean) |
| `title-contains` | String → (Book → Boolean) |

### Predicate combinators

| Procedure | Contract |
|---|---|
| `p-and` | (Book → Boolean) … → (Book → Boolean) |
| `p-or` | (Book → Boolean) … → (Book → Boolean) |
| `p-not` | (Book → Boolean) → (Book → Boolean) |

## 3.3 Design notes (pseudocode)

```
search-catalog(pred, catalog) =
  every book for which pred returns true, preserving order

find-first(pred, catalog) =
  the first book that satisfies pred, or #f

any-match?(pred, catalog) =
  true if find-first returns a book

all-match?(pred, catalog) =
  not any-match?(not pred, catalog)   // De Morgan

by-author(name) =
  a predicate that is true exactly when book-author equals name

p-and(p1, p2, ...) =
  a predicate true only when every pi is true
```

After this iteration, specialised finders such as “find by author” should be expressed as one-liners using the generic search + a predicate constructor.

## 3.4 Acceptance criteria

* The generic search family is implemented by structural recursion (or later by filter).
* Predicate constructors return closures.
* Combinators correctly implement logical operations.
* Existing specialised searches can be rewritten without duplication.

---

# Iteration 4 — Functional Collection Processing

## 4.1 Goal and Core Concepts

Implement the classic sequence algebra (`map`, `filter`, `fold`) by hand, then express domain operations as pipelines.

## 4.2 Required procedures

### Generic layer

| Procedure | Contract | Purpose |
|---|---|---|
| `my-map` | (A → B) × list of A → list of B | Transform every element |
| `my-filter` | (A → Boolean) × list of A → list of A | Keep satisfying elements |
| `fold-right` | (A × B → B) × B × list of A → B | Right fold |
| `fold-left` | (B × A → B) × B × list of A → B | Left (tail-recursive) fold |
| `flat-map` | (A → list of B) × list of A → list of B | Map then concatenate |
| `unique` | list of A → list of A | Order-preserving duplicate removal |

### Domain layer

| Procedure | Contract | Purpose |
|---|---|---|
| `catalog-titles` | Catalog → list of String | (re-implemented with map) |
| `catalog-authors` | Catalog → list of String | Unique authors |
| `catalog-genres` | Catalog → list of Symbol | Unique genres |
| `catalog-year-sum` | Catalog → Integer | Sum of publication years |
| `catalog-average-year` | Catalog → Real \| #f | Average year (#f for empty) |
| `catalog-oldest` | Catalog → Book \| #f | Book with smallest year |
| `catalog-newest` | Catalog → Book \| #f | Book with largest year |
| `catalog-year-range` | Catalog → (Integer . Integer) \| #f | (min-year . max-year) |
| `count-by-genre` | Catalog → list of (Symbol . Integer) | Frequency table by genre |

### Pipeline examples (required)

| Procedure | Contract | Purpose |
|---|---|---|
| `recent-sci-fi-titles` | Catalog × Integer → list of String | Titles of sci-fi books published ≥ given year |
| `total-age` | Catalog × Integer → Integer | Sum of ages relative to a reference year |

**Note:** There is no separate `catalog-total-books`. Use the existing `catalog-count`.

## 4.3 Design notes (pseudocode)

```
my-map(f, lst) =
  empty → empty
  (x · xs) → f(x) · my-map(f, xs)

my-filter(pred, lst) =
  empty → empty
  (x · xs) → if pred(x) then x · my-filter(pred, xs)
             else my-filter(pred, xs)

fold-left(f, init, lst) =   // tail recursive
  empty → init
  (x · xs) → fold-left(f, f(init, x), xs)

fold-right(f, init, lst) =
  empty → init
  (x · xs) → f(x, fold-right(f, init, xs))

catalog-average-year(catalog) =
  if empty then #f
  else catalog-year-sum(catalog) / catalog-count(catalog)

count-by-genre(catalog) =
  fold-left over the catalog, accumulating an association list of counts
```

## 4.4 Acceptance criteria

* Generic higher-order procedures are written by hand (not imported).
* Domain aggregations are expressed via fold / map / filter.
* At least one visible pipeline that chains filter → map → fold (or equivalent) is present.
* Empty-catalog edge cases return `#f` or the empty list as specified.

---

# Iteration 5 — Hierarchical Catalog Structure

## 5.1 Goal and Core Concepts

Represent a tree of categories whose leaves (or mixed nodes) hold books. Mutual recursion over trees.

## 5.2 Required procedures

### Node constructors & selectors

| Procedure | Contract |
|---|---|
| `make-category` | String × list of Element → Node |
| `category-name` | Node → String |
| `category-children` | Node → list of Element |
| `category?` | Any → Boolean |
| `empty-tree` | String → Node |

An Element is either a Book or a Node.

### Tree operations

| Procedure | Contract | Purpose |
|---|---|---|
| `tree-add-book` | Node × list of String × Book → Node | Insert book under a path of category names |
| `tree-add-category` | Node × list of String × String → Node | Create a new subcategory under a path |
| `tree-books` | Node → list of Book | All books at any depth |
| `tree-count` | Node → Integer | Number of books |
| `tree-depth` | Node → Integer | Depth of the tree (root alone = 1) |
| `tree-categories` | Node → list of String | Names of all categories |
| `tree-map-books` | (Book → Book) × Node → Node | Structure-preserving map over books |
| `tree-filter-books` | (Book → Boolean) × Node → Node | Keep only matching books |
| `tree-search` | (Book → Boolean) × Node → list of Book | Search anywhere in the tree |
| `tree-find-category` | Node × list of String → Node \| #f | Locate a node by path |
| `tree-path-of` | Node × String → list of String \| #f | Path to the book with the given title |
| `tree->catalog` | Node → Catalog | Flatten the tree back into a catalog |

## 5.3 Design notes (pseudocode)

```
tree-books(node) =
  books directly in this node
  + tree-books of every child category

tree-add-book(node, path, book) =
  if path is empty → add book to this node’s children
  else → recursively descend into (or create) the named subcategory

tree-map-books(f, node) =
  a new node with the same name and structure,
  but every book replaced by f(book)

tree->catalog(node) =
  catalog-from-list(tree-books(node))
```

## 5.4 Acceptance criteria

* Tree operations are pure and persistent.
* Mutual recursion is used correctly for nodes vs. forests.
* Flattening a tree and counting books agrees with the original catalog size when the tree was built from that catalog.
* Paths and search work across multiple levels.

---

# Iteration 6 — Key-Value / Table Representation

## 6.1 Goal and Core Concepts

Association lists (tables) as a pure functional map. Build secondary indices for fast lookup by author or genre.

## 6.2 Required procedures

### Generic table

| Procedure | Contract |
|---|---|
| `empty-table` | → Table |
| `table-put` | Key × Value × Table → Table |
| `table-get` | Key × Table → Value \| #f |
| `table-has?` | Key × Table → Boolean |
| `table-remove` | Key × Table → Table |
| `table-keys` | Table → list of Key |
| `table-values` | Table → list of Value |
| `table-size` | Table → Integer |

### Domain indices

| Procedure | Contract | Purpose |
|---|---|---|
| `index-by-author` | Catalog → Table | Map author → list of books |
| `index-by-genre` | Catalog → Table | Map genre → list of books |
| `index-lookup` | Table × Key → list of Book | Books for a given key |
| `index-summary` | Table → list of (Key . Integer) | Counts per key |

## 6.3 Design notes (pseudocode)

```
table-put(key, value, table) =
  a new association list with the binding;
  any previous binding for the same key is replaced

index-by-author(catalog) =
  fold over the catalog, accumulating a table
  whose keys are authors and whose values are lists of books
```

## 6.4 Acceptance criteria

* Tables are immutable.
* Indices correctly group books.
* Lookup cost is linear in the number of distinct keys (alist), which should be discussed in the README.

---

# Iteration 7 — File I/O and Persistence

## 7.1 Goal and Core Concepts

Serialize a catalog to an external representation and restore it. Separate pure conversion from impure port operations.

## 7.2 Required procedures

### Pure conversion layer

| Procedure | Contract | Purpose |
|---|---|---|
| `book->sexp` | Book → S-expression | External form of a book |
| `catalog->sexp` | Catalog → S-expression | External form of a catalog |
| `sexp->book` | S-expression → Book \| #f | Inverse |
| `sexp->catalog` | S-expression → Catalog \| #f | Inverse |
| `catalog->report-lines` | Catalog → list of String | Pure report generation |

### Impure I/O (confined to `io.scm`)

| Procedure | Contract | Purpose |
|---|---|---|
| `save-catalog` | Catalog × String → Boolean | Write to file |
| `load-catalog` | String → Catalog \| #f | Read from file |
| `write-report` | Catalog × String → Boolean | Write a human-readable report |

## 7.3 Design notes (pseudocode)

```
book->sexp(b) =
  a list or vector that can be written with write
  and read back with read

catalog->report-lines(catalog) =
  a list of strings forming a readable summary
  (total count, average year, year range, counts by genre, …)
  — pure, therefore fully testable

save-catalog / load-catalog =
  open a port, write/read the s-expression, close the port;
  return success or failure
```

## 7.4 Acceptance criteria

* Round-trip property: loading a saved catalog yields an equal catalog.
* Report generation is pure.
* I/O failures are signalled by `#f` (or an appropriate result), not by uncaught exceptions in normal use.

---

# Iteration 8 — Complete Integrated Functional Information System

## 8.1 Goal and Core Concepts

Compose everything into a single application state. Provide sorting, grouping, statistics and a thin interactive / demo layer.

## 8.2 Required procedures

### Composition utilities

| Procedure | Contract |
|---|---|
| `identity` | A → A |
| `compose` | (B → C) × (A → B) → (A → C) |
| `pipe` | (A → B) … → (A → ?) |

### Sorting

| Procedure | Contract |
|---|---|
| `merge-sorted` | (A × A → Boolean) × list of A × list of A → list of A |
| `merge-sort` | (A × A → Boolean) × list of A → list of A |
| `sort-by` | (A → Key) × (Key × Key → Boolean) × list of A → list of A |
| `catalog-sort-by-year` | Catalog → Catalog |
| `catalog-sort-by-title` | Catalog → Catalog |
| `catalog-sort-by-author` | Catalog → Catalog |

### Grouping & statistics

| Procedure | Contract |
|---|---|
| `group-by` | (Book → Key) × Catalog → list of (Key . list of Book) |
| `catalog-statistics` | Catalog → Table |
| `top-n` | Integer × list of (Key . Integer) → list of (Key . Integer) |
| `most-prolific-author` | Catalog → String \| #f |
| `books-per-decade` | Catalog → list of (Integer . Integer) |

### Application state

| Procedure | Contract | Purpose |
|---|---|---|
| `make-app` | Catalog × Node → App | Construct application state |
| `app-catalog` | App → Catalog | Current catalog |
| `app-tree` | App → Node | Current category tree |
| `app-author-index` | App → Table | Derived index |
| `app-genre-index` | App → Table | Derived index |
| `app-add-book` | App × list of String × Book → App | Add book and rebuild derived data |
| `app-remove-book` | App × String → App | Remove by title and rebuild |
| `app-query` | App × (Book → Boolean) → list of Book | Query via predicate |
| `app-load` | String → App | Load from file |
| `app-save` | App × String → Boolean | Save to file |
| `run-demo` | → unspecified | Demonstration / menu (impure) |

## 8.3 Design notes (pseudocode)

```
pipe(f, g, h)(x) = h(g(f(x)))

merge-sort(less?, lst) =
  if length ≤ 1 then lst
  else split into two halves,
       recursively sort each half,
       merge the results stably

app-add-book(app, path, book) =
  new-catalog = catalog-add(book, app-catalog(app))
  new-tree    = tree-add-book(app-tree(app), path, book)
  rebuild indices from the new catalog
  return a new App containing all of the above
```

## 8.4 Acceptance criteria

* Sorting is stable and pure.
* Application state is immutable; every “update” returns a new App.
* Derived data (indices, tree) stay consistent after add/remove.
* A short demo that exercises the major features runs without error.

---

# 9. Code Style Guide

* Prefer small, single-purpose procedures.
* Name every intermediate value that is not immediately obvious.
* Keep the abstraction barrier absolute.
* Document every exported procedure with a contract.
* Prefer derivation (e.g. `all-match?` via De Morgan) over a fresh recursive definition when possible.
* Tests should cover ordinary cases, empty collections, missing keys, and boundary values.
* Never let a test depend on another test having run first.

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
* **Good (60–69).** All eight iterations work. Higher-order procedures are used where specified. Tests cover the ordinary cases.
* **Very good (70–79).** No duplication; generic procedures are genuinely generic. Layers are clean. Boundary cases are tested. `README.md` explains the design.
* **Excellent (80+).** Property-based tests. A defended representation choice. Complexity analysis. Extensions beyond the specification. Code that reads like an explanation of itself.

## 10.4 Submission checklist

- [ ] `src/` contains all source files, each loadable independently in dependency order.
- [ ] `test/run-all.scm` runs from the project root and reports **0 failures**.
- [ ] Every exported procedure has a contract comment.
- [ ] No `set!` in core layers (or every occurrence is justified in `README.md`).
- [ ] No `car`/`cdr` applied to a book outside `book.scm`.
- [ ] `data/sample-catalog.txt` (or equivalent) is present.
- [ ] `README.md` describes the design decisions and how to run the system.

---

# 11. Appendix A — Sample Dataset

Suggested fixture books (titles may be adjusted):

* Foundation — Isaac Asimov (1951) [sci-fi]
* I, Robot — Isaac Asimov (1950) [sci-fi]
* Dune — Frank Herbert (1965) [sci-fi]
* Neuromancer — William Gibson (1984) [cyberpunk]
* The Hobbit — J. R. R. Tolkien (1937) [fantasy]

Build the sample catalog with `catalog-from-list` (or successive `catalog-add`).

---

# 12. Appendix B — Optional Extensions

Attempt these only after every acceptance criterion is met. Each is worth bonus credit if documented in `README.md`.

| # | Extension | Concept exercised |
|---|---|---|
| B1 | Streams / lazy search | Lazy evaluation |
| B2 | A query DSL represented as data | Metalinguistic abstraction |
| B3 | Persistent balanced tree index | Persistent data structures |
| B4 | Generic dispatch for multiple media types | Data-directed programming |
| B5 | CSV import/export | Parsing without regular expressions |
| B6 | Property-based testing with random generators | Property-based testing |
| B7 | Undo history (list of past App states) | Practical payoff of persistence |
| B8 | Empirical complexity measurement of merge-sort | Higher-order instrumentation |

Extension B7 is especially illustrative: because every state is a value, undo reduces to taking the previous element of a history list.

---

*End of project specification.*
