//
//  ContentView.swift
//  BibleReadingPlan
//
//  Created by Nicholas Villarreal on 4/5/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject var readingPlan = ReadingPlan(jsonFile: "plan.json")
    @State var showInputDialog = false
    @State private var inputText = ""
    @FocusState private var isTextFieldFocused: Bool
    
    
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(readingPlan.today) { chapter in
                    Text(chapter.name)
                }
            }
            .navigationTitle("Day \(readingPlan.day)")
            .toolbar {
                ToolbarItem(placement:.primaryAction) {
                    Button("Next") {
                        readingPlan.setDay(newValue: readingPlan.day + 1)
                    }
                }
                ToolbarItem(placement: .secondaryAction) {
                    Button("Goto") {
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
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
