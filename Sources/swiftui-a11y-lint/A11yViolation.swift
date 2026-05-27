struct A11yViolation: Equatable {
    enum Kind: Equatable {
        case missingLabel
        case emptyLabel
    }

    let file: String
    let line: Int
    let column: Int
    let typeName: String
    let kind: Kind

    var description: String {
        switch kind {
        case .missingLabel:
            return "\(file):\(line):\(column): warning: `\(typeName)` does not have an accessibility label."
        case .emptyLabel:
            return "\(file):\(line):\(column): warning: `\(typeName)` has an accessibility label but it is empty."
        }
    }
}
