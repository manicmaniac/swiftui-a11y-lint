import Testing
@testable import swiftui_a11y_lint

@Suite struct A11yCheckerTests {
    let checker = A11yChecker()

    @Test func imageWithoutLabelHasMissingLabelViolation() {
        let source = #"Image("cat")"#
        let violations = checker.check(source: source, file: "test.swift")
        #expect(violations.count == 1)
        #expect(violations[0].typeName == "Image")
        #expect(violations[0].kind == .missingLabel)
        #expect(violations[0].line == 1)
        #expect(violations[0].column == 1)
    }

    @Test func imageWithValidLabelHasNoViolation() {
        let source = #"Image("cat").accessibilityLabel("A cat")"#
        let violations = checker.check(source: source, file: "test.swift")
        #expect(violations.isEmpty)
    }

    @Test func imageWithEmptyLabelHasEmptyLabelViolation() {
        let source = #"Image("cat").accessibilityLabel("")"#
        let violations = checker.check(source: source, file: "test.swift")
        #expect(violations.count == 1)
        #expect(violations[0].kind == .emptyLabel)
    }

    @Test func imageWithLabelArgumentHasNoViolation() {
        let source = #"Image("cat", label: Text("A cat"))"#
        let violations = checker.check(source: source, file: "test.swift")
        #expect(violations.isEmpty)
    }

    @Test func decorativeImageHasNoViolation() {
        let source = #"Image(decorative: "bg")"#
        let violations = checker.check(source: source, file: "test.swift")
        #expect(violations.isEmpty)
    }

    @Test func asyncImageWithoutLabelHasMissingLabelViolation() {
        let source = #"AsyncImage(url: URL(string: "https://example.com"))"#
        let violations = checker.check(source: source, file: "test.swift")
        #expect(violations.count == 1)
        #expect(violations[0].typeName == "AsyncImage")
        #expect(violations[0].kind == .missingLabel)
    }

    @Test func imageWithChainedModifiersAndValidLabelHasNoViolation() {
        let source = #"Image("cat").resizable().accessibilityLabel("A cat")"#
        let violations = checker.check(source: source, file: "test.swift")
        #expect(violations.isEmpty)
    }

    @Test func systemNameImageWithChainedModifiersAndJapaneseLabelHasNoViolation() {
        let source = """
                            Image(systemName: "chevron.backward")
                                .font(.system(size: 18))
                                .accessibilityLabel("戻る")
        """
        let violations = checker.check(source: source, file: "test.swift")
        #expect(violations.isEmpty)
    }

    @Test func customTypeWithoutLabelHasMissingLabelViolation() {
        let source = #"AsyncCachedImage(url: someURL)"#
        let checker = A11yChecker(additionalTypes: ["AsyncCachedImage"])
        let violations = checker.check(source: source, file: "test.swift")
        #expect(violations.count == 1)
        #expect(violations[0].typeName == "AsyncCachedImage")
        #expect(violations[0].kind == .missingLabel)
    }

    @Test func customTypeWithValidLabelHasNoViolation() {
        let source = #"AsyncCachedImage(url: someURL).accessibilityLabel("image")"#
        let checker = A11yChecker(additionalTypes: ["AsyncCachedImage"])
        let violations = checker.check(source: source, file: "test.swift")
        #expect(violations.isEmpty)
    }

    @Test func customTypeIsIgnoredWithoutFlag() {
        let source = #"AsyncCachedImage(url: someURL)"#
        let violations = checker.check(source: source, file: "test.swift")
        #expect(violations.isEmpty)
    }

    @Test func imageInsideLabelIconClosureHasNoViolation() {
        let source = """
        Label {
            Text("戻る")
        } icon: {
            Image(systemName: "chevron.backward")
        }
        """
        let violations = checker.check(source: source, file: "test.swift")
        #expect(violations.isEmpty)
    }

    @Test func imageWithAccessibilityHiddenTrueHasNoViolation() {
        let source = #"Image("bg").accessibilityHidden(true)"#
        let violations = checker.check(source: source, file: "test.swift")
        #expect(violations.isEmpty)
    }

    @Test func imageWithAccessibilityHiddenFalseHasMissingLabelViolation() {
        let source = #"Image("cat").accessibilityHidden(false)"#
        let violations = checker.check(source: source, file: "test.swift")
        #expect(violations.count == 1)
        #expect(violations[0].kind == .missingLabel)
    }

    @Test func imageWithTextWrappedEmptyLabelHasEmptyLabelViolation() {
        let source = #"Image("cat").accessibilityLabel(Text(""))"#
        let violations = checker.check(source: source, file: "test.swift")
        #expect(violations.count == 1)
        #expect(violations[0].kind == .emptyLabel)
    }

    @Test func multipleViolationsAreAllDetected() {
        let source = """
        Image("cat")
        AsyncImage(url: nil)
        """
        let violations = checker.check(source: source, file: "test.swift")
        #expect(violations.count == 2)
    }

    @Test func violationReportsCorrectLineAndColumn() {
        let source = """
        struct ContentView: View {
            var body: some View {
                Image("cat")
            }
        }
        """
        let violations = checker.check(source: source, file: "test.swift")
        #expect(violations.count == 1)
        #expect(violations[0].line == 3)
        #expect(violations[0].column == 9)
    }

    @Test func missingLabelViolationDescriptionMatchesExpectedFormat() {
        let source = #"Image("cat")"#
        let violations = checker.check(source: source, file: "/path/to/test.swift")
        #expect(violations.count == 1)
        #expect(violations[0].description == #"/path/to/test.swift:1:1: warning: `Image` does not have an accessibility label."#)
    }

    @Test func emptyLabelViolationDescriptionMatchesExpectedFormat() {
        let source = #"Image("cat").accessibilityLabel("")"#
        let violations = checker.check(source: source, file: "/path/to/test.swift")
        #expect(violations.count == 1)
        #expect(violations[0].description == #"/path/to/test.swift:1:1: warning: `Image` has an accessibility label but it is empty."#)
    }
}
