
import Vapor

struct ProposalController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let proposalRoutes = routes.grouped("api", "proposals")
        
        proposalRoutes.post(use: createProposalHandler)
            
    }

    func createProposalHandler(_ req: Request) async throws -> Response {
        let data = try req.content.decode(CreateProposalDTO.self)
        
        let created_proposal = Proposal(
            id: UUID(),
            userID: data.userID,
            title: data.title,
            description: data.description,
            link: data.link,
            markdown: data.markdown
        )
        
        try await created_proposal.save(on: req.db)
        
        return Response(status: .ok)
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
        
