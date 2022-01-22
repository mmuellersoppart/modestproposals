//
//  File.swift
//  
//
//  Created by Marlon Mueller Soppart on 1/19/22.
//

import Foundation
import Vapor

// Handle displaying register, login, and logout display and actions. 
struct AuthenticationWebsiteController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.get("register", use: registerHandler)
        routes.post("register", use: registerPostHandler)
        
        routes.get("login", use: loginHandler)
        
        let basicAuthRoutes = routes.grouped(
            User.credentialsAuthenticator()
        )
        
        basicAuthRoutes.post("login", use: loginPostHandler)
        basicAuthRoutes.post("logout", use: logoutHandler)
    }
    
    /// Renders registration page
    func registerHandler(_ req: Request) async throws -> View {
        
        let baseContext = BaseContext(title: "Register", isLoggedIn: false)
        let context = RegisterContext(baseContext: baseContext)
        
        return try await req.view.render("register", context)
    }
    
    /// Creates user from registration form data
    func registerPostHandler(_ req: Request) async throws -> Response {
        
        // convert data from form to RegisterDTO object
        let data = try req.content.decode(RegisterDTO.self)
        
        // convert plaintext password to an encrypted one and save that!
        let password = try Bcrypt.hash(data.password)
        
        let user = User(
            id: UUID(),
            username: data.username,
            email: data.email,
            password: password
        )
        try await user.save(on: req.db)
        
        // login user, they'll recieve a session in a cookie now
        req.auth.login(user)
        
        return req.redirect(to: "/")
    }
    
    /// renders login page
    func loginHandler(_ req: Request) async throws -> View {
        let baseContext = BaseContext(title: "Login", isLoggedIn: false)
        let context: LoginContext
        
        // if error exist, a notification will appear on screen telling
        // the user.
        if let error = req.query[Bool.self, at: "error"], error {
            context = LoginContext(baseContext: baseContext, loginError: true)
        } else {
            context = LoginContext(baseContext: baseContext)
        }
        
        return try await req.view.render("login", context)
    }
    
    /// takes information from login form and logs in users who are in auth cache (currently only in memory)
    func loginPostHandler(_ req: Request) async throws -> Response {
        do {
            // case where user is found in the system
            let user = try req.auth.require(User.self)
            req.auth.login(user)
            return req.redirect(to: "/")
        } catch {
            // user is not in the system, so we send an error in the context
            let baseContext = BaseContext(title: "Login", isLoggedIn: false)
            let context = LoginContext(baseContext: baseContext, loginError: true)
            return try await req.view.render("login", context).encodeResponse(for: req)
        }
    }
    
    /// Logs out any user who is currently logged in. 
    func logoutHandler(_ req: Request) -> Response {
        req.auth.logout(User.self)
        return req.redirect(to: "/")
    }
    
}

// Log in
struct LoginContext: Encodable {
    let baseContext: BaseContext
    let loginError: Bool
    
    init(baseContext: BaseContext, loginError: Bool = false) {
        self.baseContext = baseContext
        self.loginError = loginError
    }
}

struct LoginData: Content {
    let username: String
    let password: String
}

// Register
struct RegisterContext: Encodable {
    let baseContext: BaseContext
}

struct RegisterDTO: Content {
    let username: String
    let email: String
    let password: String
    let confirmPassword: String
}
