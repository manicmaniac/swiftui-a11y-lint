import SwiftSyntax
import SwiftParser

struct A11yChecker {
    var additionalTypes: Set<String> = []

    func check(source: String, file: String) -> [A11yViolation] {
        let sourceFile = Parser.parse(source: source)
        let converter = SourceLocationConverter(fileName: file, tree: sourceFile)
        let visitor = A11yVisitor(file: file, converter: converter, additionalTypes: additionalTypes)
        visitor.walk(sourceFile)
        return visitor.violations
    }
}

private final class A11yVisitor: SyntaxVisitor {
    let file: String
    let converter: SourceLocationConverter
    var violations: [A11yViolation] = []
    let checkedTypes: Set<String>

    static let defaultCheckedTypes: Set<String> = ["Image", "AsyncImage"]

    init(file: String, converter: SourceLocationConverter, additionalTypes: Set<String> = []) {
        self.file = file
        self.converter = converter
        self.checkedTypes = Self.defaultCheckedTypes.union(additionalTypes)
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        guard let callee = node.calledExpression.as(DeclReferenceExprSyntax.self),
              checkedTypes.contains(callee.baseName.text) else {
            return .visitChildren
        }

        let typeName = callee.baseName.text

        if node.arguments.contains(where: { $0.label?.text == "decorative" || $0.label?.text == "label" }) {
            return .visitChildren
        }

        if isInsideLabelClosure(node) {
            return .visitChildren
        }

        let location = converter.location(for: node.positionAfterSkippingLeadingTrivia)

        switch findLabelStatus(from: node) {
        case .none:
            violations.append(A11yViolation(
                file: file, line: location.line, column: location.column,
                typeName: typeName, kind: .missingLabel
            ))
        case .some(.empty):
            violations.append(A11yViolation(
                file: file, line: location.line, column: location.column,
                typeName: typeName, kind: .emptyLabel
            ))
        case .some(.nonEmpty), .some(.hidden):
            break
        }

        return .visitChildren
    }

    private enum LabelStatus { case empty, nonEmpty, hidden }

    private func isInsideLabelClosure(_ node: some SyntaxProtocol) -> Bool {
        var current: Syntax = Syntax(node)
        while let parent = current.parent {
            if let call = parent.as(FunctionCallExprSyntax.self),
               let callee = call.calledExpression.as(DeclReferenceExprSyntax.self),
               callee.baseName.text == "Label" {
                return true
            }
            current = parent
        }
        return false
    }

    private func findLabelStatus(from imageCall: FunctionCallExprSyntax) -> LabelStatus? {
        var current: Syntax = Syntax(imageCall)
        while let parent = current.parent {
            guard let memberAccess = parent.as(MemberAccessExprSyntax.self) else { break }
            let name = memberAccess.declName.baseName.text
            if name == "accessibilityLabel" {
                guard let outerCall = memberAccess.parent?.as(FunctionCallExprSyntax.self) else {
                    return .nonEmpty
                }
                if let arg = outerCall.arguments.first {
                    return isEmptyStringLiteral(arg.expression) ? .empty : .nonEmpty
                }
                return .nonEmpty
            }
            if name == "accessibilityHidden" {
                if let outerCall = memberAccess.parent?.as(FunctionCallExprSyntax.self),
                   let arg = outerCall.arguments.first,
                   let bool = arg.expression.as(BooleanLiteralExprSyntax.self),
                   bool.literal.text == "true" {
                    return .hidden
                }
            }
            guard let outerCall = memberAccess.parent?.as(FunctionCallExprSyntax.self) else { break }
            current = Syntax(outerCall)
        }
        return nil
    }

    private func isEmptyStringLiteral(_ expr: ExprSyntax) -> Bool {
        if let call = expr.as(FunctionCallExprSyntax.self),
           let callee = call.calledExpression.as(DeclReferenceExprSyntax.self),
           callee.baseName.text == "Text",
           let inner = call.arguments.first?.expression {
            return isEmptyStringLiteral(inner)
        }
        guard let lit = expr.as(StringLiteralExprSyntax.self) else { return false }
        for segment in lit.segments {
            switch segment {
            case .stringSegment(let s) where !s.content.text.isEmpty:
                return false
            case .expressionSegment:
                return false
            default:
                break
            }
        }
        return true
    }
}
