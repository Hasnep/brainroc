interface Parser exposes [Ast, parseAll] imports [Tokeniser.{ Token }]

Ast : [
    IncrementPointer,
    DecrementPointer,
    IncrementByte,
    DecrementByte,
    Output,
    Block (List Ast),
]

ParserState : { tokens : List Token, ast : [Block (List Ast)] }

parse : ParserState -> ParserState
parse = \{ tokens, ast: Block children } ->
    when (List.first tokens, List.dropFirst tokens) is
        (Ok IncrementPointer, rest) -> parse { tokens: rest, ast: children |> List.append IncrementPointer |> Block }
        (Ok DecrementPointer, rest) -> parse { tokens: rest, ast: children |> List.append DecrementPointer |> Block }
        (Ok IncrementByte, rest) -> parse { tokens: rest, ast: children |> List.append IncrementByte |> Block }
        (Ok DecrementByte, rest) -> parse { tokens: rest, ast: children |> List.append DecrementByte |> Block }
        (Ok Output, rest) -> parse { tokens: rest, ast: children |> List.append Output |> Block }
        (Ok JumpForward, rest) ->
            { tokens: restRest, ast: loopAst } = parse { tokens: rest, ast: Block [] }
            parse { tokens: restRest, ast: children |> List.append loopAst |> Block }

        (Ok JumpBack, rest) -> { tokens: rest, ast: Block children }
        (Ok Comment, rest) -> parse { tokens: rest, ast: Block children }
        (Err ListWasEmpty, _) -> { tokens: [], ast: Block children }

expect
    out = parse { tokens: [], ast: Block [] }
    out == { tokens: [], ast: Block [] }

expect
    out = parse { tokens: [Comment], ast: Block [] }
    out == { tokens: [], ast: Block [] }

expect
    out = parse { tokens: [IncrementPointer, DecrementPointer], ast: Block [] }
    out == { tokens: [], ast: Block [IncrementPointer, DecrementPointer] }

expect
    out = parse { tokens: [DecrementPointer], ast: Block [IncrementPointer] }
    out == { tokens: [], ast: Block [IncrementPointer, DecrementPointer] }

expect
    out = parse { tokens: [JumpForward, IncrementPointer, DecrementPointer, JumpBack], ast: Block [] }
    out == { tokens: [], ast: Block [Block [IncrementPointer, DecrementPointer]] }

expect
    out = parse { tokens: [IncrementPointer, JumpForward, IncrementPointer, DecrementPointer, JumpBack, DecrementPointer], ast: Block [] }
    out == { tokens: [], ast: Block [IncrementPointer, Block [IncrementPointer, DecrementPointer], DecrementPointer] }

parseAll : List Token -> [Block (List Ast)]
parseAll = \tokens ->
    when parse { tokens: tokens, ast: Block [] } is
        { tokens: [], ast: Block ast } -> Block ast
        _ -> crash "oh no"
