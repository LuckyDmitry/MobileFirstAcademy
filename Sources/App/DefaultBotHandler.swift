import Vapor
import TelegramVaporBot

var messages: [ChatGPTRequestBody.Message] = []

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
            if messages.isEmpty {
                messages.append(.init(
                    content: "You are a helper in mobile school, you have to answer only on questions related to programming and mobile stuff. If user asks you something else, you have to say sorry, i can respond only on programming questions, you need to contact Dmitrii Trifonov to resolve it. Be polite, provide code examples and explain everything simple",
                    role: "user"
                ))
            }
            
            messages.append(.init(content: text, role: "user"))

            do {
                let response = try await app.client.post(.init(string: chatGPTurl)) { buildRequest in
                    buildRequest.headers.bearerAuthorization = .init(token: API_KEY)
                    let body = ChatGPTRequestBody(model: "gpt-3.5-turbo", messages: messages)
                    
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
            messages.removeAll()
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
