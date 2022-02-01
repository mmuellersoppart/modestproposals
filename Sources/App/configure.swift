import Fluent
import FluentPostgresDriver
import Leaf
import Vapor

// configures your application
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    let databaseName: String
    let databasePort: Int
    if (app.environment == .testing) {
        databaseName = "a_modest_db_test"
        if let testPort = Environment.get("DATABASE_PORT") {
            databasePort = Int(testPort) ?? 5433
        } else {
            databasePort = 5433
        }
    } else {
        databaseName = "a_modest_db"
        databasePort = 5432
    }
    
    if var config = Environment.get("DATABASE_URL")
        .flatMap(URL.init)
        .flatMap(PostgresConfiguration.init) {
        config.tlsConfiguration = .makeClientConfiguration()
      app.databases.use(.postgres(
        configuration: config
      ), as: .psql)
    } else {
      app.databases.use(
        .postgres(
          hostname: Environment.get("DATABASE_HOST") ??
            "localhost",
          port: databasePort,
          username: Environment.get("DATABASE_USERNAME") ??
            "vapor_username",
          password: Environment.get("DATABASE_PASSWORD") ??
            "vapor_password",
          database: Environment.get("DATABASE_NAME") ??
            databaseName),
        as: .psql)
    }

    app.views.use(.leaf)
    
    app.migrations.add(CreateUser())
    app.migrations.add(CreateToken())
    app.migrations.add(CreateAdminUser())
    app.migrations.add(CreateProposal())

    // why we can send public files like css
    let file = FileMiddleware(publicDirectory: app.directory.publicDirectory)
    app.middleware.use(file)
    
    // allows website to talk to other websites
    let corsConfiguration = CORSMiddleware.Configuration(allowedOrigin: .all, allowedMethods: [.GET, .POST], allowedHeaders: [.accept, .contentType, .origin, .accessControlAllowOrigin, .authorization]
    )
    let cors = CORSMiddleware(configuration: corsConfiguration)
    app.middleware.use(cors, at: .beginning)
    
    // using sessions
    app.middleware.use(app.sessions.middleware)
    app.middleware.use(User.asyncSessionAuthenticator())
    
    // log to .debug level. (you can see when the migration happens)
    app.logger.logLevel = .debug
    
    try app.autoMigrate().wait()
    
    // register routes
    try routes(app)
}
