default: format check test build examples

format:
    roc format

check:
    roc check src/main.roc

test:
    roc test src/main.roc

build:
    roc build --optimize src/main.roc

download script:
    curl -C - https://raw.githubusercontent.com/fabianishere/brain$(echo ZnVjawo= | base64 --decode)/master/examples/{{ script }}.bf --output examples/{{ script }}.bf --create-dirs

example script: (download script)
    src/brainroc examples/{{ script }}.bf

example_hello: (example "hello")
example_bottles: (example "bottles-3")
example_chess: (example "asciiart/chess")
example_triangle: (example "asciiart/triangle")
example_bench_1: (example "bench/bench-1")
example_bench_2: (example "bench/bench-2")

examples: example_hello example_bottles example_chess example_triangle example_bench_1 example_bench_2
