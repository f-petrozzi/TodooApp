//
//  AIService.swift
//  Todoo
//
//  Created by Fabrizio Petrozzi on 6/15/25.
//

import Foundation

class AIService {
    static let shared = AIService()
    
    private var apiKey: String{
        guard let filePath = Bundle.main.path(forResource: "hidden", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: filePath),
              let key = plist["apiKey"] as? String else {
            fatalError("API Key not found")
        }
        return key
    }

    private let apiURL = URL(string: "https://api.openai.com/v1/chat/completions")!
    
    func generateNotes(from prompt: String, completion: @escaping (String?) -> Void) {
        let headers = [
            "Content-Type": "application/json",
            "Authorization": "Bearer \(apiKey)"
        ]
        
        let messages: [[String: String]] = [
            ["role": "system", "content": "You are an assistant that creates to-do lists in JSON format. Each to-do item should have a title, description, date (in ISO 8601), and completion status as true or false. Only respond with a JSON array of to-do items. Do not include explanations or extra text."],
            ["role": "user", "content": prompt]
        ]
        
        let body: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "temperature": 0.7,
            "messages": messages
        ]
        
        guard let httpBody = try? JSONSerialization.data(withJSONObject: body, options: []) else {
            print("Failed to serialize JSON")
            completion(nil)
            return
        }
        
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.httpBody = httpBody
        request.allHTTPHeaderFields = headers
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Request failed: \(error)")
                completion(nil)
                return
            }
            
            guard let data = data else {
                print("No data received")
                completion(nil)
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let message = choices.first?["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    completion(content)
                } else {
                    print("Unexpected response format")
                    completion(nil)
                }
            } catch {
                print("JSON parsing error: \(error)")
                completion(nil)
            }
        }.resume()
    }
}
