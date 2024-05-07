//
//  ChatViewController.swift
//  SampleChat
//
//  Created by David on 06.05.2024.
//

import UIKit
import InputBarAccessoryView
import MessageKit
import ConnectyCube

class ChatViewController: MessagesViewController, MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {
    
    static func navigateTo(_ controller: UIViewController, _ dialog: ConnectycubeDialog) {
        let vc = ChatViewController(dialog)
        vc.title = "Chat"
        controller.navigationController?.pushViewController(vc, animated: true)
    }
    
    var currentDialog: ConnectycubeDialog?
    let currentUser: ConnectycubeUser = ConnectycubeSessionManager().activeSession!.user!
    var currentSender: SenderType = Sender(senderId: String(ConnectycubeSessionManager().activeSession!.user!.id), displayName: (ConnectycubeSessionManager().activeSession!.user!.fullName ?? ConnectycubeSessionManager().activeSession!.user!.login)!)
    
    open lazy var attachmentManager: AttachmentManager = { [unowned self] in
        let manager = AttachmentManager()
        manager.delegate = self
        manager.showAddAttachmentCell = false
        return manager
    }()
    
    var attachmentData = [UIImage: URL]()
    
    var typingTimer = Timer()

    var messages = [Message]()
    var cubeMessages = [ConnectycubeMessage]()
    var occupants = [Int32: ConnectycubeUser]()

    var messageListener = ConnectycubeMessageListenerImpl()
    var messageTypingListener = ConnectycubeChatTypingListenerImpl()
    var messageSentListener = ConnectycubeMessageSentListenerImpl()
    var messageStatusListener = ConnectycubeMessageStatusListenerImpl()

    init(_ dialog: ConnectycubeDialog) {
        self.currentDialog = dialog
        super.init(nibName: nil, bundle: nil)
        messageListener.chatViewController = self
        messageTypingListener.chatViewController = self
        messageSentListener.chatViewController = self
        messageStatusListener.chatViewController = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    deinit {
        print("ChatViewController deinit called")
        deinitChat()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Dialogs", style: .plain, target: self, action: #selector(backToDialogs))
        
        initResources()
        configureAvatarView()
        configureMessageCollectionView()
        configureMessageInputBar()
        
        initChat()
    }
    
    @objc func backToDialogs() {
        self.navigationController?.popToViewController(ofClass: DialogViewController.self)
    }
    
    func initResources() {
        Task.init {
            do {
                try await initOcuppants()
                try await loadMessages()
            } catch let error {
                AlertBuilder.showErrorAlert(self, "Error", "create dialog: \(error.localizedDescription)")
            }
        }
    }
    
    func initOcuppants() async throws {
        let ids = Set(currentDialog!.occupantsIds as! [KotlinInt])
        let users = try await ConnectyCube().getUsersByIds(ids: ids, pagination: nil, sorter: nil).items as! [ConnectycubeUser]
        users.forEach { user in
            occupants[user.id] = user
        }
    }

    func configureAvatarView() {
        messagesCollectionView.messagesCollectionViewFlowLayout.setMessageIncomingAvatarPosition(.init(vertical: .messageTop))
        messagesCollectionView.messagesCollectionViewFlowLayout.setMessageOutgoingAvatarPosition(.init(vertical: .messageTop))
    }
    
    func configureMessageCollectionView() {
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messageCellDelegate = self
        
        scrollsToLastItemOnKeyboardBeginsEditing = true // default false
        maintainPositionOnInputBarHeightChanged = true // default false
        showMessageTimestampOnSwipeLeft = true // default false
    }
    
    func configureMessageInputBar() {
        messageInputBar.delegate = self
        messageInputBar.inputPlugins = [attachmentManager]
        messageInputBar.inputTextView.keyboardType = .twitter
        
        let attachmentItem = InputBarButtonItem(type: .system)
        attachmentItem.tintColor = .gray
        attachmentItem.image = UIImage(systemName: "plus")
        attachmentItem.addTarget(self, action: #selector(attachmentPressed), for: .primaryActionTriggered)
        attachmentItem.setSize(CGSize(width: 60, height: 30), animated: false)

        messageInputBar.leftStackView.alignment = .center
        messageInputBar.setLeftStackViewWidthConstant(to: 50, animated: false)
        messageInputBar.setStackViewItems([attachmentItem], forStack: .left, animated: false)
    }
    
    @objc func attachmentPressed() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true, completion: nil)
    }
    
    func setTypingIndicator() {
        setTypingIndicatorViewHidden(false, animated: true, completion:  { [weak self] success in
            if success, self?.isLastSectionVisible() == true {
                self?.messagesCollectionView.scrollToLastItem(animated: true)
            }
        })
        restartTypingTimer()
    }
    
    func restartTypingTimer() {
        typingTimer.invalidate()
        typingTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateTyping), userInfo: nil, repeats: false)
    }
    
    @objc func updateTyping() {
        setTypingIndicatorViewHidden(true, animated: true)
    }
    
    func insertMessage(_ message: Message) {
        messages.append(message)
        // Reload last section to update header/footer labels and insert a new one
        messagesCollectionView.performBatchUpdates({
            messagesCollectionView.insertSections([messages.count - 1])
            if messages.count >= 2 {
                messagesCollectionView.reloadSections([messages.count - 2])
            }
        }, completion: { [weak self] _ in
            if self?.isLastSectionVisible() == true {
                self?.messagesCollectionView.scrollToLastItem(animated: true)
            }
        })
    }
    
    func isLastSectionVisible() -> Bool {
        guard !messages.isEmpty else { return false }
        
        let lastIndexPath = IndexPath(item: 0, section: messages.count - 1)
        
        return messagesCollectionView.indexPathsForVisibleItems.contains(lastIndexPath)
    }
    
    func loadMessages() async throws {
        let params: GetMessagesParameters = GetMessagesParameters()
        params.markAsRead = false
        params.sorter = RequestSorter(fieldType: "", fieldName: "date_sent", sortType: "asc")
        
        cubeMessages = try await ConnectyCube().getMessages(dialogId: (currentDialog?.dialogId)!, params: (params.getRequestParameters() as! [String : Any])).items as! [ConnectycubeMessage]
        cubeMessages.forEach { msg in
            if isIncoming(msg: msg) {
                markAsRead(msg)
            }
            messages.append(msg.toMessage(currentSender, currentDialog!, occupants))
        }
        
        self.messagesCollectionView.reloadData()
        self.messagesCollectionView.scrollToLastItem(animated: false)
    }
    
    func updateMessageStatus(_ messageId: String, status: String) {
        if let indexMatched = messages.firstIndex(where: {$0.messageId == messageId}) {
            let indexPath = IndexPath(row: 0, section: indexMatched)
            messages[indexPath.section].status = status
            self.messagesCollectionView.performBatchUpdates({
                messagesCollectionView.reloadItems(at: [indexPath])
            }, completion: { [weak self] _ in
//                self?.messagesCollectionView.reloadDataAndKeepOffset()
            })
        }
    }

    func markAsRead(_ message: ConnectycubeMessage) {
        ConnectyCube().chat.sendReadStatus(msg: message)
    }

    func initChat() {
        ConnectyCube().chat.addMessageListener(listener: messageListener)
        ConnectyCube().chat.addTypingStatusListener(listener: messageTypingListener)
        ConnectyCube().chat.addMessageSentListener(listener: messageSentListener)
        ConnectyCube().chat.addMessageStatusListener(listener: messageStatusListener)
    }
    
    func deinitChat() {
        ConnectyCube().chat.removeMessageListener(listener: messageListener)
        ConnectyCube().chat.removeTypingStatusListener(listener: messageTypingListener)
        ConnectyCube().chat.removeMessageSentListener(listener: messageSentListener)
        ConnectyCube().chat.removeMessageStatusListener(listener: messageStatusListener)
    }

    func isIncoming(msg: ConnectycubeMessage) -> Bool {
        return msg.senderId?.int32Value != ConnectyCube().chat.userForLogin!.id
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        let message = messages[indexPath.section]
        return message
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    
    func configureMediaMessageImageView(_ imageView: UIImageView,
                                        for message: MessageType,
                                        at indexPath: IndexPath,
                                        in messagesCollectionView: MessagesCollectionView) {
        switch message.kind {
        case .photo(let p):
            imageView.downloaded(from: p.url!)
        default:
             break
        }
    }
    
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        let sender = occupants[Int32(message.sender.senderId)!]
        avatarView.downloaded(from: sender?.avatar ?? "", placeholder: UIImage(systemName: "person")!)
        avatarView.isHidden = isNextMessageSameSender(at: indexPath)
        avatarView.layer.borderWidth = 2
    }

    func isNextMessageSameSender(at indexPath: IndexPath) -> Bool {
        guard indexPath.section + 1 < messages.count else { return false }
        return messages[indexPath.section].sender.senderId == messages[indexPath.section + 1].sender.senderId
    }
    
    func cellTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        if indexPath.section % 3 == 0 {
            print("cellTopLabelAttributedText return NSAttributedString message.sentDate= " + message.sentDate.description)
            return NSAttributedString(
                string: MessageKitDateFormatter.shared.string(from: message.sentDate),
                attributes: [
                    NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 10),
                    NSAttributedString.Key.foregroundColor: UIColor.darkGray,
                ])
        }
        print("cellTopLabelAttributedText return nil")
        return nil
    }
    
    func cellBottomLabelAttributedText(for message: MessageType, at index: IndexPath) -> NSAttributedString? {
        let status = messages[index.section].status
        return NSAttributedString(
                string: status,
                attributes: [
                  NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 10),
                  NSAttributedString.Key.foregroundColor: UIColor.darkGray,
                ])
    }
    
    func messageTopLabelAttributedText(for message: MessageType, at _: IndexPath) -> NSAttributedString? {
        let name = message.sender.displayName
        return NSAttributedString(
            string: name,
            attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .caption1)])
    }
    
    func messageBottomLabelAttributedText(for message: MessageType, at _: IndexPath) -> NSAttributedString? {
        let dateString = formatter.string(from: message.sentDate)
        return NSAttributedString(
            string: dateString,
            attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .caption2)])
    }
    
    func textCell(for _: MessageType, at _: IndexPath, in _: MessagesCollectionView) -> UICollectionViewCell? {
        nil
    }
    
    private let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
    
    func cellTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 10
        
    }
    
    func cellBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 10
    }
    
    func messageTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 15
    }
    
    func messageBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 15
    }
    
    class ConnectycubeMessageListenerImpl: ConnectycubeMessageListener {
        weak var chatViewController: ChatViewController! = nil
        
        func onMessage(message: ConnectycubeMessage) {
            NSLog("onMessage message= " + message.body!)
            if (chatViewController.isIncoming(msg: message)) {
                let msg = message.toMessage(chatViewController.currentSender, chatViewController.currentDialog!, chatViewController.occupants)
                chatViewController.insertMessage(msg)
            }
        }
        
        func onError(message: ConnectycubeMessage, ex: KotlinThrowable) {
            NSLog("MessageListener error= " + ex.description())
        }
    }
    
    class ConnectycubeChatTypingListenerImpl: ConnectycubeChatTypingListener {
        weak var chatViewController: ChatViewController! = nil
        
        func onUserIsTyping(dialogId: String?, userId: Int32) {
            NSLog("onUserIsTyping dialogId= " + (dialogId ?? " nil"))
            self.chatViewController.setTypingIndicator()
        }
        
        func onUserStopTyping(dialogId: String?, userId: Int32) {
        }
    }
    
    class ConnectycubeMessageSentListenerImpl: ConnectycubeMessageSentListener {
        weak var chatViewController: ChatViewController! = nil
        
        func onMessageSent(message: ConnectycubeMessage) {
            chatViewController.updateMessageStatus(message.messageId!, status: "Sent")
        }
        
        func onMessageSentFailed(message: ConnectycubeMessage) {
            //remove message from list
        }
    }

    class ConnectycubeMessageStatusListenerImpl: ConnectycubeMessageStatusListener {
        weak var chatViewController: ChatViewController! = nil

        func onMessageDelivered(messageId: String, dialogId: String, userId: Int32) {
            print("onMessageDelivered")
            chatViewController.updateMessageStatus(messageId, status: "Delivered")
        }

        func onMessageRead(messageId: String, dialogId: String, userId: Int32) {
            print("onMessageRead")
            chatViewController.updateMessageStatus(messageId, status: "Read")
        }
    }
}

extension ChatViewController: InputBarAccessoryViewDelegate {
    
    @objc
    func inputBar(_: InputBarAccessoryView, didPressSendButtonWith _: String) {
        processInputBar(messageInputBar)
    }
    
    func processInputBar(_ inputBar: InputBarAccessoryView) {
        let components = inputBar.inputTextView.components
        let msgTemp = buildTempMsg(components)
        
        inputBar.inputTextView.text = String()
        inputBar.invalidatePlugins()
        attachmentData.removeAll()
        // Send button activity animation
        inputBar.sendButton.startAnimating()
        inputBar.inputTextView.placeholder = "Sending..."
        // Resign first responder for iPad split view
        inputBar.inputTextView.resignFirstResponder()
        inputBar.sendButton.stopAnimating()
        inputBar.inputTextView.placeholder = "Aa"
        insertMessage(msgTemp.toMessage(currentSender, currentDialog!, occupants))
        
        Task.init {
            do {
                let message = try await self.buildCubeMsg(tempMsg: msgTemp)
                ConnectyCube().chat.sendMessage(msg: message)
            } catch let error {
//                removeMessage() FIXME RP
                AlertBuilder.showErrorAlert(self, "Error", "create dialog: \(error.localizedDescription)")
            }
        }
    }
    
    func buildTempMsg(_ data: [Any]) -> ConnectycubeMessage {
        let msg: ConnectycubeMessage = ConnectycubeMessage()
        msg.dateSent = Int32(Date().timeIntervalSince1970).toKotlinLong()
        msg.dialogId = currentDialog?.dialogId
        msg.senderId = ConnectycubeSessionManager().activeSession!.user!.id.toKotlinInt()
        
        if(data.isEmpty && !attachmentManager.attachments.isEmpty) {
            let attachment = attachmentManager.attachments.first
            if case .image(let i) = attachment {
                let cubeAttachment: ConnectycubeAttachment = createTempAttachment(path: attachmentData[i]!.path, type: "image")
                msg.attachments?.add(cubeAttachment)
                msg.body = "Attachment"
            }
        }
        
        for component in data {
            if let str = component as? String {
                msg.body = str
            }
        }
        return msg
    }
    
    func createTempAttachment(path: String, type: String) -> ConnectycubeAttachment {
        let size = getImageSize(url: path)//FIXME RP
        
        let attachment = ConnectycubeAttachment()
        attachment.type = type
        attachment.id = String(path.hashValue)
        attachment.url = path
        attachment.height = Int32(size.height)
        attachment.width = Int32(size.width)
        return attachment
    }
    
    func createAttachment(tempAttachment: ConnectycubeAttachment) async throws -> ConnectycubeAttachment {
        let file = try await ConnectyCube().uploadFile(filePath: tempAttachment.url!, public: true, progress: nil)
        
        let attachment = ConnectycubeAttachment()
        attachment.type = tempAttachment.type
        attachment.id = String(file.id)
        attachment.url = file.getPublicUrl()
        attachment.height = tempAttachment.height
        attachment.width = tempAttachment.width
        return attachment
    }
    
    func getImageSize(url: String) -> CGSize{
        if let imageSource = CGImageSourceCreateWithURL(URL(string: url)! as CFURL, nil) {
            if let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as Dictionary? {
                let pixelWidth = imageProperties[kCGImagePropertyPixelWidth] as! Int
                let pixelHeight = imageProperties[kCGImagePropertyPixelHeight] as! Int
                return CGSize(width: pixelWidth, height: pixelHeight)
            }
        }
        return CGSize()
    }
    
    func buildCubeMsg(tempMsg: ConnectycubeMessage) async throws -> ConnectycubeMessage {
        let msg: ConnectycubeMessage = ConnectycubeMessage()
        msg.dateSent = Int32(Date().timeIntervalSince1970).toKotlinLong()
        msg.dialogId = tempMsg.dialogId
        if(currentDialog!.type == ConnectycubeDialogType.companion.PRIVATE) { msg.recipientId = currentDialog!.getRecipientId().toKotlinInt() }
        else { msg.type = ConnectycubeMessageType.groupchat }
        msg.body = tempMsg.body
        if(tempMsg.attachments!.count > 0) {
            let attachment = try await createAttachment(tempAttachment: tempMsg.attachments!.firstObject as! ConnectycubeAttachment)
            msg.attachments?.add(attachment)
        }
        return msg
    }
}

extension ChatViewController: MessageCellDelegate {
    func didTapAvatar(in _: MessageCollectionViewCell) {
        print("Avatar tapped")
    }
    
    func didTapMessage(in _: MessageCollectionViewCell) {
        print("Message tapped")
    }
    
    func didTapImage(in _: MessageCollectionViewCell) {
        print("Image tapped")
    }
    
    func didTapCellTopLabel(in _: MessageCollectionViewCell) {
        print("Top cell label tapped")
    }
    
    func didTapCellBottomLabel(in _: MessageCollectionViewCell) {
        print("Bottom cell label tapped")
    }
    
    func didTapMessageTopLabel(in _: MessageCollectionViewCell) {
        print("Top message label tapped")
    }
    
    func didTapMessageBottomLabel(in _: MessageCollectionViewCell) {
        print("Bottom label tapped")
    }
    
    func didTapPlayButton(in cell: AudioMessageCell) {
        print("Play Button tapped")
    }
}

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
        if(self.senderId == Int32(currentSender.senderId)?.toKotlinInt()) {
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

extension Int32 {
    /// returns Integer equivalent of this instance.
    /// created as a shorthand to avoid casting to Int.
    func asInt() -> Int {
        return Int(self)
    }
}

extension Int32 {
    /// converts this Integer to KotlinInt
    func toKotlinInt() -> KotlinInt {
        return KotlinInt(integerLiteral: Int(self))
    }
}

extension Int32 {
    /// converts this Integer to KotlinInt
    func toKotlinLong() -> KotlinLong {
        return KotlinLong(integerLiteral: Int(self))
    }
}

extension Array where Element == Int {
    /// Returns true if at least one element matches the given predicate.
    func any(_ array: [Int]) -> Bool {
        return self.contains{ array.contains($0)}
    }
}


struct Sender: SenderType {
    var senderId: String
    
    var displayName: String
}

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

extension UINavigationController {
  func popToViewController(ofClass: AnyClass, animated: Bool = true) {
    if let vc = viewControllers.last(where: { $0.isKind(of: ofClass) }) {
      popToViewController(vc, animated: animated)
    }
  }
}

class AttachmentItem: MediaItem {
    var url: URL?
    var image: UIImage?
    var placeholderImage: UIImage
    var size: CGSize
    
    init(connectycubeAttachment: ConnectycubeAttachment) {
        if (connectycubeAttachment.url!.hasPrefix("https")) {
            self.url = URL(string: connectycubeAttachment.url!)
        } else {
            self.url = URL.init(fileURLWithPath: connectycubeAttachment.url!)
        }
       
        if (connectycubeAttachment.width != 0 && connectycubeAttachment.height != 0) {
            size = CGSize(width: Int(connectycubeAttachment.width), height: Int(connectycubeAttachment.height))
        } else {
            self.size = CGSize(width: 240, height: 240)
        }
        self.placeholderImage = UIImage()
    }
}

extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            //1 option
            //                UIPasteboard.general.image = pickedImage
            //                self.messageInputBar.inputTextView.paste(nil)
            //2 option
            //                let imageAttachment = NSTextAttachment()
            //                imageAttachment.image = pickedImage
            //                self.messageInputBar.inputTextView.attributedText = NSAttributedString(attachment: imageAttachment)
            //3 option
            let handled = self.attachmentManager.handleInput(of: pickedImage)
            if !handled {
                print("pickedImage error")
            }
            attachmentData[pickedImage] = info[UIImagePickerController.InfoKey.imageURL] as? URL
        }
        self.dismiss(animated: true, completion: nil)
    }
}

extension ChatViewController: AttachmentManagerDelegate {
    
    // MARK: - AttachmentManagerDelegate
    
    func attachmentManager(_ manager: AttachmentManager, shouldBecomeVisible: Bool) {
        setAttachmentManager(active: shouldBecomeVisible)
    }

    func attachmentManager(_ manager: AttachmentManager, didReloadTo attachments: [AttachmentManager.Attachment]) {
        messageInputBar.sendButton.isEnabled = manager.attachments.count > 0
    }

    func attachmentManager(_ manager: AttachmentManager, didInsert attachment: AttachmentManager.Attachment, at index: Int) {
        messageInputBar.sendButton.isEnabled = manager.attachments.count > 0
    }

    func attachmentManager(_ manager: AttachmentManager, didRemove attachment: AttachmentManager.Attachment, at index: Int) {
        messageInputBar.sendButton.isEnabled = manager.attachments.count > 0
    }

    // MARK: - AttachmentManagerDelegate Helper
    
    func setAttachmentManager(active: Bool) {
        
        let topStackView = messageInputBar.topStackView
        if active && !topStackView.arrangedSubviews.contains(attachmentManager.attachmentView) {
            topStackView.insertArrangedSubview(attachmentManager.attachmentView, at: topStackView.arrangedSubviews.count)
            topStackView.layoutIfNeeded()
        } else if !active && topStackView.arrangedSubviews.contains(attachmentManager.attachmentView) {
            topStackView.removeArrangedSubview(attachmentManager.attachmentView)
            topStackView.layoutIfNeeded()
        }
    }
}
