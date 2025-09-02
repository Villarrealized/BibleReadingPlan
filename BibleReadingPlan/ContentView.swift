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
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            if isLoading {
                LoadingView()
            } else {
                ZStack(alignment: .bottom) {
                    NavigationStack {
                        ZStack {
                            Color(.systemGroupedBackground)
                                .ignoresSafeArea()
                            VStack {
                                DayHeaderView(
                                    day: readingPlan.day,
                                    duration: audioManager.totalDurationForToday
                                )
                                
                                ChapterListView(
                                    readingPlan: readingPlan,
                                    audioManager: audioManager,
                                    showInputDialog: $showInputDialog,
                                    inputText: $inputText
                                )
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
            }
        }
        .onAppear {
            if let url = Bundle.main.url(forResource: "bible", withExtension: "mp3") {
                do {
                    try AudioPlayerEngine.shared.loadLargeFile(url: url, tracks: [])
                    AudioPlayerEngine.shared.updateTracks(for: readingPlan.today)
                    // TODO: fix - Preload workaround
                    AudioPlayerEngine.shared.togglePlayPause()
                    AudioPlayerEngine.shared.togglePlayPause()
                } catch {
                    print("Error loading audio file: \(error)")
                }
            }
            // Arbitrary delay to temporarily solve the issue with the audio not being ready
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                isLoading = false
            }
        }
    }
}

struct LoadingView: View {
    var body: some View {
        VStack {
            ProgressView("Loading audio...")
                .progressViewStyle(CircularProgressViewStyle())
                .padding()
        }
    }
}

struct DayHeaderView: View {
    let day: Int
    let duration: TimeInterval
    
    var body: some View {
        HStack {
            Text("Day \(day)")
                .font(.title2)
                .bold()
            Spacer()
            Text("Duration: \(formatDuration(duration))")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

struct ChapterListView: View {
    @ObservedObject var readingPlan: ReadingPlan
    @ObservedObject var audioManager: AudioPlayerEngine
    @Binding var showInputDialog: Bool
    @Binding var inputText: String
    
    var body: some View {
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

//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}
