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
        guard let filePath = Bundle.main.path(forResource: "Hidden", ofType: "plist"),
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
            ["role": "system", "content": "You are an assistant that generates to-do items in pure JSON format. Each item must include a title, description, date in full ISO 8601 format (e.g., 2022-03-30T10:00:00Z), and isCompleted (true or false). Only return the JSON array. Do not include text or formatting."],
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
                let raw = try JSONSerialization.jsonObject(with: data, options: [])
                print("Raw JSON response: \n\(raw)")
                
                if let json = raw as? [String: Any],
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
    
    func parseNotes(from jsonString: String) -> [Note]? {
        guard let data = jsonString.data(using: .utf8) else {
            print("Could not convert string to data")
            return nil
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            let GeneratedNotes = try decoder.decode([GeneratedNote].self, from: data)
            let converted = GeneratedNotes.map {
                Note(id:0, title: $0.title, description: $0.description, date: $0.date, isCompleted: $0.isCompleted)
            }
            return converted
        } catch {
            print("Failed to decode notes: \(error)")
            return nil
        }
    }
    
    func extractFirstJSONArray(from text: String) -> String? {
        var cleaned = text

        if let range = cleaned.range(of: "```json") {
            cleaned.removeSubrange(range)
        }
        if let range = cleaned.range(of: "```") {
            cleaned.removeSubrange(range)
        }

        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let startIndex = cleaned.firstIndex(of: "["),
              let endIndex = cleaned.lastIndex(of: "]") else {
            print("Could not find JSON array in cleaned text")
            return nil
        }

        let jsonSubstring = cleaned[startIndex...endIndex]
        return String(jsonSubstring)
    }
    
    struct GeneratedNote: Codable {
        let title: String
        let description: String
        let date: Date
        let isCompleted: Bool
    }
}
