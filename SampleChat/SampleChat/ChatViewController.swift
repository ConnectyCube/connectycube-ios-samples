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
import IQKeyboardManagerSwift

class ChatViewController: MessagesViewController, MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {
    
    static func navigateTo(_ controller: UIViewController, _ dialog: ConnectycubeDialog) {
        let vc = ChatViewController(dialog)
        vc.navigationItem.title = dialog.name
        controller.navigationController?.pushViewController(vc, animated: true)
    }
    
    var currentDialog: ConnectycubeDialog?
    var isPrivateChat: Bool = false
    let currentUser: ConnectycubeUser = ConnectycubeSessionManager().activeSession!.user!
    var currentSender: SenderType = Sender(senderId: String(ConnectycubeSessionManager().activeSession!.user!.id), displayName: (ConnectycubeSessionManager().activeSession!.user!.login)!)
    
    open lazy var attachmentManager: AttachmentManager = { [unowned self] in
        let manager = AttachmentManager()
        manager.delegate = self
        manager.showAddAttachmentCell = false
        return manager
    }()
    
    var attachmentImageData = [UIImage: URL]()
    
    var typingTimer = Timer()

    var messages = [Message]()
    var cubeMessages = [ConnectycubeMessage]()
    var occupants = [Int32: ConnectycubeUser]()

    var messageListener = ConnectycubeMessageListenerImpl()
    var messageTypingListener = ConnectycubeChatTypingListenerImpl()
    var messageSentListener = ConnectycubeMessageSentListenerImpl()
    var messageStatusListener = ConnectycubeMessageStatusListenerImpl()

    init(_ dialog: ConnectycubeDialog) {
        super.init(nibName: nil, bundle: nil)
        self.currentDialog = dialog
        isPrivateChat = currentDialog!.type == ConnectycubeDialogType.companion.PRIVATE
        messageListener.chatViewController = self
        messageTypingListener.chatViewController = self
        messageSentListener.chatViewController = self
        messageStatusListener.chatViewController = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    deinit {
        deinitChat()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initBackBtn()
        initTitleChatBtn()
        initResources()
        configureMessageView()
        configureAvatarView()
        configureMessageCollectionView()
        configureMessageInputBar()
        
        initChat()
    }
    
    @objc func backToDialogs() {
        self.navigationController?.popToViewController(ofClass: DialogViewController.self)
    }
    
    @objc func navigateToChatInfo() {
        if currentDialog!.type == ConnectycubeDialogType.companion.PRIVATE {
            UserProfileViewController.navigateTo(self, Array(occupants.values).first{$0.id != Int(currentSender.senderId) ?? 0}!)
        } else {
            let vc = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "ChatDetailsViewController") as? ChatDetailsViewController
            vc?.title = "Chat details"
            vc?.currentDialog = currentDialog!
            vc?.occupants = Array(occupants.values)
            self.navigationController?.pushViewController(vc!, animated: true)
        }
    }
    
    func initBackBtn() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "chevron.backward"), style: .plain, target: self, action: #selector(backToDialogs))
    }
    
    func initTitleChatBtn() {        
        let containerView = UIControl(frame: CGRect.init(x: 0, y: 0, width: 30, height: 30))
        containerView.addTarget(self, action: #selector(navigateToChatInfo), for: .touchUpInside)
        let imageView = UIImageView(frame: CGRect.init(x: 0, y: 0, width: 30, height: 30))
        imageView.layer.masksToBounds = false
        imageView.layer.cornerRadius = imageView.frame.size.width / 2
        imageView.clipsToBounds = true
        imageView.downloaded(from: currentDialog!.photo ?? "", placeholder: UIImage(named: "avatar_placeholder_group")!)
        containerView.addSubview(imageView)
        let buttonItem = UIBarButtonItem(customView: containerView)
        buttonItem.width = 30
        navigationItem.rightBarButtonItem = buttonItem
    }
    
    func configureMessageView() {
        let incomingAlignment = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 0)
        let outgoingAlignment = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 5)
        if(isPrivateChat) {
            messagesCollectionView.messagesCollectionViewFlowLayout.setMessageIncomingMessageBottomLabelAlignment(LabelAlignment(textAlignment: .left, textInsets: incomingAlignment))
            messagesCollectionView.messagesCollectionViewFlowLayout.setMessageIncomingAvatarSize(.zero)
        }
        messagesCollectionView.messagesCollectionViewFlowLayout.setMessageOutgoingMessageBottomLabelAlignment(LabelAlignment(textAlignment: .right, textInsets: outgoingAlignment))
        messagesCollectionView.messagesCollectionViewFlowLayout.setMessageOutgoingAvatarSize(.zero)
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
        let ids = Set(currentDialog!.occupantsIds!.asXPIntArray())
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
  
        IQKeyboardManager.shared.disabledToolbarClasses.append(ChatViewController.self)
    }
    
    @objc func attachmentPressed() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .savedPhotosAlbum
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
        updateCollectionContentInset()
        self.messagesCollectionView.scrollToLastItem()
    }
    
    //show messages from the bottom
    func updateCollectionContentInset() {
        let contentSize = messagesCollectionView.collectionViewLayout.collectionViewContentSize
        var contentInsetTop = messagesCollectionView.bounds.size.height
        let offset: CGFloat = messageInputBar.contentView.bounds.height / 2

            contentInsetTop -= contentSize.height
            if contentInsetTop <= 0 {
                contentInsetTop = 0
        }
        messagesCollectionView.contentInset = UIEdgeInsets(top: contentInsetTop,left: 0,bottom: messageInputBar.contentView.bounds.height + offset, right: 0)
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
        if(isPrivateChat) {
            avatarView.isHidden = true
        } else {
            avatarView.downloaded(from: sender?.avatar ?? "", placeholder: UIImage(systemName: "person")!)
            avatarView.isHidden = isNextMessageSameSender(at: indexPath)
            avatarView.layer.borderWidth = 2
        }
    }

    func isNextMessageSameSender(at indexPath: IndexPath) -> Bool {
        guard indexPath.section + 1 < messages.count else { return false }
        return messages[indexPath.section].sender.senderId == messages[indexPath.section + 1].sender.senderId
    }
    
    func dateCellText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        if indexPath.section % 3 == 0 {
            return NSAttributedString(
                string: MessageKitDateFormatter.shared.string(from: message.sentDate),
                attributes: [
                    NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 10),
                    NSAttributedString.Key.foregroundColor: UIColor.darkGray,
                ])
        }
        return nil
    }
    
    func cellTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        return dateCellText(for: message, at: indexPath)
    }
    
    func messageTopLabelAttributedText(for message: MessageType, at _: IndexPath) -> NSAttributedString? {
        if(isPrivateChat || isFromCurrentSender(message: message)) {
            return nil
        } else {
            let name = message.sender.displayName
            return NSAttributedString(
                string: name,
                attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .caption1)])
        }
    }
    
    func messageBottomLabelAttributedText(for message: MessageType, at index: IndexPath) -> NSAttributedString? {
        let status = messages[index.section].status
        return NSAttributedString(
                string: status,
                attributes: [
                  NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 10),
                  NSAttributedString.Key.foregroundColor: UIColor.darkGray,
                ])
    }
    
    func cellTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        if(dateCellText(for: message, at: indexPath) == nil) {
            return 0
        } else {
            return 15
        }
    }
    
    func cellBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 0
    }
    
    func messageTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        if(isFromCurrentSender(message: message) || isPrivateChat) {
            return 0
        } else {
            return 15
        }
    }
    
    func messageBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        if(isFromCurrentSender(message: message) && !messages[indexPath.section].status.isEmpty) {
            return 15
        } else {
            return 0
        }
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
            chatViewController.updateMessageStatus(messageId, status: "Delivered")
        }

        func onMessageRead(messageId: String, dialogId: String, userId: Int32) {
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
        attachmentImageData.removeAll()
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
                AlertBuilder.showErrorAlert(self, "Error", "create dialog: \(error.localizedDescription)")
            }
        }
    }
    
    func buildTempMsg(_ data: [Any]) -> ConnectycubeMessage {
        let msg: ConnectycubeMessage = ConnectycubeMessage()
        msg.dateSent = Int32(Date().timeIntervalSince1970).asXPLong()
        msg.dialogId = currentDialog?.dialogId
        msg.senderId = ConnectycubeSessionManager().activeSession!.user!.id.asXPInt()
        
        if(data.isEmpty && !attachmentManager.attachments.isEmpty) {
            let attachment = attachmentManager.attachments.first
            if case .image(let i) = attachment {
                let (url, _) = compressImage(image: i)
                let connectycubeAttachment = createTempAttachment(path: url?.path ?? attachmentImageData[i]!.path, type: "image")
                msg.attachments?.add(connectycubeAttachment)
                
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
        let attachment = ConnectycubeAttachment()
        attachment.type = type
        attachment.id = String(path.hashValue)
        attachment.url = path
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
    
    func buildCubeMsg(tempMsg: ConnectycubeMessage) async throws -> ConnectycubeMessage {
        let msg: ConnectycubeMessage = ConnectycubeMessage()
        msg.dateSent = Int32(Date().timeIntervalSince1970).asXPLong()
        msg.dialogId = tempMsg.dialogId
        if(currentDialog!.type == ConnectycubeDialogType.companion.PRIVATE) { msg.recipientId = currentDialog!.getRecipientId().asXPInt() }
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

extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            let handled = self.attachmentManager.handleInput(of: pickedImage)
            if !handled {
                print("pickedImage error")
            }
            attachmentImageData[pickedImage] = info[UIImagePickerController.InfoKey.imageURL] as? URL
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
