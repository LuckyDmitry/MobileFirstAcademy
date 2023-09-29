import App
import Vapor

var env = try Environment.detect()
try LoggingSystem.bootstrap(from: &env)
let app = Application(env)
defer { app.shutdown() }

let TGBOT: TGBotConnection = .init()

try await configure(app)

try app.run()
