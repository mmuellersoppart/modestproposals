
import Vapor
import Foundation


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
        
        let proposal = Proposal(id: UUID(), userID: user.id!, title: data.title, description: data.description, proposal: data.proposal)
        
        try await proposal.save(on: req.db)
   
        return try await proposal.encodeResponse(for: req)
    }
}

struct CreateProposalDTO: Content {
    let title: String
    let description: String
    let markdown: String
    let userID: UUID
}

struct ProposalsResponse: Content {
    let request: [Proposal]
}
