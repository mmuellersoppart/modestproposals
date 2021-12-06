//
//  File.swift
//  
//
//  Created by Marlon Mueller Soppart on 12/6/21.
//

import Foundation
import Fluent

struct CreateDummy: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("dummies")
                .id()
                .field("value", .string, .required)
                .field("created_at", .datetime, .required)
                .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema("dummies").delete()
    }
}
