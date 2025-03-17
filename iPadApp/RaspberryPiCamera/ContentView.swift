// Main view controller

import SwiftUI
struct ContentView: View {
    @StateObject var streamManager: StreamManager()
    @State private var showingSettnigs = false

    var body: some View {
        ZStack {
            // Video stream takes up the full screen
            VideoStreamView()
                .environmentObject(streamManager)
                .edgesIgnoringSafeArea(.all)

            VStack {
                Spacer()

                // Connection status indicator
                HStack {
                    Spacer()

                    VStack {
                        if streamManager.isConnected {
                            Text("Connected")
                                .foregroundColor(.green)
                                .padding(6)
                                .background(Color.black.opacity(0.5))
                                .cornerRadius(8)
                        } else {
                            Text("Not Connected")
                                .foregroundColor(.red)
                                .padding(6)
                                .background(Color.black.opacity(0.5))
                                .cornerRadius(8)
                        }

                        Button(action: {
                            streamManager.testConnection()
                        }) {
                            Image(systemName: "arrow.clockwise.circle")
                                .font(.title)
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.trailing)
                }
                .padding(.bottom)
            }

            // Settings button in top right
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gear")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .padding()
                }
                Spacer()
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .environmentObject(streamManager)
        }
        .onAppear {
            streamManager.testConnection()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}