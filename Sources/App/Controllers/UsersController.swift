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
        usersRoutes.delete(":userID", use: deleteUserHandler)
       
        usersRoutes.post(use: createHandler)  // basic authentication inside
        
        let basicAuthMiddleware = User.authenticator()
        let basicAuthGroup = usersRoutes.grouped(basicAuthMiddleware)
        
        basicAuthGroup.post("login", use: loginHandler)
    }
    
    func loginHandler(_ req: Request) async throws -> Token {
        req.logger.debug("here")
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
        
//        let user = try req.content.decode(User.self)
        let user = try req.auth.require(User.self)
        
        // one way hash of the password
        user.password = try Bcrypt.hash(user.password)
        
        try await user.save(on: req.db)
        
        // TODO: set a max on users
        
        return UserPublicResponse(request: user.convertToPublic())
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
