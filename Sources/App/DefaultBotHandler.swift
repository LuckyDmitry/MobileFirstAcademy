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
            guard let apiKey = Environment.get("OPENAI_KEY") else { return }
            // let params: TGSendMessageParams = .init(chatId: .chat(update.message!.chat.id), text: "Success")
            // try bot.sendMessage(params: params)
            let chatGPTurl = "https://api.openai.com/v1/chat/completions"

            do {
                let response = try await app.client.post(.init(string: chatGPTurl)) { buildRequest in
                    buildRequest.headers.bearerAuthorization = .init(token: apiKey)
                    let body = ChatGPTRequestBody(model: "gpt-3.5-turbo", messages: [
                        .init(content: "You are a helper in mobile school, you help students who learn programming. You are programmed to respond only questions related programming, engineering and development. you can respond to technologies, software arhitecture, programming languages, operating systems. Be polite, provide code examples in kotlin if the language is not specified and explain everything simple", role: "user"),
                        .init(content: text, role: "user")
                    
                    ])
                    
                    try buildRequest.content.encode(body)
                }
                
                let result = try response.content.decode(Output.self)
                let resultText = result.choices.first?.message.content ?? "Empty"
                
                let params: TGSendMessageParams = .init(chatId: .chat(message.chat.id), text: resultText)
                try await connection.bot.sendMessage(params: params)
            } catch {
                try await connection.bot.sendMessage(params: .init(chatId: .chat(message.chat.id), text: error.localizedDescription))
            }
            
        }))
    }

    /// Handler for Commands
    private static func commandPingHandler(app: Vapor.Application, connection: TGConnectionPrtcl) async {
        await connection.dispatcher.add(TGCommandHandler(commands: ["/clean"]) { update, bot in
            try await update.message?.reply(text: "Почистили!", bot: bot)
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
