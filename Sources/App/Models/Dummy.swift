//
//  File.swift
//  
//
//  Created by Marlon Mueller Soppart on 12/6/21.
//

import Vapor
import Fluent
import Foundation

final class Dummy: Content, Model {
    static let schema: String = "dummies"
    
    @ID
    var id: UUID?
    
    @Field(key: "value")
    var value: String
    
    @Timestamp(key: "created_at", on: .create)
        var createdAt: Date?
    
    init() {}
    
    init(id: UUID?, value: String) {
        self.id = id
        self.value = value
        self.createdAt = Date.now
    }
}

