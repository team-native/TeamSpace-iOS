import Foundation

/// `data` 에 의미 있는 값이 없는 응답용 (예: `{ "success": true }`)
struct EmptyResponseDTO: Decodable {}
