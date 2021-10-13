## Development

To generate bindings with ffigen use (adjust paths to yours):

```bash
dart run ffigen --compiler-opts "-I/path/to/libgit2dart/libgit2/headers/ -I/lib64/clang/12.0.1/include"
```

## Running Tests

To run all tests and generate coverage report use the following commands:

```sh
$ dart pub global activate coverage
$ dart test --coverage="coverage"
$ format_coverage --lcov --check-ignore --in=coverage --out=coverage/lcov.info --packages=.packages --report-on=lib
```

To view the generated coverage report you can use [lcov](https://github.com/linux-test-project/lcov):

```sh
$ genhtml coverage/lcov.info -o coverage/
$ open coverage/index.html
```
