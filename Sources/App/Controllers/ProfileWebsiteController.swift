//
//  File.swift
//  
//
//  Created by Marlon Mueller Soppart on 1/23/22.
//

import Vapor

// Handles the rendering and actions of profile pages
struct ProfileWebsiteController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let basicAuthRoutes = routes.grouped(
            User.credentialsAuthenticator()
        )
        
        basicAuthRoutes.get("profile", use: profileHandler)
        basicAuthRoutes.get("profile", ":user_id", "energy", use: profileEnergyHandler)
    }
    
    func profileEnergyHandler(_ req: Request) async throws -> View {
        
        // must be logged in to logout
        let currUser = req.auth.get(User.self)
        
        let userOfProfile = try await User.find(req.parameters.get("user_id"), on: req.db)!
        
        var isCurrUserProfile: Bool = false
        if let currUser = currUser {
            isCurrUserProfile = (currUser.id == userOfProfile.id)
        }
        
        let baseProfileContext = BaseProfileContext(isCurrUserProfile: isCurrUserProfile, userOfProfile: userOfProfile)
        
        let baseContext = BaseContext(
            title: "Profile",
            isLoggedIn: (currUser != nil),
            isPage: IsPage(profile: isCurrUserProfile)
        )
        
        let context = ProfileContext(baseContext: baseContext, baseProfileContext: baseProfileContext)
        
        return try await req.view.render("profile", context)
    }
    
    func profileHandler(_ req: Request) async throws -> View {
        
        // must be logged in to logout
        let currUser = try req.auth.require(User.self)
        
        let baseProfileContext = BaseProfileContext(isCurrUserProfile: true, userOfProfile: currUser)
        
        let baseContext = BaseContext(
            title: "Profile",
            isLoggedIn: true,
            isPage: IsPage(profile: true)
        )
        
        let context = ProfileContext(baseContext: baseContext, baseProfileContext: baseProfileContext)
        
        return try await req.view.render("profile", context)
    }
}

// Context data needed for each profile page
struct BaseProfileContext: Encodable {
    let isCurrUserProfile: Bool
    let userOfProfile: User
}

// Profile
struct ProfileContext: Encodable {
    let baseContext: BaseContext
    let baseProfileContext: BaseProfileContext
}
