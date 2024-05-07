//
//  DialogDateFormatter.swift
//  SampleChat
//
//  Created by David on 17.05.2024.
//

import Foundation

class DialogDateFormatter {
    
    private init() { }
    
    public static let shared = DialogDateFormatter()
    
    private let formatter = DateFormatter()
    
    func toTimeStamp(dateString: String) -> Int {
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        let date = formatter.date(from: dateString)
        let dateStamp:TimeInterval = date!.timeIntervalSince1970
        
        return Int(dateStamp)
    }
    
    func toString(dateInt: Int) -> String {
        let dateVar = Date(timeIntervalSince1970: (Double(dateInt)))
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        
        return formatter.string(from: dateVar)
    }
}
