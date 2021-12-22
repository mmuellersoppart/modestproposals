//
//  File.swift
//  
//
//  Created by Marlon Mueller Soppart on 12/20/21.
//

import Vapor

struct UsersController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let usersRoutes = routes.grouped("api", "users")
        
        usersRoutes.get(use: getAllHandler)
        usersRoutes.post(use: createHandler)
    }
    
    func getAllHandler(_ req: Request) async throws -> [User.Public] {
        let users = try await User.query(on: req.db).all()
        let public_users = users.convertToPublic()
        return public_users
    }
    
    func createHandler(_ req: Request) async throws -> UserPublicResponse {
        let user = try req.content.decode(User.self)
        
        // one way hash of the password
        user.password = try Bcrypt.hash(user.password)
        
        try await user.save(on: req.db)
        
        // TODO: set a max on users
        
        return UserPublicResponse(request: user.convertToPublic())
    }
    
    struct UserPublicResponse: Content {
        let request: User.Public
    }
    
}
