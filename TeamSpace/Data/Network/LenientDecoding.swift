import Foundation

extension KeyedDecodingContainer {
    /// 서버가 같은 ID 를 숫자(`/users/me`)로도, 문자열(`/auth/login` 의 `user.id`)로도 보내서 둘 다 받아요.
    func decodeIntOrString(forKey key: Key) throws -> Int {
        if let number = try? decode(Int.self, forKey: key) { return number }
        let text = try decode(String.self, forKey: key)
        guard let number = Int(text) else {
            throw DecodingError.dataCorruptedError(forKey: key, in: self, debugDescription: "숫자 ID 가 아니에요: \(text)")
        }
        return number
    }

    /// 조직도 ID("member-02")처럼 문자열 ID 도 있어서, 숫자로 와도 문자열로 받아요.
    func decodeStringOrInt(forKey key: Key) throws -> String {
        if let number = try? decode(Int.self, forKey: key) { return String(number) }
        return try decode(String.self, forKey: key)
    }
}
