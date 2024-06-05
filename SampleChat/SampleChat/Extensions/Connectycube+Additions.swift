//
//  Connectycube+Additions.swift
//  SampleChat
//
//  Created by David on 05.06.2024.
//

import MessageKit
import ConnectyCube

extension ConnectycubeMessage {
    private func formatOccupantsIds(_ currentSender: SenderType, _ chatDialog: ConnectycubeDialog) -> [Int] {
        var occupantsIds: [Int] = chatDialog.occupantsIds! as! [Int]
        occupantsIds.remove(at: occupantsIds.firstIndex(of: Int(currentSender.senderId)!)!)
        return occupantsIds
    }
    
    func isRead(_ currentSender: SenderType, _ chatDialog: ConnectycubeDialog) -> Bool {
       // return self.readIds != nil && self.readIds!.contains(currentSender.senderId)// for incoming
        if(chatDialog.type == ConnectycubeDialogType.companion.PRIVATE) {
            return (self.readIds?.contains(self.recipientId!)) != nil
        }
        return self.readIds != nil && (self.readIds! as! [Int]).any(formatOccupantsIds(currentSender, chatDialog))
    }
    
    func isDelivered(_ currentSender: SenderType, _ chatDialog: ConnectycubeDialog) -> Bool {
        if(chatDialog.type == ConnectycubeDialogType.companion.PRIVATE) {
            return (self.deliveredIds?.contains(self.recipientId!)) != nil
        }
        return self.deliveredIds != nil && (self.deliveredIds! as! [Int]).any(formatOccupantsIds(currentSender, chatDialog))
    }
    
    func isSent(_ currentSender: SenderType) -> Bool {
        return self.deliveredIds != nil && self.deliveredIds!.contains(currentSender.senderId)
    }

    func toMessage(_ currentSender: SenderType, _ dialog: ConnectycubeDialog, _ occupants: [Int32: ConnectycubeUser]) -> Message {
        
        let sender: SenderType
        if(self.senderId == Int32(currentSender.senderId)?.asXPInt()) {
            sender = currentSender
        } else {
            let displayName: String? = occupants[self.senderId as! Int32]?.fullName ?? occupants[self.senderId as! Int32]?.login!
            sender = Sender(senderId: self.senderId!.stringValue, displayName: displayName ?? "Not from app")
        }

        let status: String = {
            if isRead(currentSender, dialog) {
                return "Read"
            } else if (isDelivered(currentSender, dialog)) {
                return "Delivered"
            } else if (isSent(currentSender)) {
                return "Sent"
            } else {
                return "Empty"
            }
        }()
        let kind: MessageKind
        let attachments:[ConnectycubeAttachment]? = self.attachments?.mutableCopy() as? [ConnectycubeAttachment]
        if(attachments != nil && !attachments!.isEmpty) {
            let mediaItem: AttachmentItem = AttachmentItem(connectycubeAttachment: (attachments?.first)!)
            kind = .photo(mediaItem)
        } else {
            kind = .text(self.body!)
        }
        
        return Message(sender: sender,
                       messageId: self.messageId!,
                       sentDate: Date(timeIntervalSince1970: TimeInterval(truncating: self.dateSent!)),
                       kind: kind,
                       status: status)
    }
}
