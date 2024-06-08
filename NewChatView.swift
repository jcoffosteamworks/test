import SwiftUI
import CoreData

struct NewChatView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var viewContext
    var onComplete: (Chat) -> Void

    @State private var title: String = ""

    var body: some View {
        VStack {
            TextField("Chat Title", text: $title)
                .padding()

            Button("Create Chat") {
                let newChat = Chat(context: viewContext)
                newChat.id = UUID()
                newChat.timestamp = Date()
                newChat.title = title

                do {
                    try viewContext.save()
                    onComplete(newChat)
                    presentationMode.wrappedValue.dismiss()
                } catch {
                    print("Failed to save new chat: \(error.localizedDescription)")
                }
            }
            .padding()
        }
        .padding()
    }
}
