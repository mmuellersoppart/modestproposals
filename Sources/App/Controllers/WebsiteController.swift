//
//  WebsiteController.swift
//  
//
//  Created by Marlon Mueller Soppart on 1/15/22.
//

import Vapor
import Leaf

struct WebsiteController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        
        routes.get(use: indexHandler)
        
        routes.get("register", use: registerHandler)
        routes.post("register", use: registerPostHandler)

//        routes.get("login", use: loginHandler)
        
        let basicAuthRoutes = routes.grouped(
            User.credentialsAuthenticator()
        )
        
//        basicAuthRoutes.post("login", use: loginPostHandler)
    }
    
    func registerHandler(_ req: Request) async throws -> View {
      let context = RegisterContext()
      return try await req.view.render("register", context)
    }
    
    func registerPostHandler(_ req: Request) async throws -> Response {
      // 2
      let data = try req.content.decode(RegisterData.self)
      // 3
      let password = try Bcrypt.hash(data.password)
      // 4
      let user = User(
        id: UUID(),
        username: data.username,
        email: data.email,
        password: password
      )
      // 5
      try await user.save(on: req.db)
 
      req.auth.login(user)
        // 7
      return req.redirect(to: "/")
    }
    
    func indexHandler(_ req: Request) async throws -> View {
        
        let isLoggedIn = req.auth.has(User.self)
        
        let proposals = try await Proposal.query(on: req.db).all()
        
        let context = IndexContext(title: "Homepage", isLoggedIn: isLoggedIn, homepageProposals: proposals)
//        let context = IndexContext(title: "Homepage", isLoggedIn: isLoggedIn)
        return try await req.view.render("index", context)
    }
    
}

// Log in
struct LoginContext: Encodable {
    let title = "Log In"
    let loginError: Bool
    
    init(loginError: Bool = false) {
        self.loginError = loginError
    }
}

struct LoginData: Content {
    let username: String
    let password: String
}

// Register

struct RegisterContext: Encodable {
  let title = "Register"
}

struct RegisterData: Content {
  let username: String
  let email: String
  let password: String
  let confirmPassword: String
}

// Index

struct IndexContext: Encodable {
    let title: String
    let isLoggedIn: Bool
    
    let homepageProposals: [Proposal]
}
