//
//  File.swift
//  
//
//  Created by Marlon Mueller Soppart on 12/7/21.
//

@testable import App
import XCTVapor

final class DummyTests: XCTestCase {
    let dummyValue = "test test"
    let dummyURI = "/api/dummies"
    var app: Application!
    
    override func setUpWithError() throws {
        app = try Application.testable()
    }
    
    override func tearDownWithError() throws {
        app.shutdown()
    }
    
    func testUsersCanBeRetrievedFromAPI() throws {
        let dummy = try Dummy.create(value: "t1", on: app.db)
        _ = try Dummy.create(value: "t2", on: app.db)
        
        try app.test(.GET, dummyURI, afterResponse: { response in
            XCTAssertEqual(response.status, .ok)
            let users = try response.content.decode([Dummy].self)
            
            XCTAssertEqual(users.count, 2)
            XCTAssertEqual(users[1].value, dummy.value)
            XCTAssertEqual(users[1].id, dummy.id)
        })
    }
    
}
