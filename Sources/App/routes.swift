import Fluent
import Vapor

func routes(_ app: Application) throws {
    app.get { req in
        return req.view.render("index", ["title": "Hello Vapor!"])
    }

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
    
    let dummiesController = DummiesController()
    try app.register(collection: dummiesController)
    
    let usersController = UsersController()
    try app.register(collection: usersController)
}
