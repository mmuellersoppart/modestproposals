//
//  File.swift
//  
//
//  Created by Marlon Mueller Soppart on 1/19/22.
//

import Foundation
import Vapor

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
    
    func registerHandler(_ req: Request) async throws -> View {
    
      let baseContext = BaseContext(title: "Register", isLoggedIn: false)
        
      let context = RegisterContext(baseContext: baseContext)
      return try await req.view.render("register", context)
    }
    
    func registerPostHandler(_ req: Request) async throws -> Response {
      let data = try req.content.decode(RegisterData.self)
      let password = try Bcrypt.hash(data.password)
      let user = User(
        id: UUID(),
        username: data.username,
        email: data.email,
        password: password
      )
      try await user.save(on: req.db)
 
      req.auth.login(user)
      return req.redirect(to: "/")
    }
    
    func loginHandler(_ req: Request) async throws -> View {
        let baseContext = BaseContext(title: "Login", isLoggedIn: false)
        let context: LoginContext
        
        if let error = req.query[Bool.self, at: "error"], error {
            context = LoginContext(baseContext: baseContext, loginError: true)
        } else {
            context = LoginContext(baseContext: baseContext)
        }
        
        return try await req.view.render("login", context)
    }
    
    func loginPostHandler(_ req: Request) async throws -> Response {
        do {
            let user = try req.auth.require(User.self)
            req.auth.login(user)
            return req.redirect(to: "/")
        } catch {
            let baseContext = BaseContext(title: "Login", isLoggedIn: false)
            let context = LoginContext(baseContext: baseContext, loginError: true)
            return try await req.view.render("login", context).encodeResponse(for: req)
        }
    }
    
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

struct RegisterData: Content {
  let username: String
  let email: String
  let password: String
  let confirmPassword: String
}
