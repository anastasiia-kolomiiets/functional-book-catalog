;;; ============================================================================
;;; test-framework.scm — a small, purely functional test harness.
;;; ============================================================================

;; check : String Any Any -> Result
;; Compares ACTUAL against EXPECTED using equal?.
(define (check name expected actual)
  (list name (equal? expected actual) expected actual))

;; check-true : String Any -> Result
;; Passes when ACTUAL is any true value.  Normalizes to #t so that a failure
;; report shows a boolean rather than an opaque value.
(define (check-true name actual)
  (check name #t (if actual #t #f)))

;; check-false : String Any -> Result
;; Passes when ACTUAL is #f.
(define (check-false name actual)
  (check name #f (if actual #t #f)))


;;; ----------------------------------------------------------------------------
;;; Selectors
;;; ----------------------------------------------------------------------------

;; result-name : Result -> String
(define (result-name     r) (car r))
;; result-passed? : Result -> Boolean
(define (result-passed?  r) (cadr r))
;; result-expected : Result -> Any
(define (result-expected r) (caddr r))
;; result-actual : Result -> Any
(define (result-actual   r) (cadddr r))


;;; ----------------------------------------------------------------------------
;;; Reporting
;;; ----------------------------------------------------------------------------

;; report-result : Result -> unspecified
;; Prints one line for a pass, or three for a failure.
(define (report-result r)
  (if (result-passed? r)
      (begin (display "  PASS  ") (display (result-name r)) (newline))
      (begin (display "  FAIL  ") (display (result-name r)) (newline)
             (display "        expected: ") (write (result-expected r)) (newline)
             (display "        actual:   ") (write (result-actual   r)) (newline))))

;; count-passed : (listof Result) -> Integer
;; How many of RESULTS passed.  Tail recursive.
(define (count-passed results)
  (let loop ((rs results) (n 0))
    (cond ((null? rs) n)
          ((result-passed? (car rs)) (loop (cdr rs) (+ n 1)))
          (else (loop (cdr rs) n)))))

;; run-suite : String (listof Result) -> Integer
;; Prints every result in RESULTS under the heading TITLE, then a tally.
;; Returns the number of FAILURES, so that callers can sum them.
(define (run-suite title results)
  (display "== ") (display title) (newline)
  (for-each report-result results)
  (let ((total  (length results))
        (passed (count-passed results)))
    (display "   ") (display passed) (display "/") (display total)
    (display " passed") (newline) (newline)
    (- total passed)))
