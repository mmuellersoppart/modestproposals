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

        routes.get("login", use: loginHandler)
        
        let basicAuthRoutes = routes.grouped(
            User.credentialsAuthenticator()
        )
        
        basicAuthRoutes.post("login", use: loginPostHandler)
        basicAuthRoutes.get("profile", use: profileHandler)
        basicAuthRoutes.post("logout", use: logoutHandler)
    }
    
    func registerHandler(_ req: Request) async throws -> View {
    
      let baseContext = BaseContext(title: "Register", isLoggedIn: false)
        
      let context = RegisterContext(baseContext: baseContext)
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
        
    func profileHandler(_ req: Request) async throws -> View {
        // must be logged in to logout
        let user = try req.auth.require(User.self)
        
        let baseContext = BaseContext(title: "Profile", isLoggedIn: true)
        
        let context = ProfileContext(baseContext: baseContext, user: user)
        
        return try await req.view.render("profile", context)
    }
    
    func indexHandler(_ req: Request) async throws -> View {
        
        let isLoggedIn = req.auth.has(User.self)
        
        let proposals = try await Proposal.query(on: req.db).all()
        
        var creators = [User]()
        for proposal in proposals {
            let user = try await proposal.$user.get(on: req.db)
            creators.append(user)
        }
        
        let zipped = zip(proposals, creators)
        
        var proposalAndCreators = [ProposalAndCreator]()
        for combo in zipped {
            let proposalAndCreator = ProposalAndCreator(
                proposalTitle: combo.0.title,
                creatorUsername: combo.1.username
            )
            proposalAndCreators.append(proposalAndCreator)
        }
        
        let baseContext = BaseContext(title: "Homepage", isLoggedIn: isLoggedIn)
        
        let context = IndexContext(baseContext: baseContext, homepageProposals: proposalAndCreators
        )

        return try await req.view.render("index", context)
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
      // 2
      req.auth.logout(User.self)
      // 3
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

// Index
struct IndexContext: Encodable {
    let baseContext: BaseContext
    
    let homepageProposals: [ProposalAndCreator]
}

// Index struct
struct ProposalAndCreator: Encodable {
    let proposalTitle: String
    let creatorUsername: String
}

// Profile
struct ProfileContext: Encodable {
    let baseContext: BaseContext
    let user: User
}


// Context data needed on every page
struct BaseContext: Encodable {
    let title: String
    let isLoggedIn: Bool
}
