//
//  Book.swift
//  HornerBibleReadingPlan
//
//  Created by Nicholas Villarreal on 8/14/24.
//

import Foundation

let userDefaults = UserDefaults.standard

struct BookList: Codable, Identifiable {
    var id: Int
    var books: [BookItem]
    var chapterCount: Int {
        self.books.reduce(0) { $0 + $1.chapters }
    }
}

struct BookItem: Codable, Hashable {
    var name: String
    var chapters: Int
}

struct ReadingBucket: Identifiable {
    var id: Int
    var chapterName: String
    var currentChapter: Int
    var totalChapters: Int
}

class ReadingPlan: ObservableObject {
    init(jsonFile: String) {
        self.bookList = Bundle.main.decode([BookList].self, from: jsonFile)
        let initialDay = userDefaults.integer(forKey: "day")
        self.day = initialDay == 0 ? 1 : initialDay
        self.today = []
        self.setToday()
    }
    
    var bookList: [BookList]
    @Published var day: Int
    @Published var today : [ReadingBucket]
    
    func setDay(newValue: Int) {
        let value = newValue <= 0 ? 1 : newValue
        userDefaults.set(value, forKey: "day")
        self.day = value
        self.setToday()
    }
    
    func setToday() {
        var readingBuckets:[ReadingBucket] = []
        for (listIndex, list) in self.bookList.enumerated() {
            let num = self.day
            var virtualChapter = num % list.chapterCount
            if virtualChapter == 0 {
                virtualChapter = list.chapterCount
            }
            var chapter = 0
            var bookName: String = ""
            for (index, book) in list.books.enumerated() {
                chapter += book.chapters
                if virtualChapter <= chapter {
                    bookName = book.name
                    if index == 0 {
                        chapter = virtualChapter
                    } else {
                        chapter = virtualChapter - list.books.prefix(index).reduce(0) { $0 + $1.chapters }
                    }
                    break
                }
            }
            readingBuckets.append(
                ReadingBucket(
                    id: listIndex,
                    chapterName: "\(bookName) \(chapter)",
                    currentChapter: virtualChapter,
                    totalChapters: list.chapterCount
                )
            )
        }
        self.today = readingBuckets
    }
}
