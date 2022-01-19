import Fluent
import Vapor

func routes(_ app: Application) throws {

    // api routes
    try app.register(collection: UsersController())
    try app.register(collection: ProposalController())
    
    // website routes
    try app.register(collection: WebsiteController())
    try app.register(collection: AuthenticationWebsiteController())
    
    // Sanity Check Routes

    app.get("hello") { req -> String in
        return "Hello, world!"
    }
    
    app.post("ok") { req -> Response in
        return Response(status: .ok)
    }
    
    app.get("ok") { req -> String in
        return "okay!"
    }

    app.post("very_much_not_ok") { req -> Response in
        return Response(status: .badRequest)
    }
}
