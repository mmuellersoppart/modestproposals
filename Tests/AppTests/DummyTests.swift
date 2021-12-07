//
//  File.swift
//  
//
//  Created by Marlon Mueller Soppart on 12/7/21.
//

@testable import App
import XCTVapor

final class DummyTests: XCTestCase {
    func testDummyCanBeRetrievedFromAPI() async throws {
        
        let expectedValue = "Sup Sup Sup"
        
        let app = Application(.testing)
        
        defer { app.shutdown() }
        
        try configure(app)
        
        try await app.autoRevert()
        try await app.autoMigrate()
        
        let dummy = Dummy(id: UUID(), value: expectedValue)
        try await dummy.save(on: app.db)
        try await Dummy(id: UUID(), value: "I am not saying hello").save(on: app.db)
        
        try app.test(.GET, "/api/dummies", afterResponse: { response in
            
            XCTAssertEqual(response.status, .ok)
            
            let dummies = try response.content.decode([Dummy].self)
            
            // be wary of the sort placed on the get all 
            XCTAssertEqual(dummies.count, 2)
            XCTAssertEqual(dummies[1].value, expectedValue)
            XCTAssertEqual(dummies[1].id, dummy.id)
        })
        
    }
}
