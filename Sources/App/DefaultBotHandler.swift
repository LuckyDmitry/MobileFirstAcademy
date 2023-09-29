import Vapor
import TelegramVaporBot

final class DefaultBotHandlers {

    static func addHandlers(app: Vapor.Application, connection: TGConnectionPrtcl) async {
        await defaultBaseHandler(app: app, connection: connection)
        await commandPingHandler(app: app, connection: connection)
    }
    
    /// Handler for all updates
    private static func defaultBaseHandler(app: Vapor.Application, connection: TGConnectionPrtcl) async {
        await connection.dispatcher.add(TGBaseHandler({ update, bot in
            guard let message = update.message, let text = message.text else { return }
            // let params: TGSendMessageParams = .init(chatId: .chat(update.message!.chat.id), text: "Success")
            // try bot.sendMessage(params: params)
            let chatGPTurl = "https://api.openai.com/v1/chat/completions"
            let API_KEY = "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"
            let request: [String: Decodable] = [
                "model" : "gpt-3.5-turbo",
                "messages":  [
                    "content": text,
                    "role": "user"
                    
                ]
              ]
            let response = try await app.client.post(.init(string: chatGPTurl)) { buildRequest in
                buildRequest.headers.bearerAuthorization = .init(token: API_KEY)
                let body = ChatGPTRequestBody(model: "gpt-3.5-turbo", messages: [
                    .init(content: text, role: "user")
                ])
                
                try buildRequest.content.encode(body)
            }
            
            let result = try response.content.decode(Output.self)
            let resultText = result.choices.first?.message.content ?? "Empty"
            
            let params: TGSendMessageParams = .init(chatId: .chat(message.chat.id), text: resultText)
            
            try await connection.bot.sendMessage(params: params)
        }))
    }

    /// Handler for Commands
    private static func commandPingHandler(app: Vapor.Application, connection: TGConnectionPrtcl) async {
        await connection.dispatcher.add(TGCommandHandler(commands: ["/ping"]) { update, bot in
            try await update.message?.reply(text: "pong", bot: bot)
        })
    }
}

struct ChatGPTRequestBody: Content {
    struct Message: Content {
        let content: String
        let role: String
    }
    let model: String
    let messages: [Message]
}

struct Output: Decodable {
  struct Choice: Decodable {
    struct Message: Decodable {
      var content: String
    }
    var message: Message
  }
  
  var choices: [Choice] = []
}
