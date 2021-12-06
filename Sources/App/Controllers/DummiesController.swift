//
//  File.swift
//  
//
//  Created by Marlon Mueller Soppart on 12/6/21.
//

import Foundation
import Vapor

struct DummiesController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let dummiesRoutes = routes.grouped("api", "dummies")
        
        dummiesRoutes.get(use: getAllHandler)
        dummiesRoutes.post(use: createHandler)
    }
    
    func getAllHandler(_ req: Request) async throws -> [Dummy] {
        try await Dummy.query(on: req.db).all()
    }
    
    func createHandler(_ req: Request) async throws -> Response {
        let dummy = try req.content.decode(Dummy.self)
        
        try await dummy.save(on: req.db)
        
        return Response(status: HTTPResponseStatus.ok)
    }
    
}
