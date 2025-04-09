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
        let fieldWidth: CGFloat = 200 // Shared width for TextField and Button

        VStack(spacing: 8) {
            Text("Go to day").font(.headline)
            TextField(String(readingPlan.day), text: $inputText)
                .keyboardType(.numberPad)
                .focused($isTextFieldFocused)
                .frame(width: fieldWidth, height: 36)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(UIColor.secondarySystemBackground))
                )
                .foregroundColor(Color.primary)
                .cornerRadius(8)
                .padding(.top, 8)

            Button(action: {
                let newDay = Int(inputText) ?? readingPlan.day
                readingPlan.setDay(newValue: newDay)
                isPresented = false
            }) {
                Text("Go")
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .cornerRadius(8)
            }
            .frame(width: fieldWidth)
            .padding(.top, 6)
        }
        .padding()
        .presentationDetents([.fraction(0.22)])
        .presentationDragIndicator(.visible)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                isTextFieldFocused = true
            }
        }
        .onDisappear {
            inputText = ""
        }
    }

}
