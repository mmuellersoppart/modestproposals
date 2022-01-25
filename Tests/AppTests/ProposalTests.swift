//
//  File.swift
//  
//
//  Created by Marlon Mueller Soppart on 1/24/22.
//

@testable import App
import XCTVapor

// TODO: get and create proposals

final class ProposalTests: XCTestCase {
    let proposalURI = "/api/proposal"
    var app: Application!
    
    override func setUpWithError() throws {
        app = try Application.testable()
    }
    
    override func tearDownWithError() throws {
        app.shutdown()
    }
    
    func testUsersCanBeRetrievedFromAPI() async throws {
        let user = try await User.create(email: "email1@mail.com", username: "u1", password: "password1", on: app.db)
        _ = try await User.create(email: "email2@mail.com", username: "u2", password: "password2", on: app.db)
        
        try app.test(.GET, proposalURI, afterResponse: { response in
            XCTAssertEqual(response.status, .ok)
            let users = try response.content.decode([User.Public].self)
            
            XCTAssertEqual(users.count, 3)
            
            XCTAssertEqual(users[0].username, "mmuellersoppart")
            
            XCTAssertEqual(users[1].username, user.username)
            XCTAssertEqual(users[1].id, user.id)
            // TODO: test for password not being there.
        })
    }
//
//    func testUserCanBeSavedWithAPI() async throws {
//        let user = try await User.create(email: "e1@mail.com", username: "u1", password: "p1", on: app.db)
//
//        try app.test(.POST, userURI, )
//    }
}

