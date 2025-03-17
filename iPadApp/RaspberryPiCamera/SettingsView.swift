// For configuration settings

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var streamManager: StreamManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var tempIPAddress: String = ""
    @State private var tempPort: String = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("RTSP Stream Settings")) {
                    TextField("IP Address", text: $tempIPAddress)
                        .keyboardType(.numbersAndPunctuation)
                        .autocapitalization(.none)
                        
                    TextField("Port", text: $tempPort)
                        .keyboardType(.numberPad)
                }

                Section {
                    Button("Test Connection") {
                        streamManager.ipAddress = tempIPAddress
                        streamManager.port = tempPort
                        streamManager.testConnection()
                    }

                    if streamManager.isConnected {
                        Text("Connected!")
                            .foregroundColor(.green)
                    } else if let error = streamManager.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }

                Section {
                    Button("Save") {
                        streamManager.ipAddress = tempIPAddress
                        streamManager.port = tempPort
                        presentationMode.wrappedValue.dismiss()
                    }
                }

            }
            .navigationTitle("Camera Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .onAppear {
                tempIPAddress = streamManager.ipAddress
                tempPort = streamManager.port
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(StreamManager())
    }
}