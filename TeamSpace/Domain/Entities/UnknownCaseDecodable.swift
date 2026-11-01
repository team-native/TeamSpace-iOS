import Foundation

/// 서버에서 정의되지 않은 값이 내려와도 디코딩이 실패하지 않도록 `.unknown` 으로 받아주는 enum 규칙.
protocol UnknownCaseDecodable: RawRepresentable, Decodable where RawValue == String {
    static var unknownCase: Self { get }
}

extension UnknownCaseDecodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = Self(rawValue: rawValue) ?? Self.unknownCase
    }
}
