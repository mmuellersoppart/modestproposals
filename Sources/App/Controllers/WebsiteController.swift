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
        
        basicAuthRoutes.get("propose", use: proposeHandler)
        basicAuthRoutes.post("propose", use: proposePostHandler)
        
        basicAuthRoutes.get("proposal", ":proposal_id", use: proposalHandler)
    }
    
    func proposalHandler(_ req: Request) async throws -> View {
      
        let proposal: Proposal = try await Proposal.find(req.parameters.get("proposal_id"), on: req.db)!
        let creator = try await User.find(proposal.$user.id, on: req.db)!
        
        // TODO: handle logged in and not logged in
        let baseContext = BaseContext(title: "Proposal Details", isLoggedIn: false)
        let context = ProposalContext(baseContext: baseContext, proposal: proposal, user: creator)
        
        return try await req.view.render("proposal", context)
        
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
        
        return try await req.view.render("user_profile", context)
    }
    
    func proposeHandler(_ req: Request) async throws -> View {
        
        let user = try req.auth.require(User.self)
        
        let baseContext = BaseContext(title: "Propose", isLoggedIn: true)
        let context = ProposeContext(baseContext: baseContext)
        
        return try await req.view.render("propose", context)
    }
    
    func proposePostHandler(_ req: Request) async throws -> Response {
        
        let user = try req.auth.require(User.self)
        let data = try req.content.decode(ProposeData.self)
        
        // get data from link
        let link = data.link
        
        // TODO: check if link is allowed
        
        let url = URL(string: link)!
        
        let (url_data, response) = try await URLSession.shared.data(from: url)
    
        // see if response is good
        guard let httpRequest = response as? HTTPURLResponse,
              httpRequest.statusCode == 200 else {
                  // throw error
                  // TODO: handle error
                  throw Abort(.badRequest)
              }
        
        // check if file data is good
        guard let markdown = String(data: url_data, encoding: .utf8) else {
            // throw error
            // TODO: do better
            throw Abort(.processing)
        }
        
        let proposal = Proposal(id: UUID(), userID: user.id!, title: data.title, description: data.description, link: data.link, markdown: markdown)
        
        try await proposal.save(on: req.db)
   
        return req.redirect(to: "/")
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

// Propose
struct ProposeContext: Encodable {
    let baseContext: BaseContext
}

// Expected data from form
struct ProposeData: Content {
    let title: String
    let description: String
    let link: String
}

//
struct ProposalContext: Encodable {
    let baseContext: BaseContext
    let proposal: Proposal
    let user: User
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
