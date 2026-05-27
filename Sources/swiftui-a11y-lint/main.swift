import Foundation

var additionalTypes: Set<String> = []
var filePaths: [String] = []
let args = Array(CommandLine.arguments.dropFirst())
var i = 0

while i < args.count {
    if args[i] == "--type", i + 1 < args.count {
        additionalTypes.insert(args[i + 1])
        i += 2
    } else {
        filePaths.append(args[i])
        i += 1
    }
}

var checker = A11yChecker()
checker.additionalTypes = additionalTypes
var hasViolations = false

for path in filePaths {
    guard let source = try? String(contentsOfFile: path, encoding: .utf8) else {
        fputs("Error: Cannot read '\(path)'\n", stderr)
        continue
    }
    for violation in checker.check(source: source, file: path) {
        print(violation.description)
        hasViolations = true
    }
}

exit(hasViolations ? 1 : 0)
