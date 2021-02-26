#lang racket
; (provide expr-compare)
(provide (all-defined-out))

#| Expressions allows (subset of Racket expressions)

literal constants - #t, #f, 4, 2.3, ...
identifiers [variables] -> if x bounds X in same place y bounds Y, should refer as X!Y from then on; bounded variables are declared in lambda constructs

function calls - (<fn> <expr> <expr> ...) ; <fn> can be either an identifier or a lambda expression
special forms
    (quote <s-expr>)
    (lambda <formals> <expr>)
    (LAMBDA <formals> <body>)
    (if <expr> <expr> <expr>)

|#

;;; determines if symbol x is a lambda symbol
(define (lambda? x) (member x '(lambda λ)))

;;; used for testing, since my terminal can't take λ as input 
(define LAMBDA 'λ)

;;; compares two expressions 'x' and 'y' given that the variables bound under this scope are 'bvars'
(define (expr-compare-help x y bvars)
    (cond [(and (pair? x) (pair? y)) (form-compare x y bvars)] ; pair? for non-empty lists - input will never be improper list so don't have to worry about that
        [else (term-compare x y bvars)])) ; if one is a list and the other isn't, term-compare will handle properly

;;; compares two expressions at the top-level, when there are no bound variables yet
(define (expr-compare x y) (expr-compare-help x y '()))

;;; matches a term (could be identifier or literal constant) with a bound variable in bvars
;;; if no match, just return the original term
;;; side determines if term should bind with the LHS or RHS of the '!' in a bound variable
;;; side is 0 for LHS and should be used as such for x expressions
;;; side is 1 for RHS and should be used as such for y expressions
(define (match-term term side bvars)
    (if (not (symbol? term)) 
        term ; if term is not a symbol, then it's not an identifier (variable), so return it immediately
        (let (
            [matched-var (findf ; findf searches left to right, so variable shadowing can occur
                (lambda (bvar) 
                    (let ([bvar-sides (map string->symbol (string-split (symbol->string bvar) "!"))])
                        (if (null? (cdr bvar-sides)) ; if there was no ! in bvar
                            (eq? term (car bvar-sides)) ; compare term with bvar
                            (eq? term (list-ref bvar-sides side))))) ; compare term with the correct side of bvar
                bvars)])
            (if matched-var matched-var term)))) ; if term didn't match anything in bvars, return original term

;;; compares expressions that aren't lists, which I'm calling a 'term'
(define (term-compare x y bvars) 
    (let ([x (match-term x 0 bvars)] [y (match-term y 1 bvars)]) ; check if x or y is a bound variable
        (cond [(eq? x y) x]
            [(and (boolean? x) (boolean? y)) (if x '% '(not %))] ; special case where we compare booleans with '% or '(not %)
            [else `(if % ,x ,y)])))

;;; compares expressions that are lists, which I'm calling a 'form'
;;; forms can be function calls or any of the special forms: λ, lambda, if, quote
(define (form-compare x y bvars)
    (let ([xf (match-term (car x) 0 bvars)] [yf (match-term (car y) 1 bvars)]) ; get the first element of the list, which is the type of form, but also see if it's a bound variable, in which case, func-call
        (cond 
            [(not (= (length x) (length y))) (quote-compare x y)] ; different length, so are fundamentally different
            [(let ([specials '(λ lambda if quote)]) (or (member xf specials) (member yf specials))) (special-form-compare x y bvars)]
            [else (func-call-compare x y bvars)]
        )))

;;; compares expressions that are forms but not special forms, i.e. function calls
(define (func-call-compare x y bvars)
    (let ([xf (car x)] [yf (car y)] [xargs (cdr x)] [yargs (cdr y)])
        (cons 
            (expr-compare-help xf yf bvars) ; procedures are expressions - xf or yf could be lambda expressions, which themselves evaluate to 'procedures', also could be bound variables
            (args-compare xargs yargs bvars))))

;;; compares arguments of function calls individually, which could be any form of expression
;;; reused for comparing formals in lambda-compare, even though formals are a subset (they're all just identifiers) of expressions, which this function can handle 
(define (args-compare xargs yargs bvars)
    (cond
        [(or (null? xargs) (null? yargs)) '()] ; wouldn't do well on its own because loses information when one is null and other isn't, but lengths should be the same because of form-compare
        [else (cons (expr-compare-help (car xargs) (car yargs) bvars) (args-compare (cdr xargs) (cdr yargs) bvars))]))

;;; compares expressions where at least one is a special form
(define (special-form-compare x y bvars)
    (let ([xf (car x)] [yf (car y)])
        (cond [(and (lambda? yf) (lambda? xf)) (lambda-compare x y bvars)] ; they're lambda's (either lambda or λ)
            [(not (eq? xf yf)) (quote-compare x y)] ; if special form is not the same as the other form, they're fundamentally different and should be quote-compare'd
            [(eq? xf 'quote) (quote-compare x y)] ; if quote, these are different unless completely equal, so should be quote-compare'd
            [(eq? xf 'if) (func-call-compare x y bvars)]; 'if can be handled like a function call, since it's (if <expr> <expr> <expr>), but is still a special form because '(if x y z) is completely different from '(g x y z)
        )))

;;; compares quoted expressions
;;; reused for many other situations when x and y are completely different expressions and their comparisons need to be returned as such
(define (quote-compare x y)
    (cond [(equal? x y) x]
        [else `(if % ,x ,y)]))

;;; compares lambda expressions
(define (lambda-compare x y bvars)
    (let ([xformals (cadr x)] [yformals (cadr y)] [xbody (caddr x)] [ybody (caddr y)]) ; formals are the second, body is the third, element of lambda expressions
        (if (not (= (length xformals) (length yformals)))
            (quote-compare x y) ; if formals of different length, different expressions
            (let ([bvars (gen-bvars xformals yformals bvars)]) ; generate new bound variables, given the new variables in xformals and yformals
                (list 
                    (if (and (eq? (car x) 'lambda) (eq? (car y) 'lambda)) 'lambda 'λ) ; only outputs 'lambda if both expressions use it, otherwise, 'λ
                    (args-compare xformals yformals bvars) ; comparing formals here includes the new bound variables 
                    (expr-compare-help xbody ybody bvars)))))) ; the bodies are expressions, so compare them with the new bound variables included

;;; appends new bound variables onto bvars using xformals and yformals and returns the new bvars
(define (gen-bvars xformals yformals bvars)
    (cond [(or (null? xformals) (null? yformals)) bvars] ; the lengths of formals are always equal, so could actually use (and), but (or) is slightly faster
        [else 
            (gen-bvars ; make a bound variable out of the first elements, append it to bvars, and recursively call itself with cdr of formals
                (cdr xformals) 
                (cdr yformals) 
                (cons (make-bvar (car xformals) (car yformals)) bvars))]))

;;; create a new bounded variable out of xvar and yvar, i.e. 'xvar!yvar if they're different
(define (make-bvar xvar yvar)
    (if (eq? xvar yvar) 
        xvar
        (string->symbol (string-append (symbol->string xvar) "!" (symbol->string yvar)))))

;;; test the outputs of (expr-compare x y)
(define (test-expr-compare x y) 
    (and 
        (equal? (eval x) (eval `(let ((% #t)) ,(expr-compare x y))))
        (equal? (eval y) (eval `(let ((% #f)) ,(expr-compare x y))))))

;;; last and longest test case from the spec 
(define (test-long) (expr-compare 
    '((lambda (a) 
        (eq? a 
            ((λ (a b) 
                ((λ (a b) (a b)) b a)) a (lambda (a) a)))) 
    (lambda (b a) (b a)))
    '((λ (a) 
        (eqv? a 
            ((lambda (b a) 
                ((lambda (a b) (a b)) b a)) a (λ (b) a)))) 
    (lambda (a b) (a b)))))

;;; last and longest test case from the TA's that's even longer
(define (test-superlong) (expr-compare '(((λ (g)
                   ((λ (x) (g (λ () (x x))))
                    (λ (x) (g (λ () (x x))))))
                 (λ (r)
                   (λ (n) (if (= n 0)
                              1
                              (* n ((r) (- n 1)))))))
                10)
              '(((λ (x)
                   ((λ (n) (x (λ () (n n))))
                    (λ (r) (x (λ () (r r))))))
                 (λ (g)
                   (λ (x) (if (= x 0)
                              1
                              (* x ((g) (- x 1)))))))
                9)))

;;; these two test cases cover a lot of ground
;;; correct output of lambda expressions when one uses λ
;;; shadowing of variables (even for special forms) - here a lambda expression has a formal called lambda, and in the body calls lambda in the same form as a special form lambda call, but is bound, so we don't bind with the second elemnent
;;; comparing boolean expressions correctly - (expr-compare #f #t) => (not %)
;;; difference between (if x y z) and (gif x y z)
;;; (quote ...), where equal? and where not equal?
;;; using variables that are just outside the scope of where they would be binded (if and lambda, here)
;;; lambda expression where the body is the same but the formals are different size, so they're completely different
;;; 'inverted' bound variable - x uses b and y uses a, where a bound variable is a!b, so don't match it
;;; lambda is a bound variable, but can still use λ to create a lambda expression, and vice-versa
(define test-expr-x 
    '((lambda (lambda if q) (lambda (c) (λ (arg) lambda))) ; c is not binded to d below, since lambda is now a bound variable, not the special form. However, can use λ as a special form, because only lambda is binded
        (lambda (a) 
            (if #f 
                (list 
                    q ; is a shared bound variable
                    else ; else is not bound here, since the bound variable is if!else, so else is a top-level identifier
                    '(a b) 
                    (if x if q)) ; even though if is bound to else, (if ...) is completely different to (gif ...), so don't match them
                (quoth a '(a)))) ; a is a bound variable here (a!b)
        (if if (λ (arg) (+ arg λ)) 18.1)
        (lambda (dog) (+ dog))))
        
(define test-expr-y 
    '((λ (λ else q) (λ (d) (lambda (arg) lambda))) ; d is not binded to c above, since λ is now a bound variable, not the special form. However, can use lambda as a special form, because only λ is binded
        (lambda (b) 
            (if #t 
                (cons 
                    q ; is a shared bound variable
                    if ; if is not bound here, since the bound variable is if!else, so if is a top-level identifier
                    '(a c) 
                    (gif x else q)) 
                (quoth a '(a)))) ; a is not a bound variable here
        (if lambda (lambda (arg) (+ arg λ)) 18)
        (λ (dog cat) (+ dog))))

(define (test-mine) (expr-compare test-expr-x test-expr-y))

(define my-program '(display "You have entered The Matrix\n"))

; namespace
; run the file as racket hello.ss
; or click run in DrRacket
(define ns (make-base-namespace))
(eval my-program ns)
