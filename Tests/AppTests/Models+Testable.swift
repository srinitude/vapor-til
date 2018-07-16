import FluentPostgreSQL
@testable import App

extension User {
    static func create(
        name: String = "Luke",
        username: String = "lukes",
        on connection: PostgreSQLConnection
        ) throws -> User {
        let user = User(name: name, username: username)
        return try user.save(on: connection).wait()
    }
}

extension Acronym {
    static func create(
        short: String = "TIL",
        long: String = "Today I Learned",
        user: User? = nil,
        on connection: PostgreSQLConnection
        ) throws -> Acronym {
        var acronymsUser = user
        
        if acronymsUser == nil {
            acronymsUser = try User.create(on: connection)
        }
        
        let acronym = Acronym(short: short,
                              long: long,
                              userID: acronymsUser!.id!)
        return try acronym.save(on: connection).wait()
    }
}
