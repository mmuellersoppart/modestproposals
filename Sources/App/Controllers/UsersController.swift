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
        // Register
        usersRoutes.post("register", use: createHandler)
        usersRoutes.delete("all", use: deleteAllUsersHandler)
        
        // basic authentication
        let basicProtectedAuthGroup = usersRoutes.grouped(basicAuthMiddleware, User.sessionAuthenticator())
        // Login
        basicProtectedAuthGroup.post("login", use: loginHandler)
        
        
        // need to be logged in, or have a session going
        let loginProtectedAuthGroup = usersRoutes.grouped(
            basicAuthMiddleware,
            tokenAuthMiddleware,
            User.credentialsAuthenticator()
        )

        //loginProtectedAuthGroup.get(use: getAllHandler)
        usersRoutes.get(use: getAllHandler)
        loginProtectedAuthGroup.delete(":userID", use: deleteUserHandler)
        
        // TODO: disposable
        // dummy tests - session authentication
        let protectedCredentialAuthGroup = usersRoutes.grouped(User.sessionAuthenticator(), User.redirectMiddleware(path: "/hello"))
        
        protectedCredentialAuthGroup.get("silly", use: getSillyStringHandler)
        
    }
    
    func getSillyStringHandler(_ req: Request) -> String {
        return "I'm silly"
    }
    
    func loginHandler(_ req: Request) async throws -> Response {
        let user = try req.auth.require(User.self)
        return Response(status: .ok)
    }
    
    func getAllHandler(_ req: Request) async throws -> [User.Public] {
//        let _ = try req.auth.require(User.self)
        let users = try await User.query(on: req.db).all()
        let public_users = users.convertToPublic()
        return public_users
    }
    
    // Register users
    func createHandler(_ req: Request) async throws -> Response {
        
        let created_user = try req.content.decode(User.self)
        
        created_user.password = try Bcrypt.hash(created_user.password)
        
        try await created_user.save(on: req.db)
        
        req.auth.login(created_user)
        
        // TODO: set a max on users
        
        return Response(status: .ok)
    }
    
    func deleteUserHandler(_ req: Request) async throws -> UserPublicResponse {
        let user = try await User.find(req.parameters.get("userID"), on: req.db)
        try await user?.delete(on: req.db)
        return UserPublicResponse(request: user?.convertToPublic() ?? User().convertToPublic())
    }
    
    func deleteAllUsersHandler(_ req: Request) async throws -> Response {
        let _ = try await User.query(on: req.db).all().delete(on: req.db)
        return Response(status: .ok)
    }
    
    struct UserPublicResponse: Content {
        let request: User.Public
    }
    
}
