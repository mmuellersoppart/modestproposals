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

extension Dummy {
    static func create(
        value: String = "test test",
        on database: Database
    ) throws -> Dummy {
        let dummy = Dummy(id: UUID(), value: value)
        try dummy.save(on: database).wait()
        return dummy
    }
}

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
