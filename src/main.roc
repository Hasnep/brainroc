app "brainroc"
    packages {
        pf: "https://github.com/roc-lang/basic-cli/releases/download/0.3.2/tE4xS_zLdmmxmHwHih9kHWQ7fsXtJr7W7h3425-eZFk.tar.br",
    }
    imports [
        pf.Arg,
        pf.File,
        pf.Path,
        pf.Stdout,
        pf.Task,
        Interpreter,
        Parser,
        Tokeniser,
    ]
    provides [main] to pf

main =
    parser =
        Arg.str { name: "input", help: "The BF file to be interpreted." }
        |> Arg.program { name: "brainroc", help: "A BF interpreter." }

    # Get a list of the commandline arguments passed to the program
    args <- Arg.list |> Task.await

    # Parse the commandline arguments
    when Arg.parseFormatted parser (args) is
        Ok inputFilePath ->
            # Read the input file
            inputResult <- inputFilePath |> Path.fromStr |> File.readUtf8 |> Task.attempt
            when inputResult is
                # Run the interpreter
                Ok source -> source |> Tokeniser.tokenise |> Parser.parseAll |> Interpreter.runAll |> Stdout.line
                Err (FileReadErr _ _) -> "Failed to read the input file `\(inputFilePath)`." |> Stdout.line
                Err (FileReadUtf8Err _ _) -> "Input file `\(inputFilePath)` did not contain valid UTF-8." |> Stdout.line

        # Show the help information
        Err helpInfo -> helpInfo |> Stdout.line
