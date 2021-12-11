#!/usr/bin/env sbcl --script

(let
    (
        ; Define the characters using the 'char function (and thus require the 'cons and 'list
        ; functions) instead of character literals & alist literals because the "bracket pair
        ; colorizer" extension doesn't understand Lisp's character literal syntax and totally breaks.
        ; It correctly handles strings, though.

        ; Define open and close mappings
        (pairs
            (list
                (cons (char ")" 0) (char "(" 0))
                (cons (char "}" 0) (char "{" 0))
                (cons (char "]" 0) (char "[" 0))
                (cons (char ">" 0) (char "<" 0))
            )
        )

        ; Point mappings
        (points
            (list
                (cons (char ")" 0) 3)
                (cons (char "]" 0) 57)
                (cons (char "}" 0) 1197)
                (cons (char ">" 0) 25137)
            )
        )

        (lines
            (with-open-file
                (in #p"input.txt")
                (loop for line = (read-line in nil nil)
                    while line
                    collect (coerce line 'string)
                )
            )
        )

        (score 0)
    )

    (loop for line in lines do 
        (let ((stack ()))
            (loop for c across line
                while (if (null (assoc c pairs))
                    ; This character is an opening brace, not close
                    (progn (push c stack) T)
                    ; This character is a closing brace, not open
                    (if (not (eql c (car (rassoc (pop stack) pairs))))
                        ; Invalid closing brace
                        (progn
                            ; Ddd the score of the invalid line
                            (setf score (+ score (cdr (assoc c points))))
                            ; Return false to halt the execution of this line
                            nil
                        )
                        ; This closing brace is fine
                        T
                    )
                )
            )
        )
    )

    (print score)
    (princ #\Newline)
)
