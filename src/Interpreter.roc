interface Interpreter exposes [runAll] imports [Parser.{ Ast }, Tokeniser, Parser]

## The number of cells in the interpreter's stream.
streamLength : Nat
streamLength = 30_000

InterpreterState : {
    ast : [Block (List Ast)],
    currentCommand : Nat,
    pointer : Nat,
    stream : List U8,
    output : List U8,
}

## Construct an interpreter state from an AST.
fromAst : [Block (List Ast)] -> InterpreterState
fromAst = \ast -> {
    ast: ast,
    currentCommand: 0,
    pointer: 0,
    stream: List.repeat 0 streamLength,
    output: [],
}

## Increment the pointer, wrapping back to 0 if it reaches the end of the stream.
incrementPointer : InterpreterState -> InterpreterState
incrementPointer = \bf -> { bf & pointer: bf.pointer |> Num.addChecked 1 |> Result.withDefault 0 }

## Decrement the pointer, wrapping to the last element if it underflows.
decrementPointer : InterpreterState -> InterpreterState
decrementPointer = \bf -> { bf & pointer: bf.pointer |> Num.subChecked 1 |> Result.withDefault (streamLength - 1) }

## Update the byte at the pointer with a callback function.
updateByte : InterpreterState, (U8 -> U8) -> InterpreterState
updateByte = \bf, updateFunction -> { bf & stream: bf.stream |> List.update bf.pointer updateFunction }

## Increment the byte at the pointer position, wrapping if the byte overflows.
incrementByte : InterpreterState -> InterpreterState
incrementByte = \bf -> bf |> updateByte (\n -> n |> Num.addWrap 1)

## Decrement the byte at the pointer position, wrapping if the byte underflows.
decrementByte : InterpreterState -> InterpreterState
decrementByte = \bf -> bf |> updateByte (\n -> n |> Num.subWrap 1)

## Move the interpreter to the next command.
goToNextCommand : InterpreterState -> InterpreterState
goToNextCommand = \bf -> { bf & currentCommand: bf.currentCommand + 1 }

## Get the value of the stream at the pointer position.
getCurrentCell : InterpreterState -> U8
getCurrentCell = \bf ->
    when bf.stream |> List.get bf.pointer is
        Ok x -> x
        Err OutOfBounds -> crash "This should never happen because the pointer is always in bounds."

## Run a block of instructions.
run : InterpreterState -> InterpreterState
run = \bf ->
    (Block children) = bf.ast
    when (children |> List.get bf.currentCommand) is
        Ok IncrementPointer -> bf |> incrementPointer |> goToNextCommand |> run
        Ok DecrementPointer -> bf |> decrementPointer |> goToNextCommand |> run
        Ok IncrementByte -> bf |> incrementByte |> goToNextCommand |> run
        Ok DecrementByte -> bf |> decrementByte |> goToNextCommand |> run
        Ok Output -> { bf & output: bf.output |> List.append (getCurrentCell bf) } |> goToNextCommand |> run
        Ok (Block blockAst) ->
            if (getCurrentCell bf) == 0 then
                # If the current cell is zero, skip over the block and do nothing
                bf |> goToNextCommand |> run
            else
                # Run the block and get the new state after running the block
                bfNew = { bf & ast: Block blockAst, currentCommand: 0 } |> run
                # Return to the instructions before we started running the block and try running it again
                { bfNew & ast: bf.ast, currentCommand: bf.currentCommand } |> run

        # When we reach the final instruction, return the state of the interpreter
        Err OutOfBounds -> bf

expect
    out = (Block []) |> fromAst |> run
    List.all out.stream (\x -> x == 0)

expect
    out = Block [IncrementByte, IncrementByte, IncrementByte] |> fromAst |> run
    out.stream |> List.sublist { start: 0, len: 3 } == [3, 0, 0]

expect
    out = Block [IncrementByte, DecrementByte, IncrementByte] |> fromAst |> run
    out.stream |> List.sublist { start: 0, len: 3 } == [1, 0, 0]

expect
    out = Block [IncrementPointer, IncrementByte] |> fromAst |> run
    out.stream |> List.sublist { start: 0, len: 3 } == [0, 1, 0]

expect
    out =
        Block [
            IncrementByte,
            IncrementByte,
            IncrementByte,
            Block [IncrementPointer, IncrementByte, DecrementPointer, DecrementByte],
        ]
        |> fromAst
        |> run
    out.stream |> List.sublist { start: 0, len: 3 } == [0, 3, 0]

expect
    out = Block [DecrementByte, IncrementPointer, DecrementByte, IncrementByte] |> fromAst |> run
    out.stream |> List.sublist { start: 0, len: 3 } == [255, 0, 0]

expect
    out =
        Block [
            IncrementByte,
            IncrementByte,
            IncrementByte,
            Block [DecrementByte],
            IncrementPointer,
            IncrementByte,
        ]
        |> fromAst
        |> run
    out.stream |> List.sublist { start: 0, len: 3 } == [0, 1, 0]

## Run an AST and return the output stream, interpreted as UTF-8 code units.
runAll : [Block (List Ast)] -> Str
runAll = \ast ->
    outputStream = (ast |> fromAst |> run).output
    outputStream |> Str.fromUtf8 |> Result.withDefault "" |> Str.trimEnd

expect
    out =
        "++++++++[>++++[>++>+++>+++>+<<<<-]>+>+>->>+[<]<-]>>.>---.+++++++..+++.>>.<-.<.+++.------.--------.>>+.>++."
        |> Tokeniser.tokenise
        |> Parser.parseAll
        |> runAll
    out == "Hello World!"
