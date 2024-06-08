import Foundation
import CoreData

extension CodingUserInfoKey {
    static let context = CodingUserInfoKey(rawValue: "context")
}

class APIService {
    static let shared = APIService()
       private let apiKey: String

       init() {
           guard let key = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] else {
               fatalError("API key not found in environment variables")
           }
           self.apiKey = key
       }

    func sendMessage(_ message: String, chat: Chat, context: NSManagedObjectContext, completion: @escaping (String) -> Void) {
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let messages: [[String: String]] = [
            ["role": "user", "content": message]
        ]

        let body: [String: Any] = [
            "model": "gpt-4o",
            "messages": messages,
            "stream": true
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
                print("Unauthorized request. Check your API key.")
                return
            }

            guard let data = data, error == nil else {
                print("Failed to fetch data: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                self.handleStreamedResponse(data, chat: chat, context: context, completion: completion)
            } else {
                print("Unexpected response status code: \(response)")
            }
        }

        task.resume()
    }

    func sendMessageStreaming(_ message: String, chat: Chat, context: NSManagedObjectContext, completion: @escaping (String) -> Void) {
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let messages: [[String: String]] = [
            ["role": "user", "content": message]
        ]

        let body: [String: Any] = [
            "model": "gpt-4o",
            "messages": messages,
            "stream": true
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
                print("Unauthorized request. Check your API key.")
                return
            }

            guard let data = data, error == nil else {
                print("Failed to fetch data: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                self.handleStreamedResponse(data, chat: chat, context: context, completion: completion)
            } else {
                print("Unexpected response status code: \(response)")
            }
        }

        task.resume()
    }

    private func handleStreamedResponse(_ data: Data, chat: Chat, context: NSManagedObjectContext, completion: @escaping (String) -> Void) {
        let decoder = JSONDecoder()
        decoder.userInfo[CodingUserInfoKey.context!] = context

        var responseString = ""
        if let stringData = String(data: data, encoding: .utf8) {
            responseString = stringData
        }

        let lines = responseString.split(separator: "\n")
        var accumulatedResponse = ""
        for line in lines {
            guard line.hasPrefix("data:") else { continue }

            let jsonString = line.dropFirst(5).trimmingCharacters(in: .whitespaces)
            guard !jsonString.isEmpty else { continue }

            do {
                let responseData = jsonString.data(using: .utf8)!
                let apiResponse = try JSONDecoder().decode(APIResponse.self, from: responseData)
                for choice in apiResponse.choices {
                    if let delta = choice.delta.content {
                        accumulatedResponse += delta
                        DispatchQueue.main.async {
                            completion(accumulatedResponse)
                        }
                    }
                }
            } catch {
                print("Failed to decode JSON: \(error.localizedDescription)")
            }
        }
    }

    func summarizeChat(_ chat: Chat, context: NSManagedObjectContext, completion: @escaping (String?) -> Void) {
        let url = URL(string: "https://api.openai.com/v1/engines/davinci-codex/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let messages = CoreDataManager.shared.fetchMessages(for: chat, in: context).map { $0.content ?? "" }.joined(separator: "\n")
        let prompt = "Summarize the following conversation in less than 8 words:\n\(messages)"

        let body: [String: Any] = [
            "prompt": prompt,
            "max_tokens": 50
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("Failed to fetch data: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
                return
            }

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                    let choices = json?["choices"] as? [[String: Any]]
                    let text = choices?.first?["text"] as? String
                    completion(text?.trimmingCharacters(in: .whitespacesAndNewlines))
                } catch {
                    print("Failed to parse JSON: \(error.localizedDescription)")
                    completion(nil)
                }
            } else {
                print("Unexpected response status code: \(response)")
                completion(nil)
            }
        }

        task.resume()
    }
}

struct APIResponse: Codable {
    struct Choice: Codable {
        struct Delta: Codable {
            let content: String?
        }

        let delta: Delta
    }

    let choices: [Choice]
}
