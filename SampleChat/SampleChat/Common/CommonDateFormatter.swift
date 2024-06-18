//
//  CommonDateFormatter.swift
//  SampleChat
//
//  Created by David on 17.05.2024.
//

import Foundation

class CommonDateFormatter {
    
    private init() { }
    
    public static let shared = CommonDateFormatter()
    
    private let formatter = DateFormatter()
    private let relativeDateFormatter = DateFormatter()
    
    func toTimeStamp(dateString: String) -> Int {
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        guard let date = formatter.date(from: dateString) else { return 0 }
        let dateStamp:TimeInterval = date.timeIntervalSince1970
        
        return Int(dateStamp)
    }
    
    func toString(dateInt: Int) -> String {
        let dateVar = Date(timeIntervalSince1970: (Double(dateInt)))
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        
        return formatter.string(from: dateVar)
    }
    
    func toLastActivityDate(dateString: String) -> String {
        relativeDateFormatter.timeStyle = .none
        relativeDateFormatter.dateStyle = .medium
        relativeDateFormatter.doesRelativeDateFormatting = true
        
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        guard let date = formatter.date(from: dateString) else { return "" }
        
        return relativeDateFormatter.string(from: date)
    }
}
