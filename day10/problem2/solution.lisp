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
                (cons (char ")" 0) 1)
                (cons (char "]" 0) 2)
                (cons (char "}" 0) 3)
                (cons (char ">" 0) 4)
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

        (scores ())
    )

    (loop for line in lines do 
        (let ((stack ()) (corrupt nil))
            (loop for c across line
                while (if (null (assoc c pairs))
                    ; This character is an opening brace, not close
                    (progn (push c stack) T)
                    ; This character is a closing brace, not open
                    (if (not (eql c (car (rassoc (pop stack) pairs))))
                        ; Invalid closing brace, ignore
                        ; Set corrupt to false to show that it is bad
                        (progn (setf corrupt T) nil)
                        ; This closing brace is fine
                        T
                    )
                )
            )

            (if (not corrupt)
                ; Calculate and store this score value
                (let 
                    ((score 0))

                    (loop for c in stack do
                        (setf score
                            ; score = (5 * score) + points
                            (+
                                ; Multiply the current score by 5
                                (* 5 score)
                                ; Find the cost of the closing brace we need to add
                                (cdr (assoc
                                    ; Find the closing brace which goes with the open brace
                                    ; that is at this place on the stack
                                    (car (rassoc c pairs))
                                    points
                                ))
                            )
                        )
                    )

                    (push score scores)
                )
            )
        )
    )

    ; Find the median score value
    (let ((sorted (sort scores '>)))
        (print
            (nth
                ; (sorted.length - 1) / 2
                (/
                    (- (length sorted) 1)
                    2
                )
                sorted
            )
        )
    )

    (princ #\Newline)
)
