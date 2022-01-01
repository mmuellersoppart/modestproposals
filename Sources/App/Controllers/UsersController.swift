//
//  File.swift
//  
//
//  Created by Marlon Mueller Soppart on 12/20/21.
//

import Vapor

struct UsersController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let basicAuthMiddleware = User.authenticator()
        let tokenAuthMiddleware = Token.authenticator()
        
        // open apis, no permissions needed
        let usersRoutes = routes.grouped("api", "users")
        
        usersRoutes.post(use: createHandler)
        
        // login routes
        let loginProtectedAuthGroup = usersRoutes.grouped(basicAuthMiddleware, tokenAuthMiddleware)

        loginProtectedAuthGroup.get(use: getAllHandler)
        loginProtectedAuthGroup.delete(":userID", use: deleteUserHandler)
//        loginProtectedAuthGroup.post(use: createHandler)
//
        // basic auth
        let basicProtectedAuthGroup = usersRoutes.grouped(basicAuthMiddleware)
        
        basicProtectedAuthGroup.post("login", use: loginHandler)
    }
    
    func loginHandler(_ req: Request) async throws -> Token {
        let user = try req.auth.require(User.self)
        let token = try Token.generate(for: user)
        try await token.save(on: req.db)
        return token
    }
    
    func getAllHandler(_ req: Request) async throws -> [User.Public] {
        let users = try await User.query(on: req.db).all()
        let public_users = users.convertToPublic()
        return public_users
    }
    
    func createHandler(_ req: Request) async throws -> UserPublicResponse {
        
        let created_user = try req.content.decode(User.self)
        
        created_user.password = try Bcrypt.hash(created_user.password)
        
        try await created_user.save(on: req.db)
        
        
        
        // TODO: set a max on users
        
        return UserPublicResponse(request: created_user.convertToPublic())
    }
    
    func deleteUserHandler(_ req: Request) async throws -> UserPublicResponse {
        let user = try await User.find(req.parameters.get("userID"), on: req.db)
        try await user?.delete(on: req.db)
        return UserPublicResponse(request: user?.convertToPublic() ?? User().convertToPublic())
    }
    
    struct UserPublicResponse: Content {
        let request: User.Public
    }
    
}
