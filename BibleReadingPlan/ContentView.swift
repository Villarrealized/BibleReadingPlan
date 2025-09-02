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
    
    init() {
        if let url = Bundle.main.url(forResource: "bible", withExtension: "mp3") {
            do {
                try AudioPlayerEngine.shared.loadLargeFile(url: url, tracks: [])
                // Initial load for today's buckets
                AudioPlayerEngine.shared.updateTracks(for: readingPlan.today)
            } catch {
                print("Error loading audio file: \(error)")
            }
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            NavigationStack {
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
                .navigationTitle("Day \(readingPlan.day)")
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
    
    // MARK: - Load tracks helper
    func loadAllChapters() -> [ChapterJSON] {
        guard let url = Bundle.main.url(forResource: "chapters", withExtension: "json") else {
            print("chapters.json not found")
            return []
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([ChapterJSON].self, from: data)
        } catch {
            print("Error decoding chapters.json: \(error)")
            return []
        }
    }
    
    func loadTracksForToday(todayBuckets: [ReadingBucket]) -> [VirtualTrack] {
        let allChapters = loadAllChapters()
        var tracks: [VirtualTrack] = []
        
        for bucket in todayBuckets {
            let matchingChapters = allChapters.filter { chapter in
                chapter.name.starts(with: bucket.bookName) &&
                (Int(chapter.name.components(separatedBy: " ").last ?? "") ?? 0) >= bucket.startChapter &&
                (Int(chapter.name.components(separatedBy: " ").last ?? "") ?? 0) <= bucket.endChapter
            }
            let bucketTracks = matchingChapters.map { chapter in
                VirtualTrack(title: chapter.name, startTime: chapter.start, endTime: chapter.end)
            }
            tracks.append(contentsOf: bucketTracks)
        }
        return tracks
    }
}
