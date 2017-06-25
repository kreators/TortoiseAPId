
import PerfectLib
import PerfectHTTPServer

initConfiguration()

let server = HTTPServer()
server.serverPort = 80
let routes = makeURLRoutes()
server.addRoutes(routes)

do {
    try server.start()
} catch PerfectError.networkError(let err, let msg) {
    print("Network error thrown: \(err) \(msg)")
}
