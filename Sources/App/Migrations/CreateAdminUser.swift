//
//  File.swift
//  
//
//  Created by Marlon Mueller Soppart on 12/25/21.
//

import Vapor
import Fluent

struct CreateAdminUser: AsyncMigration {
    func prepare(on database: Database) async throws {
        
        // TODO: Production Concern. Create a random password and print out instead of being hardcoded. 
        let passwordHash: String = try Bcrypt.hash("QV2Xm%LCp1")
        
        let user = User(
            id: UUID(),
            username: "mmuellersoppart",
            email: "mmuellersoppart@gmail.com",
            password: passwordHash
        )
        
        try await user.save(on: database)
    }
    
    func revert(on database: Database) async throws {
        try await User.query(on: database).filter(\.$username == "mmuellersoppart").delete()
    }
}
