import Fluent
import Vapor

struct AcronymsController: RouteCollection {
    func boot(router: Router) throws {
        let acronymsRoutes = router.grouped("api", "acronyms")
        acronymsRoutes.get(use: getAllHandler)
        acronymsRoutes.post(use: createHandler)
        acronymsRoutes.get(Acronym.parameter, use: getHandler)
        acronymsRoutes.put(Acronym.parameter, use: updateHandler)
        acronymsRoutes.delete(Acronym.parameter, use: deleteHandler)
        acronymsRoutes.get("search", use: searchHandler)
        acronymsRoutes.get("first", use: getFirstHandler)
        acronymsRoutes.get("sorted", use: sortedHandler)
        acronymsRoutes.get(Acronym.parameter, "user", use: getUserHandler)
        acronymsRoutes.post(Acronym.parameter,
                            "categories",
                            Category.parameter,
                            use: addCategoriesHandler)
        acronymsRoutes.get(Acronym.parameter,
                           "categories",
                           use: getCategoriesHandler)
    }
    
    // MARK: - GET /api/acronyms
    func getAllHandler(_ req: Request) -> Future<[Acronym]> {
        return Acronym.query(on: req).all()
    }
    
    // MARK: - GET /api/acronyms/:id
    func getHandler(_ req: Request) throws -> Future<Acronym> {
        return try req.parameters.next(Acronym.self)
    }
    
    // MARK: - GET /api/acronyms/search
    func searchHandler(_ req: Request) throws -> Future<[Acronym]> {
        guard let searchTerm = req.query[String.self, at: "term"] else {
            throw Abort(.badRequest)
        }
        return Acronym.query(on: req)
            .group(.or) { or in
                or.filter(\.short == searchTerm)
                or.filter(\.long == searchTerm)
        }.all()
    }
    
    // MARK: - GET /api/acronyms/first
    func getFirstHandler(_ req: Request) throws -> Future<Acronym> {
        return Acronym.query(on: req)
            .first()
            .map(to: Acronym.self) { acronym in
                guard let acronym = acronym else { throw Abort(.notFound) }
                return acronym
        }
    }
    
    // MARK: - GET /api/acronyms/sorted
    func sortedHandler(_ req: Request) throws -> Future<[Acronym]> {
        return Acronym.query(on: req)
            .sort(\.short, .ascending)
            .all()
    }
    
    // MARK: - GET /api/acronyms/:id/user
    func getUserHandler(_ req: Request) throws -> Future<User> {
        return try req.parameters
                    .next(Acronym.self)
                    .flatMap(to: User.self) { acronym in
            return acronym.user.get(on: req)
        }
    }
    
    // MARK: - GET /api/acronyms/:id/categories
    func getCategoriesHandler(_ req: Request) throws -> Future<[Category]> {
        return try req.parameters
                    .next(Acronym.self)
                    .flatMap(to: [Category].self) { acronym in
            try acronym.categories.query(on: req).all()
        }
    }
    
    // MARK: - POST /api/acronyms
    func createHandler(_ req: Request) throws -> Future<Acronym> {
        return try req.content
                      .decode(Acronym.self)
                      .flatMap(to: Acronym.self) { acronym in
            return acronym.save(on: req)
        }
    }
    
    // MARK: - POST /api/acronyms/:id/categories/:category_id
    func addCategoriesHandler(_ req: Request) throws -> Future<HTTPStatus> {
        return try flatMap(to: HTTPStatus.self,
                           req.parameters.next(Acronym.self),
                           req.parameters.next(Category.self)) { acronym, category in
            let pivot = try AcronymCategoryPivot(acronym.requireID(), category.requireID())
            return pivot.save(on: req).transform(to: .created)
        }
    }
    
    // MARK: - PUT /api/acronyms/:id
    func updateHandler(_ req: Request) throws -> Future<Acronym> {
        return try flatMap(to: Acronym.self,
                           req.parameters.next(Acronym.self),
                           req.content.decode(Acronym.self)) {
            acronym, updatedAcronym in
            acronym.short = updatedAcronym.short
            acronym.long = updatedAcronym.long
            acronym.userID = updatedAcronym.userID
            
            return acronym.save(on: req)
        }
    }
    
    // MARK: - DELETE /api/acronyms/:id
    func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> {
        return try req.parameters.next(Acronym.self)
            .delete(on: req)
            .transform(to: HTTPStatus.noContent)
    }
}
