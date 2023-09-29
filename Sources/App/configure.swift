import Foundation
import Vapor
import TelegramVaporBot

let tgApi: String = "6404683601:AAFRr8n4sGmkQz0sD4q1aLLC2M51e3Myrkw"

actor TGBotConnection {
    private var _connection: TGConnectionPrtcl!

    var connection: TGConnectionPrtcl {
        self._connection
    }
    
    func setConnection(_ conn: TGConnectionPrtcl) {
        self._connection = conn
    }
}

public func configure(_ app: Application) async throws {
    /// set level of debug if you needed
    TGBot.log.logLevel = app.logger.logLevel
    let bot: TGBot = .init(app: app, botId: tgApi)
    await TGBOT.setConnection(try await TGLongPollingConnection(bot: bot))
    await DefaultBotHandlers.addHandlers(app: app, connection: TGBOT.connection)
    try await TGBOT.connection.start()

    try routes(app)
}
