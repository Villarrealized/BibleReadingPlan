//
//  ContentView.swift
//  BibleReadingPlan
//
//  Created by Nicholas Villarreal on 4/5/25.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var audioManager = AudioPlayerEngine.shared
    @StateObject var readingPlan = ReadingPlan(jsonFile: "plan.json")
    @State var showInputDialog = false
    @State private var inputText = ""
    @FocusState private var isTextFieldFocused: Bool
    @State var playStateIconName = "play.fill"
    
    @State private var showFullPlayer = false
    
    init() {
        if let url = Bundle.main.url(forResource: "bible", withExtension: "mp3") {
            let tracks = loadChapters()
            
            do {
                try AudioPlayerEngine.shared.loadLargeFile(url: url, tracks: tracks)
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
                            Text("\(bucket.day)/\(bucket.totalDays)").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                .navigationTitle("Day \(readingPlan.day)")
                .toolbar {
                    ToolbarItem(placement:.primaryAction) {
                        Button("Next") {
                            readingPlan.setDay(newValue: readingPlan.day + 1)
                        }
                    }
                    ToolbarItem(placement:.primaryAction) {
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
                        isPresented: $showInputDialog, readingPlan: readingPlan
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
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
