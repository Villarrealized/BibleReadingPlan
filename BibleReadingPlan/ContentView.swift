//
//  ContentView.swift
//  BibleReadingPlan
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var audioManager = AudioPlayerEngine.shared
    @StateObject var readingPlan = ReadingPlan(jsonFile: "plan.json")
    @State var showInputDialog = false
    @State private var inputText = ""
    @FocusState private var isTextFieldFocused: Bool
    @State private var showFullPlayer = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            NavigationStack {
                ZStack {
                    Color(.systemGroupedBackground) // matches typical List background
                        .ignoresSafeArea()
                    VStack {
                        HStack {
                            Text("Day \(readingPlan.day)")
                                .font(.title2)
                                .bold()
                            Spacer()
                            Text("Duration: \(formatDuration(audioManager.totalDurationForToday))")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                        .padding(.top, 8)
                        
                        List {
                            ForEach(readingPlan.today) { bucket in
                                HStack {
                                    Text(bucket.chapterName)
                                    Spacer()
                                    Text("\(bucket.day)/\(bucket.totalDays)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .toolbar {
                            ToolbarItem(placement: .primaryAction) {
                                Button("Next") {
                                    readingPlan.setDay(newValue: readingPlan.day + 1)
                                }
                            }
                            ToolbarItem(placement: .primaryAction) {
                                Button {
                                    audioManager.togglePlayPause()
                                } label: {
                                    Image(systemName: audioManager.isPlaying ? "pause.fill" : "play.fill")
                                        .font(.title2)
                                }
                            }
                            ToolbarItem(placement: .secondaryAction) {
                                Button("Go to day") {
                                    showInputDialog = true
                                }
                            }
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Previous") {
                                    readingPlan.setDay(newValue: readingPlan.day - 1)
                                }
                            }
                        }
                        .sheet(isPresented: $showInputDialog) {
                            InputSheet(
                                inputText: $inputText,
                                isPresented: $showInputDialog,
                                readingPlan: readingPlan
                            )
                        }
                    }
                }
            }
            
            MiniPlayerView(showFullPlayer: $showFullPlayer)
                .padding(.horizontal)
                .padding(.bottom)
        }
        .sheet(isPresented: $showFullPlayer) {
            FullPlayerView()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        // MARK: - Dynamic track updates
        .onChange(of: readingPlan.today) { newBuckets in
            AudioPlayerEngine.shared.updateTracks(for: newBuckets)
        }
        
        .onAppear {
            // Pre-start the audio engine to avoid first-play delay
            let engine = AudioPlayerEngine.shared.audioEngine
            if !engine.isRunning {
                do {
                    try engine.start()
                } catch {
                    print("Failed to start audio engine on launch: \(error)")
                }
            }
            
            guard !AudioPlayerEngine.shared.isLoaded else { return }
            if let url = Bundle.main.url(forResource: "bible", withExtension: "mp3") {
                do {
                    try AudioPlayerEngine.shared.loadLargeFile(url: url, tracks: [])
                    AudioPlayerEngine.shared.updateTracks(for: readingPlan.today)
                } catch {
                    print("Error loading audio file: \(error)")
                }
            }
        }
    }
}

private func formatDuration(_ seconds: TimeInterval) -> String {
    let hrs = Int(seconds) / 3600
    let mins = (Int(seconds) % 3600) / 60
    let secs = Int(seconds) % 60
    
    if hrs > 0 {
        return String(format: "%d:%02d:%02d", hrs, mins, secs)
    } else {
        return String(format: "%d:%02d", mins, secs)
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
