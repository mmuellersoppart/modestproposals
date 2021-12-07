//
//  File.swift
//  
//
//  Created by Marlon Mueller Soppart on 12/7/21.
//

import Foundation
import XCTVapor
import App

extension Application {
    static func testable() throws -> Application {
        
        let app = Application(.testing)
        try configure(app)
        
        try app.autoRevert().wait()
        try app.autoMigrate().wait()
        
        return app
    }
}
