//
//  File.swift
//  
//
//  Created by Marlon Mueller Soppart on 12/7/21.
//

@testable import App
import Fluent
import Foundation

extension Dummy {
  static func create(
    value: String = "test test",
    on database: Database
  ) async throws -> Dummy {
    let dummy = Dummy(id: UUID(), value: value)
    try await dummy.save(on: database)
    return dummy
  }
}
