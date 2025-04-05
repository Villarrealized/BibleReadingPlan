//
//  InputSheet.swift
//  BibleReadingPlan
//
//  Created by Nicholas Villarreal on 4/5/25.
//

import SwiftUI

struct InputSheet: View {
    @Binding var inputText: String
    @Binding var isPresented: Bool
    @FocusState private var isTextFieldFocused: Bool
    @ObservedObject var readingPlan: ReadingPlan // Ensure it's passed into the sheet

    var body: some View {
        VStack(spacing: 12) {
            Text("Skip to any day")
                .font(.headline)

            TextField("Enter day", text: $inputText)
                .keyboardType(.numberPad)
                .focused($isTextFieldFocused)
                .frame(height: 36)
                .padding(.horizontal, 12)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.top, 8)

            Button("Go") {
                // Check if input is a valid integer, if not use current day
                let newDay = Int(inputText) ?? readingPlan.day
                readingPlan.setDay(newValue: newDay)
                isPresented = false // Dismiss the sheet after action
            }
            .padding(.top, 6)
            .bold()
        }
        .padding()
        .presentationDetents([.fraction(0.22)])
        .presentationDragIndicator(.hidden)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                isTextFieldFocused = true
            }
        }
    }
}
