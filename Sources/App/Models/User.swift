//
//  File.swift
//  
//
//  Created by Marlon Mueller Soppart on 12/20/21.
//

import Foundation
import Vapor
import Fluent

final class User: Model, Content {
    static let schema: String = "users"
    
    @ID
    var id: UUID?
    
    @Field(key: "username")
    var username: String
    
    @Field(key: "email")
    var email: String
    
    @Field(key: "password")
    var password: String
    
    init() {}
    
    init(
        id: UUID?,
        username: String,
        email: String,
        password: String
    ) {
        self.id = id
        self.username = username
        self.email = email
        self.password = password
    }
    
    final class Public: Content {
        var id: UUID?
        var username: String
        var email: String
        
        init(id: UUID?, username: String, email: String) {
            self.id = id
            self.username = username
            self.email = email
        }
    }
}

extension User {
    func convertToPublic() -> User.Public {
        return User.Public(id: id, username: username, email: email)
    }
}

extension Collection where Element: User {
    func convertToPublic() -> [User.Public] {
        return self.map { $0.convertToPublic() }
    }
}

extension User: ModelAuthenticatable {
    static let usernameKey = \User.$username
    static let passwordHashKey = \User.$password
    
    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.password)
    }
}
