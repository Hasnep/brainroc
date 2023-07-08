interface Tokeniser exposes [Token, tokenise] imports []

Token : [
    IncrementPointer,
    DecrementPointer,
    IncrementByte,
    DecrementByte,
    Output,
    JumpForward,
    JumpBack,
    Comment,
]

tokenise : Str -> List Token
tokenise = \source ->
    source
    |> Str.graphemes
    |> List.map
        (
            \c ->
                when c is
                    ">" -> IncrementPointer
                    "<" -> DecrementPointer
                    "+" -> IncrementByte
                    "-" -> DecrementByte
                    "." -> Output
                    "[" -> JumpForward
                    "]" -> JumpBack
                    _ -> Comment
        )
