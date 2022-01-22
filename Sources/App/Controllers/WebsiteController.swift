//
//  WebsiteController.swift
//  
//
//  Created by Marlon Mueller Soppart on 1/15/22.
//

import Down
import Vapor
import Leaf

struct WebsiteController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        
        routes.get(use: indexHandler)
        
        let basicAuthRoutes = routes.grouped(
            User.credentialsAuthenticator()
        )
        
        basicAuthRoutes.get("profile", use: profileHandler)
    
        basicAuthRoutes.get("propose", use: proposeHandler)
        basicAuthRoutes.post("propose", use: proposePostHandler)
        
        basicAuthRoutes.get("proposal", ":proposal_id", use: proposalHandler)
        basicAuthRoutes.get("profile", ":user_id", "energy", use: profileEnergyHandler)
    }
    
    func proposalHandler(_ req: Request) async throws -> View {
      
        let proposal: Proposal = try await Proposal.find(req.parameters.get("proposal_id"), on: req.db)!
        let creator = try await User.find(proposal.$user.id, on: req.db)!
        
        // TODO: handle logged in and not logged in
        let baseContext = BaseContext(title: "Proposal Details", isLoggedIn: false)
        let down = Down(markdownString: proposal.markdown)
        let context = ProposalContext(baseContext: baseContext, proposal: proposal, creator: creator, html: try down.toHTML())
        
        return try await req.view.render("proposal", context)
        
    }
  
    func profileEnergyHandler(_ req: Request) async throws -> View {
        
        // must be logged in to logout
        let currUser = req.auth.get(User.self)
        
        let userOfProfile = try await User.find(req.parameters.get("user_id"), on: req.db)!
        
        var isCurrUserProfile: Bool = false
        if let currUser = currUser {
            isCurrUserProfile = (currUser.id == userOfProfile.id)
        }
        
        let baseProfileContext = BaseProfileContext(isCurrUserProfile: isCurrUserProfile, userOfProfile: userOfProfile)
        
        let baseContext = BaseContext(title: "Profile", isLoggedIn: true)
        
        let context = ProfileContext(baseContext: baseContext, baseProfileContext: baseProfileContext)
        
        return try await req.view.render("profile", context)
    }
    
    func profileHandler(_ req: Request) async throws -> View {
        
        // must be logged in to logout
        let currUser = try req.auth.require(User.self)
        
        let userOfProfile = try await User.find(req.parameters.get("user_id"), on: req.db)!
        
        let isCurrUserProfile = (currUser.id == userOfProfile.id)
        
        let baseProfileContext = BaseProfileContext(isCurrUserProfile: isCurrUserProfile, userOfProfile: userOfProfile)
        
        let baseContext = BaseContext(title: "Profile", isLoggedIn: true)
        
        let context = ProfileContext(baseContext: baseContext, baseProfileContext: baseProfileContext)
        
        return try await req.view.render("profile", context)
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
                proposalId: combo.0.id!,
                creatorUsername: combo.1.username,
                creatorId: combo.1.id!
            )
            proposalAndCreators.append(proposalAndCreator)
        }
        
        let baseContext = BaseContext(title: "Homepage", isLoggedIn: isLoggedIn)
        
        let context = IndexContext(baseContext: baseContext, homepageProposals: proposalAndCreators
        )

        return try await req.view.render("index", context)
    }
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
    let creator: User
    let html: String
}

// Index
struct IndexContext: Encodable {
    let baseContext: BaseContext
    
    let homepageProposals: [ProposalAndCreator]
}

// Index struct
struct ProposalAndCreator: Encodable {
    let proposalTitle: String
    let proposalId: UUID
    let creatorUsername: String
    let creatorId: UUID
}

// Profile
struct ProfileContext: Encodable {
    let baseContext: BaseContext
    let baseProfileContext: BaseProfileContext
}

// Context data needed on every page
struct BaseContext: Encodable {
    let title: String
    let isLoggedIn: Bool
}

// Context data needed for each profile page
struct BaseProfileContext: Encodable {
    let isCurrUserProfile: Bool
    let userOfProfile: User
}
