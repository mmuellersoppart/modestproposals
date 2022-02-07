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
        routes.get("about", use: aboutHandler)
        
        let basicAuthRoutes = routes.grouped(
            User.credentialsAuthenticator()
        )
        
        basicAuthRoutes.get("propose", use: proposeHandler)
        basicAuthRoutes.post("propose", use: proposePostHandler)
        
        basicAuthRoutes.get("proposal", ":proposal_id", use: proposalHandler)
        
    }
    
    func proposalHandler(_ req: Request) async throws -> View {
      
        let user = req.auth.get(User.self)
        let isUserLoggedIn = (user != nil)
        let baseContext = BaseContext(title: "Proposal Details", isLoggedIn: isUserLoggedIn, isPage: IsPage())
        
        guard let proposal: Proposal = try await Proposal.find(req.parameters.get("proposal_id"), on: req.db) else {
            let context = ErrorContext(baseContext: baseContext)
            return try await req.view.render("error", context)
        }
        
        guard let creator = try await User.find(proposal.$user.id, on: req.db) else {
            let context = ErrorContext(baseContext: baseContext)
            return try await req.view.render("error", context)
        }
        
        let markdown = proposal.proposal
        let down = Down(markdownString: markdown)
        
        // TODO: handle logged in and not logged in
        let context = ProposalContext(baseContext: baseContext, proposal: proposal, creator: creator, html: try down.toHTML())
        
        return try await req.view.render("proposal", context)
        
    }
    
    func proposeHandler(_ req: Request) async throws -> View {
        
        let _ = try req.auth.require(User.self)
        
        let baseContext = BaseContext(title: "Propose", isLoggedIn: true, isPage: IsPage(propose: true))
        let context = ProposeContext(baseContext: baseContext)
        
        return try await req.view.render("propose", context)
    }
    
    func proposePostHandler(_ req: Request) async throws -> Response {
        
        let user = try req.auth.require(User.self)
        let data = try req.content.decode(ProposeDTO.self)
        
        let proposal = Proposal(id: UUID(), userID: user.id!, title: data.title, description: data.description, proposal: data.proposal)
        
        try await proposal.save(on: req.db)
   
        return req.redirect(to: "/")
    }
    
    /// Homepage handler
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
        
        let baseContext = BaseContext(title: "Homepage", isLoggedIn: isLoggedIn, isPage: IsPage(home: true))
        
        let context = IndexContext(baseContext: baseContext, homepageProposals: proposalAndCreators
        )

        return try await req.view.render("index", context)
    }
    
    /// Render about page
    func aboutHandler(_ req: Request) async throws -> View {
        
        let isLoggedIn = req.auth.has(User.self)
        
        let baseContext = BaseContext(title: "About", isLoggedIn: isLoggedIn, isPage: IsPage(about: true))
        
        let context = AboutContext(baseContext: baseContext)
        
        return try await req.view.render("about", context)
    }
}

// Context data needed on every page
struct BaseContext: Encodable {
    let title: String
    let isLoggedIn: Bool
    let isPage: IsPage
}

struct ErrorContext: Encodable {
    let baseContext: BaseContext
}

// Final information needed to render propose page
struct ProposeContext: Encodable {
    let baseContext: BaseContext
}

// Expected data from form
struct ProposeDTO: Content {
    let title: String
    let description: String
    let proposal: String
}

// Information necessary to render proposals pages
struct ProposalContext: Encodable {
    let baseContext: BaseContext
    let proposal: Proposal
    let creator: User
    let html: String // markdown or plain text
}

// Information necessary for the homepage
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

// Information necessary to render the about page
struct AboutContext: Encodable {
    let baseContext: BaseContext
}
