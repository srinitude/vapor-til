@testable import App
import FluentPostgreSQL
import Vapor
import XCTest

final class UserTests: XCTestCase {
    let usersName = "Alice"
    let usersUsername = "alicea"
    let usersURI = "/api/users/"
    var app: Application!
    var conn: PostgreSQLConnection!
    
    override func setUp() {
        try! Application.reset()
        app = try! Application.testable()
        conn = try! app.newConnection(to: .psql).wait()
    }
    
    override func tearDown() {
        conn.close()
    }
    
    func testUsersCanBeRetrievedFromAPI() throws {
        let user = try User.create(name: usersName,
                                   username: usersUsername,
                                   on: conn)
        _ = try User.create(on: conn)
        
        let users = try app.getResponse(to: usersURI, decodeTo: [User].self)
        
        XCTAssertEqual(users.count, 2)
        XCTAssertEqual(users[0].name, usersName)
        XCTAssertEqual(users[0].username, usersUsername)
        XCTAssertEqual(users[0].id, user.id)
    }
    
    func testUserCanBeSavedWithAPI() throws {
        let user = User(name: usersName, username: usersUsername)
        
        let receivedUser = try app.getResponse(to: usersURI,
                                               method: .POST,
                                               headers: ["Content-Type": "application/json"],
                                               data: user,
                                               decodeTo: User.self)
        XCTAssertEqual(receivedUser.name, usersName)
        XCTAssertEqual(receivedUser.username, usersUsername)
        XCTAssertNotNil(receivedUser.id)
        
        let users = try app.getResponse(to: usersURI, decodeTo: [User].self)
        
        XCTAssertEqual(users.count, 1)
        XCTAssertEqual(users[0].name, usersName)
        XCTAssertEqual(users[0].username, usersUsername)
        XCTAssertEqual(users[0].id, receivedUser.id)
    }
    
    func testGettingASingleUserFromTheAPI() throws {
        let user = try User.create(name: usersName, username: usersUsername, on: conn)
        
        let receivedUser = try app.getResponse(
            to: "\(usersURI)\(user.id!)",
            decodeTo: User.self)
        XCTAssertEqual(receivedUser.name, usersName)
        XCTAssertEqual(receivedUser.username, usersUsername)
        XCTAssertEqual(receivedUser.id, user.id)
    }
}
