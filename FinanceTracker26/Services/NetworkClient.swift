import Foundation

struct NetworkClient {
    func getString(url: URL, timeoutSeconds: TimeInterval = 20) async throws -> String {
        var request = URLRequest(url: url)
        request.timeoutInterval = timeoutSeconds
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)", forHTTPHeaderField: "User-Agent")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return String(decoding: data, as: UTF8.self)
    }

    func getJSON<T: Decodable>(url: URL, timeoutSeconds: TimeInterval = 20, as type: T.Type) async throws -> T {
        var request = URLRequest(url: url)
        request.timeoutInterval = timeoutSeconds
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }
}
