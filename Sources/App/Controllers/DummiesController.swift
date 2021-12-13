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
        try await Dummy.query(on: req.db).sort(\.$createdAt, .descending).all()
    }
    
    func createHandler(_ req: Request) async throws -> DummyResponse {
        let dummy = try req.content.decode(Dummy.self)
        
        let allDummies = try await getAllHandler(req)
        
        if allDummies.count >= 10 {
            try await allDummies.last?.delete(on: req.db)
        }
        
        try await dummy.save(on: req.db)
        
        return DummyResponse(request: dummy)
    }
    
    struct DummyResponse: Content {
      let request: Dummy
    }

}
