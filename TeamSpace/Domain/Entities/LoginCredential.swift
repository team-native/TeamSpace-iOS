import Foundation

struct LoginCredential: Equatable {
    let email: String
    let password: String
    let keepSignedIn: Bool
}
