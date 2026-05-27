# static-a11y-checker

A command-line tool to check if accessibility labels are set on SwiftUI `Image`, `AsyncImage` and so on.

## Usage

```
static-a11y-checker <FILE...>
```

## Examples

```
$ static-a11y-checker ContentView.swift
/path/to/ContentView.swift:30:9 `Image` does not have an accessibility label.
/path/to/ContentView.swift:60:13 `AsyncImage` has an accessiblity label but it is empty.
```

