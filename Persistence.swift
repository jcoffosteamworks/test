import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init() {
        container = NSPersistentContainer(name: "TeamworksAI")
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Unable to load persistent stores: \(error)")
            }
        }
    }

    static var preview: PersistenceController = {
        let result = PersistenceController()
        let viewContext = result.container.viewContext
        
        // Create sample data for preview purposes
        for i in 0..<10 {
            let newChat = Chat(context: viewContext)
            newChat.id = UUID()
            newChat.timestamp = Date()
            newChat.title = "Sample Chat \(i)"
            
            for j in 0..<5 {
                let newMessage = Message(context: viewContext)
                newMessage.id = UUID()
                newMessage.timestamp = Date()
                newMessage.content = "Sample message \(j)"
                newMessage.isUser = j % 2 == 0
                newMessage.chat = newChat
            }
        }

        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        
        return result
    }()
}
