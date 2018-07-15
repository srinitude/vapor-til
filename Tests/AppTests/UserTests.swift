import FluentPostgreSQL
import Vapor
import XCTest
@testable import App

final class UserTests: XCTestCase {
    func testUsersCanBeRetrievedFromAPI() throws {
        let expectedName = "Alice"
        let expectedUsername = "alice"
        
        var config = Config.default()
        var services = Services.default()
        var env = Environment.testing
        
        try App.configure(&config, &env, &services)
        let app = try Application(config: config,
                                  environment: env,
                                  services: services)
        try App.boot(app)
        
        let connection = try app.newConnection(to: .psql).wait()
        
        let user = User(name: expectedName,
                        username: expectedUsername)
        let savedUser = try user.save(on: connection).wait()
        try User(name: "Luke", username: "lukes").save(on: connection).wait()
        
        let responder = try app.make(Responder.self)
        
        let request = HTTPRequest(method: .GET, url: URL(string: "/api/users")!)
        let wrappedRequest = Request(http: request, using: app)
        
        let response = try responder.respond(to: wrappedRequest)
                                    .wait()
        
        let data = response.http.body.data
        let users = try JSONDecoder().decode([User].self, from: data!)
        
        XCTAssertEqual(users.count, 2)
        XCTAssertEqual(users[0].name, expectedName)
        XCTAssertEqual(users[0].username, expectedUsername)
        XCTAssertEqual(users[0].id, savedUser.id)
        
        connection.close()
    }
}
