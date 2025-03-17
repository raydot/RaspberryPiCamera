// For handling the connection to the Raspberry Pi

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
        
        // Validate IP address format (basic validation)
        let ipComponents = ipAddress.split(separator: ".")
        guard ipComponents.count == 4 else {
            errorMessage = "Invalid IP address format"
            return nil
        }
        
        let urlString = "rtsp://\(ipAddress):\(port)/"
        return URL(string: urlString)
    }

    func getWebPageURL() -> URL? {
        // For RTSP there's no web page, but we'll keep this for connection testing
        guard let portInt = Int(port), portInt > 0 && portInt < 65536 else {
            errorMessage = "Invalid port number"
            return nil
        }
        
        // We'll test connection on the RTSP port
        let urlString = "rtsp://\(ipAddress):\(port)/"
        return URL(string: urlString)
    }


        func testConnection() {
        guard let url = getStreamURL() else {
            isConnected = false
            return
        }
        
        errorMessage = nil
        
        // Create a temporary AVPlayer to test connection
        let asset = AVAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)
        
        // Observe the status of the player item
        let statusKeyPath = \AVPlayerItem.status
        
        playerItem.addObserver(self, forKeyPath: statusKeyPath, options: [.new], context: nil)
        
        // Store the observation in cancellables
        let cancellable = AnyCancellable {
            playerItem.removeObserver(self, forKeyPath: statusKeyPath)
        }
        cancellables.insert(cancellable)
        
        // Set a timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            if let cancellable = self?.cancellables.first(where: { $0 === cancellable }) {
                self?.cancellables.remove(cancellable)
            }
            
            if self?.isConnected == false {
                self?.errorMessage = "Connection timed out"
            }
        }
    }

// Override to handle observation
override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
    if keyPath == "status", let playerItem = object as? AVPlayerItem {
        DispatchQueue.main.async { [weak self] in
            switch playerItem.status {
            case .readyToPlay:
                self?.isConnected = true
            case .failed:
                self?.isConnected = false
                self?.errorMessage = "Failed to connect to stream"
            default:
                break
            }
        }
    }
}