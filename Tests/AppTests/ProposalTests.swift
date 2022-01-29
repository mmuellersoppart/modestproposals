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
    
    func testProposalsCanBeRetrievedFromAPI() async throws {
//        let u1 = try await User.create(email: "u1@m.com", username: "u1", password: "u1", on: app.db)
//        let u1Link = "https://gist.github.com/mmuellersoppart/afaba2e995622ff3f2242e2aac52bf92"
//        let u1ProposalMarkdown = try await linkToMarkdown(link: u1Link)
//
//        let u2 = try await User.create(email: "u2@m.com", username: "u2", password: "u2", on: app.db)
//        let u1Link = "https://gist.githubusercontent.com/mmuellersoppart/afaba2e995622ff3f2242e2aac52bf92/raw/bb9686d731b17ee32ad913319ab6eafb0eba5c84/gistfile1.txt"
//        let u1ProposalMarkdown = try await linkToMarkdown(link: u1Link)
//
////        let u3 = try await User.create(email: "u3@m.com", username: "u3", password: "u3", on: app.db)
//
//
//        let p1 = try await Proposal.create(title: "u1 proposal", description: "a proposal by u1", user: u1, link: "", markdown: "", on: app.db)
//
//        try app.test(.GET, proposalURI, afterResponse: { response in
//            XCTAssertEqual(response.status, .ok)
//            let users = try response.content.decode([User.Public].self)
//
//            XCTAssertEqual(users.count, 3)
//
//            XCTAssertEqual(users[0].username, "mmuellersoppart")
//
//            XCTAssertEqual(users[1].username, user.username)
//            XCTAssertEqual(users[1].id, user.id)
//            // TODO: test for password not being there.
//        })
    }
//
//    func testUserCanBeSavedWithAPI() async throws {
//        let user = try await User.create(email: "e1@mail.com", username: "u1", password: "p1", on: app.db)
//
//        try app.test(.POST, userURI, )
//    }
}

