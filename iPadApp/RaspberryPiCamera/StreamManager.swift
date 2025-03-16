// For handling the connection to teh Raspberry Pi

import Foundation
import SwiftUI
import Combine

class StreamManager: ObservableObject {
    @Published var ipAddress: String = UserDefaults.standard.string(forKey: "ipAddress") ?? "192.168.1.1"
    @Published var port : String = UserDefaults.standard.string(forKey: "port") ?? "8000"
    @Published var isConnected: Bool = false
    @Published var errorMessage: String? = nil

    private var cancellables = Set<AnyCancellable>()

    func saveSettings() {
        UserDefaults.standard.set(ipAddress, forKey: "ipAddress")
        UserDefaults.standard.set(port, forKey: "port")
    }

    func getStreamURL() -> URL? {
        guard let portInt = Int(port), portInt > 0 && portInt < 65536 else {
            errorMessage = "Invalid port number"
            return nil
        }

        // Validate IP addresses format (basic validation)
        let ipComponents = ipAddress.split(separator: ".")
        guard ipComponents.count == 4 else {
            errorMessage = "Invalid IP address format"
            return nil
        }

        let urlString = "http://\(ipAddress):\(port)/stream.mjpg"
        return URL(string: urlString)

    }

    func getWebPageURL() -> URL? {
        guard let portInt = Int(port), portInt > 0 && portInt < 65536 else {
            errorMessage = "Invalid port number"
            return nil
        }

        let urlString = "http://\(ipAddress):\(port)/"
        return URL(string: urlString)
    }

    func testConnection() {
        guard let url = getWebPageURL() else {
            isConnected = false
            return
        }

        errorMessage = nil

        let task = URLSession.shared.dataTask(with: url) { [weak self] _, response, error in 
            DispatchQueue.main.async {
               if let error = error {
                self?.errorMessage = "Connection error: \(error.localizedDescription)"
                self?.isConnected = false
                return
               }

               guard let httpResponse = response as? HTTPURLResponse else {
                self?.errorMessage = "Invalid response"
                self?.isConnected = false
                return
               }

               if httpResponse.statusCode == 200 || httpResponse.statusCode == 301 {
                self?.isConnected = true
               } else {
                self?.errorMessage = "Server returned status code: \(httpResponse.statusCode)"
                self?.isConnected = false
               }

            }
        }
        task.resume()
    }

}