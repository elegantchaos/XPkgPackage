import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    [
        testCase(XPkgPackageTests.allTests),
    ]
}
#endif
