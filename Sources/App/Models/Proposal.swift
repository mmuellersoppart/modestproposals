//
//  File.swift
//  
//
//  Created by Marlon Mueller Soppart on 1/15/22.
//

import Foundation
import Vapor
import Fluent

final class Proposal: Model, Content {
    static let schema: String = "proposals"
    
    @ID
    var id: UUID?
    
    @Parent(key: "user_id")
    var user: User
    
    @Field(key: "title")
    var title: String
    
    @Field(key: "description")
    var description: String
    
    @Field(key: "link")
    var link: String
    
    @Field(key: "markdown")
    var markdown: String
    
    @Field(key: "energy")
    var energy: Int
    
    @Timestamp(key: "created_at", on: .create)
    var date_created: Date?
    
    init() {}
    
    init(
        id: UUID?,
        userID: User.IDValue,
        title: String,
        description: String,
        link: String,
        markdown: String,
        energy: Int = 0,
        date_created: Date = Date()
    ) {
        self.id = id
        self.$user.id = userID
        self.title = title
        self.description = description
        self.markdown = markdown
        self.link = link
        self.energy = energy
    }

}
