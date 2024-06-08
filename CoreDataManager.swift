import CoreData

class CoreDataManager {
    static let shared = CoreDataManager()

    private init() {}

    func fetchChats(in context: NSManagedObjectContext) -> [Chat] {
        let fetchRequest: NSFetchRequest<Chat> = Chat.fetchRequest()
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Error fetching chats: \(error)")
            return []
        }
    }

    func fetchMessages(for chat: Chat, in context: NSManagedObjectContext) -> [Message] {
        let fetchRequest: NSFetchRequest<Message> = Message.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "chat == %@", chat)
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Error fetching messages: \(error)")
            return []
        }
    }

    func createChat(title: String, context: NSManagedObjectContext) -> Chat {
        let chat = Chat(context: context)
        chat.id = UUID()
        chat.title = title
        chat.timestamp = Date()
        do {
            try context.save()
        } catch {
            print("Error creating chat: \(error)")
        }
        return chat
    }

    func createMessage(content: String, isUser: Bool, chat: Chat, context: NSManagedObjectContext) -> Message {
        let message = Message(context: context)
        message.id = UUID()
        message.content = content
        message.isUser = isUser
        message.timestamp = Date()
        message.chat = chat
        do {
            try context.save()
        } catch {
            print("Error creating message: \(error)")
        }
        return message
    }
}
