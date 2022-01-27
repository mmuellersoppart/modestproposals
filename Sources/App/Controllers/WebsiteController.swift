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
        
        basicAuthRoutes.get("propose", use: proposeHandler)
        basicAuthRoutes.post("propose", use: proposePostHandler)
        
        basicAuthRoutes.get("proposal", ":proposal_id", use: proposalHandler)
        
    }
    
    func proposalHandler(_ req: Request) async throws -> View {
      
        let user = req.auth.get(User.self)
        
        let proposal: Proposal = try await Proposal.find(req.parameters.get("proposal_id"), on: req.db)!
        let creator = try await User.find(proposal.$user.id, on: req.db)!
        
        // TODO: handle logged in and not logged in
        let baseContext = BaseContext(title: "Proposal Details", isLoggedIn: (user != nil), isPage: IsPage())
        let down = Down(markdownString: proposal.markdown)
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
        
        
        let link = data.link
        
        // convert link to url
        let url = URL(string: link)
        guard let url = url else {
            throw Abort(.notAcceptable, reason: "Link submitted is unacceptable. It cannot to a url.")
        }
        
        // make sure link is from github gist
        let hostInfo = url.host
        let hostComponents = hostInfo?.components(separatedBy: ".")
        
        // check from right website
        guard hostComponents == ["gist", "githubusercontent", "com"] else {
            throw Abort(.unprocessableEntity, reason: "Link submitted is from an invalid website. Only github gist links are accepted. See tutorial below.")
        }
        
        // check that we are getting a .md file
        let urlFile = url.lastPathComponent.components(separatedBy: ".")
        guard urlFile[1] == "md" else {
            throw Abort(.unprocessableEntity, reason: "Link submitted isn't a raw markdown file. See tutorial below.")
        }
        
        let (url_data, response) = try await URLSession.shared.data(from: url)
    
        // see if response is good
        guard let httpRequest = response as? HTTPURLResponse,
              httpRequest.statusCode == 200 else {
                  // throw error
                  // TODO: handle error
                  throw Abort(.badRequest, reason: "Url session failed to retreive data from link.")
              }
        
        // check if file data is good
        guard let markdown = String(data: url_data, encoding: .utf8) else {
            // throw error
            // TODO: do better
            throw Abort(.processing, reason: "url data could not be decoded to a string.")
        }
        
        let proposal = Proposal(id: UUID(), userID: user.id!, title: data.title, description: data.description, link: data.link, markdown: markdown)
        
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
}

// Context data needed on every page
struct BaseContext: Encodable {
    let title: String
    let isLoggedIn: Bool
    let isPage: IsPage
}


// Final information needed to render propose page
struct ProposeContext: Encodable {
    let baseContext: BaseContext
}

// Expected data from form
struct ProposeDTO: Content {
    let title: String
    let description: String
    let link: String
}

// Information necessary to render proposals pages
struct ProposalContext: Encodable {
    let baseContext: BaseContext
    let proposal: Proposal
    let creator: User
    let html: String
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
