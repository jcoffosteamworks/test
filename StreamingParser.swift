import Foundation

class StreamingParser {
    var onData: ((String) -> Void)?
    var onEnd: (() -> Void)?

    func parse(data: Data) {
        let delimiter = "\n"
        let dataString = String(data: data, encoding: .utf8) ?? ""
        let lines = dataString.components(separatedBy: delimiter)

        for line in lines {
            if line.isEmpty {
                continue
            }

            print("Received line: \(line)")

            if line == "data: [DONE]" {
                onEnd?()
                continue
            }

            guard let jsonData = line.data(using: .utf8) else {
                print("Failed to convert line to data: \(line)")
                continue
            }

            do {
                if let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any],
                   let choices = jsonObject["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let delta = firstChoice["delta"] as? [String: Any],
                   let content = delta["content"] as? String {
                    print("Parsed content: \(content)")
                    onData?(content)
                }
            } catch {
                print("Failed to parse line: \(line), error: \(error)")
            }
        }
    }
}
