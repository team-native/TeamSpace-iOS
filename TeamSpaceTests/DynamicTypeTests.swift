import XCTest
import SwiftUI
@testable import TeamSpace

/// COMMON-08 · 14-5 큰 글자
final class DynamicTypeTests: XCTestCase {
    func testDefaultSizeKeepsFigmaValues() {
        XCTAssertEqual(TSFontStyle.footnote.scaledSize(for: .large), 13, accuracy: 0.01)
        XCTAssertEqual(TSFontStyle.title3.scaledSize(for: .large), 22, accuracy: 0.01)
    }

    func testTextGrowsWithSystemSize() {
        let footnote = TSFontStyle.footnote
        XCTAssertGreaterThan(footnote.scaledSize(for: .xxxLarge), 13)
        XCTAssertGreaterThan(footnote.scaledSize(for: .accessibility2), footnote.scaledSize(for: .xxxLarge))
        XCTAssertLessThan(TSFontStyle.caption.scaledSize(for: .xSmall), 12)
    }

    func testTabLabelStaysFixed() {
        XCTAssertEqual(TSFontStyle.tabLabel.scaledSize(for: .accessibility2), 10.5, accuracy: 0.01)
    }
}
