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
    var chaptersPerDay: Int?
    
    var chapterCount: Int {
        self.books.reduce(0) { $0 + $1.chapters }
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case books
        case chaptersPerDay = "chapters_per_day"
    }
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int.self, forKey: .id)
        self.books = try container.decode([BookItem].self, forKey: .books)
        self.chaptersPerDay = try container.decodeIfPresent(Int.self, forKey: .chaptersPerDay)
        
        if chaptersPerDay != nil {
            assert(self.books.count == 1, "Cannot use chapters_per_day if there is more than one book in the list. Found more than one book with list id: \(id)")
        }
    }
}

struct BookItem: Codable, Hashable {
    var name: String
    var chapters: Int
}

struct ReadingBucket: Identifiable {
    var id: Int
    var chapterName: String
    var day: Int
    var totalDays: Int
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
            let chaptersPerDay = list.chaptersPerDay ?? 1
            var totalDays = list.chapterCount
            
            if chaptersPerDay > 1 {
                totalDays = Int(ceil(Double(list.chapterCount) / Double(chaptersPerDay)))
            }
            
            var virtualChapter = self.day % totalDays
            if virtualChapter == 0 {
                virtualChapter = totalDays
            }
            
            var chapter = 0
            var bookName: String = ""
            var totalChapters: Int = 0
            
            for (index, book) in list.books.enumerated() {
                chapter += book.chapters
                totalChapters = book.chapters
                
                if virtualChapter <= chapter {
                    bookName = book.name
                    // first book in the list
                    if index == 0 {
                        chapter = virtualChapter
                    } else {
                        chapter = virtualChapter - list.books.prefix(index).reduce(0) { $0 + $1.chapters }
                    }
                    break
                }
            }
            
            var chapterName = "\(bookName) \(chapter)"
            var day = virtualChapter
            
            if chaptersPerDay > 1 {
                let startChapter = ((chapter - 1) * chaptersPerDay) + 1
                let endChapter = min((startChapter + chaptersPerDay - 1), totalChapters)
                if startChapter == endChapter {
                    chapterName = "\(bookName) \(startChapter)"
                } else {
                    chapterName = "\(bookName) \(startChapter)-\(endChapter)"
                }
                day = virtualChapter
            }
            
            readingBuckets.append(
                ReadingBucket(
                    id: listIndex,
                    chapterName: chapterName,
                    day: day,
                    totalDays: totalDays
                )
            )
        }
        self.today = readingBuckets
    }
}
