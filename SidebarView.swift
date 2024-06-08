import SwiftUI
import CoreData

struct SidebarView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: Chat.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Chat.timestamp, ascending: false)]
    ) private var chats: FetchedResults<Chat>
    @State private var selectedChat: Chat?

    var body: some View {
        List {
            ForEach(groupedChats.keys.sorted(by: >), id: \.self) { key in
                Section(header: Text(key)) {
                    ForEach(groupedChats[key] ?? [], id: \.self) { chat in
                        Button(action: {
                            self.selectedChat = chat
                        }) {
                            Text(chat.title ?? "Chat")
                        }
                    }
                    .onDelete(perform: { offsets in
                        deleteChat(at: offsets, in: groupedChats[key] ?? [])
                    })
                }
            }
        }
        .listStyle(SidebarListStyle())
        .navigationTitle("Chats")
        .sheet(item: $selectedChat) { chat in
            ChatView(chat: chat)
        }
    }

    private var groupedChats: [String: [Chat]] {
        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let last7Days = calendar.date(byAdding: .day, value: -6, to: yesterday)!
        let last30Days = calendar.date(byAdding: .day, value: -30, to: today)!
        
        var grouped: [String: [Chat]] = ["Today": [], "Last 7 days": [], "Last 30 days": []]

        for chat in chats {
            if let timestamp = chat.timestamp {
                if calendar.isDateInToday(timestamp) {
                    grouped["Today"]?.append(chat)
                } else if timestamp >= last7Days && timestamp < today {
                    grouped["Last 7 days"]?.append(chat)
                } else if timestamp >= last30Days && timestamp < last7Days {
                    grouped["Last 30 days"]?.append(chat)
                }
            }
        }

        grouped["Today"] = grouped["Today"]?.sorted(by: { $0.timestamp! > $1.timestamp! })
        grouped["Last 7 days"] = grouped["Last 7 days"]?.sorted(by: { $0.timestamp! > $1.timestamp! })
        grouped["Last 30 days"] = grouped["Last 30 days"]?.sorted(by: { $0.timestamp! > $1.timestamp! })

        return grouped
    }

    private func deleteChat(at offsets: IndexSet, in chats: [Chat]) {
        offsets.map { chats[$0] }.forEach(viewContext.delete)
        do {
            try viewContext.save()
        } catch {
            print("Failed to delete chat: \(error.localizedDescription)")
        }
    }
}
