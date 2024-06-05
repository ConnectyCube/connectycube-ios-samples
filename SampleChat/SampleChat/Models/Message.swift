//
//  Message.swift
//  SampleChat
//
//  Created by David on 05.06.2024.
//

import UIKit
import MessageKit

struct Message: MessageType {
    var sender: SenderType
    var messageId: String
    var sentDate: Date
    var kind: MessageKind
    var status: String
    
    var description: String {
        return "sender: \(sender), messageId: \(messageId), sentDate: \(sentDate), kind: \(kind), status: \(status)"
    }
}
