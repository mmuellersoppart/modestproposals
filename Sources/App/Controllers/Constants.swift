//
//  File.swift
//  
//
//  Created by Marlon Mueller Soppart on 1/23/22.
//

import Foundation

// marker of the navigatable pages
enum MainPages: Int {
    case home = 0
    case propose = 1
    case profile = 2
    case about = 3
    case register = 4
    case login = 5
}

struct IsPage : Encodable {
    let home: Bool
    let propose: Bool
    let profile: Bool
    let about: Bool
    let register: Bool
    let login: Bool
    
    init(
        home: Bool = false,
        propose: Bool = false,
        profile: Bool = false,
        about: Bool = false,
        register: Bool = false,
        login: Bool = false
    ){
        self.home = home
        self.propose = propose
        self.profile = profile
        self.about = about
        self.register = register
        self.login = login
    }
}
