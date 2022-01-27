
import Vapor

// Proposals Api
struct ProposalController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let proposalRoutes = routes.grouped("api", "proposals")
        
        proposalRoutes.get(use: getProposalsHandler)
        proposalRoutes.post(use: createProposalHandler)
            
    }

    func getProposalsHandler(_ req: Request) async throws -> ProposalsResponse {
        let proposals = try await Proposal.query(on: req.db).all()
        let res = ProposalsResponse(request: proposals)
        return res
    }
    
    func createProposalHandler(_ req: Request) async throws -> Response {
        
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
   
        return try await proposal.encodeResponse(for: req)
    }
}

struct CreateProposalDTO: Content {
    let title: String
    let description: String
    let link: String
    let markdown: String
    let userID: UUID
}

struct ProposalsResponse: Content {
    let request: [Proposal]
}
        
