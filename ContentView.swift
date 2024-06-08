import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedChat: Chat?
    @State private var showingNewChatSheet = false

    var body: some View {
        NavigationView {
            SidebarView(selectedChat: $selectedChat)
                .frame(minWidth: 250)
            
            if let chat = selectedChat {
                ChatView(chat: chat)
            } else {
                Text("Select a chat or start a new one.")
                    .font(.largeTitle)
                    .foregroundColor(.gray)
            }
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: {
                    self.showingNewChatSheet = true
                }) {
                    Label("New Chat", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingNewChatSheet) {
            NavigationView {
                NewChatView { chat in
                    self.selectedChat = chat
                    self.showingNewChatSheet = false
                }
            }
        }
    }
}
