import SwiftUI
import CoreData

struct ChatView: View {
    @ObservedObject var chat: Chat
    @Environment(\.managedObjectContext) private var viewContext
    @State private var messageText: String = ""
    @State private var streamingResponse: String = ""

    var body: some View {
        VStack {
            List {
                ForEach($chat.messagesArray, id: \.self) { message in
                    HStack {
                        if message.isUser {
                            Spacer()
                            Text(message.content ?? "")
                                .padding()
                                .background(Color.blue.opacity(0.7))
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        } else {
                            Text(message.content ?? "")
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .foregroundColor(.black)
                                .cornerRadius(10)
                            Spacer()
                        }
                    }
                }
                if !streamingResponse.isEmpty {
                    HStack {
                        Spacer()
                        Text(streamingResponse)
                            .padding()
                            .background(Color.blue.opacity(0.7))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .NSManagedObjectContextObjectsDidChange, object: viewContext)) { _ in
                chat.objectWillChange.send()
            }

            HStack {
                TextField("Type a message", text: $messageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button(action: sendMessage) {
                    Text("Send")
                }
                .padding()
            }
            .padding()
        }
        .navigationBarTitle(chat.title ?? "Chat", displayMode: .inline)
    }

    private func sendMessage() {
        guard !messageText.isEmpty else { return }

        let newMessage = CoreDataManager.shared.createMessage(content: messageText, isUser: true, chat: chat, context: viewContext)
        messageText = ""
        
        APIService.shared.sendMessage(newMessage.content ?? "", chat: chat, context: viewContext) { response in
            DispatchQueue.main.async {
                self.streamingResponse = response
            }
        }
    }
}
