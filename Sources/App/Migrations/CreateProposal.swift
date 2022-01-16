//
//  File.swift
//
//
//  Created by Marlon Mueller Soppart on 12/20/21.
//

import Fluent

struct CreateProposal: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("proposals")
            .id()
            .field("user_id", .uuid, .required, .references("users", "id"))
            .field("title", .string, .required)
            .field("description", .string, .required)
            .field("link", .string)
            .field("markdown", .string, .required)
            .field("energy", .int)
            .field("created_at", .date, .required)
            .unique(on: "title")
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema("proposals").delete()
    }
    
    
}
