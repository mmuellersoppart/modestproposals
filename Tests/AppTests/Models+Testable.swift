//
//  File.swift
//  
//
//  Created by Marlon Mueller Soppart on 12/7/21.
//

@testable import App
import Fluent
import Foundation
import Vapor

extension User {
    static func create(
        email: String = "u1@mail.com",
        username: String = "u1",
        password: String = "password1",
        on database: Database
    ) async throws -> User {
        let user = User(id: UUID(), username: username, email: email, password: password)
        try await user.save(on: database)
        return user
    }
}
