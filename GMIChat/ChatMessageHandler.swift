//
//  ChatMessageHandler.swift
//  VIMDemo
//
//  Created by 熊清 on 2017/8/18.
//  Copyright © 2017年 GMI. All rights reserved.
//

import Foundation
import Chatto
import ChattoAdditions

/**
 *func      ChatMessageViewModelProtocol-用于消息UI更新
 *return    Void
 */
public protocol ChatMessageViewModelProtocol {
    var messageModel: ChatMessageModelProtocol { get }
}

/**
 *func      ChatMessageModelProtocol-用于更新消息状态
 *return    Void
 */
public protocol ChatMessageModelProtocol:DecoratedMessageModelProtocol {
    var status: MessageStatus { get set }
    var message: AnyObject { get }
    var messageID: Int64 { get }
    var isPrompt: Bool { get }
    var showsSender: Bool { get }
    var showsTail: Bool { get }
    var showsSelectionIndicator: Bool { get }
}

protocol ChatMessageViewProtocol: class {
    func didTapOnAvatar(_ msg: ChatMessageModelProtocol)
    func didTapOnBubble(_ msg: ChatMessageModelProtocol, _ bubbleView:UIView)
    func didDoubleTapOnBubble(_ msg: ChatMessageModelProtocol, _ bubbleView:UIView)
    func didBeginLongPressOnBubble(_ msg: ChatMessageModelProtocol, _ bubbleView:UIView)
    func didEndLongPressOnBubble(_ msg: ChatMessageModelProtocol, _ bubbleView:UIView)
    
    func messageSenderInfo(_ uid: String, _ message: ChatMessageModelProtocol) -> ChatItemProtocol?
    func timeSeparator(_ uid:String, _ date:Date) -> ChatItemProtocol?
    func promptMessage(_ uid: String, _ message: ChatMessageModelProtocol) -> ChatItemProtocol?
    
    func handlerSendMessage(_ msg: ChatMessageModelProtocol)
    func loadHistoryMessage()
}

public class ChatMessageHandler: BaseMessageInteractionHandlerProtocol {
    private let sender:ChatMessageSender
    private let messagesSelector: MessagesSelectorProtocol
    init (_ sender:ChatMessageSender,_ selector:MessagesSelectorProtocol) {
        self.sender = sender
        self.messagesSelector = selector
    }
    
    public func userDidTapOnFailIcon(viewModel: ChatMessageModelProtocol, failIconView: UIView) {
        guard !self.messagesSelector.isActive else {//编辑模式不触发
            return
        }
        self.sender.sendMessage(viewModel)
    }
    
    public func userDidTapOnAvatar(viewModel: ChatMessageModelProtocol) {
        guard !self.messagesSelector.isActive else {//编辑模式不触发
            return
        }
        self.sender.handler?.didTapOnAvatar(viewModel)
    }
    
    public func userDidTapOnBubble(viewModel: ChatMessageModelProtocol, bubbleView:UIView) {
        guard !self.messagesSelector.isActive else {//编辑模式不触发
            return
        }
        self.sender.handler?.didTapOnBubble(viewModel,bubbleView)
    }
    
    public func userDidBeginLongPressOnBubble(viewModel: ChatMessageModelProtocol, bubbleView:UIView) {
        guard !self.messagesSelector.isActive else {//编辑模式不触发
            return
        }
        self.sender.handler?.didBeginLongPressOnBubble(viewModel,bubbleView)
    }
    
    public func userDidEndLongPressOnBubble(viewModel: ChatMessageModelProtocol, bubbleView:UIView) {
        guard !self.messagesSelector.isActive else {//编辑模式不触发
            return
        }
        self.sender.handler?.didEndLongPressOnBubble(viewModel,bubbleView)
    }
    
    public func userDidDoubleTapOnBubble(viewModel: ChatMessageModelProtocol, bubbleView:UIView) {
        guard !self.messagesSelector.isActive else {//编辑模式不触发
            return
        }
        self.sender.handler?.didDoubleTapOnBubble(viewModel,bubbleView)
    }
    
    public func userDidSelectMessage(viewModel: ChatMessageModelProtocol, bubbleView:UIView) {
        self.messagesSelector.selectMessage(viewModel)
    }
    
    public func userDidDeselectMessage(viewModel: ChatMessageModelProtocol, bubbleView:UIView) {
        self.messagesSelector.deselectMessage(viewModel)
    }
}

//MARK:--Sender
class ChatMessageSender {
    public var onMessageChanged: ((_ message: ChatMessageModelProtocol) -> Void)?
    
    weak var handler:ChatMessageViewProtocol?
    init(_ handler:ChatMessageViewProtocol) {
        self.handler = handler
    }
    
    func sendMessage(_ message:ChatMessageModelProtocol) {
        switch message.status {
        case .failed:
            self.updateMessage(message, MessageStatus.sending)
            self.handler?.handlerSendMessage(message)
        case .sending:
            self.handler?.handlerSendMessage(message)
        default:
            break
        }
    }
    
    func updateMessage(_ message: ChatMessageModelProtocol, _ status: MessageStatus) {
        if message.status != status {
            message.status = status
            self.notifyMessageChanged(message)
        }
    }
    
    private func notifyMessageChanged(_ message: ChatMessageModelProtocol) {
        self.onMessageChanged?(message)
    }
}

//MARK:--Selector
class ChatMessagesSelector: MessagesSelectorProtocol {
    
    weak var delegate: MessagesSelectorDelegate?
    
    public var isActive = false {
        didSet {
            guard oldValue != self.isActive else { return }
            if self.isActive {
                self.selectedMessagesDictionary.removeAll()
            }
        }
    }
    
    public func canSelectMessage(_ message: ChatMessageModelProtocol) -> Bool {
        return true
    }
    
    public func isMessageSelected(_ message: ChatMessageModelProtocol) -> Bool {
        return self.selectedMessagesDictionary[message.uid] != nil
    }
    
    public func selectMessage(_ message: ChatMessageModelProtocol) {
        self.selectedMessagesDictionary[message.uid] = message
        self.delegate?.messagesSelector(message)
    }
    
    public func deselectMessage(_ message: ChatMessageModelProtocol) {
        self.selectedMessagesDictionary[message.uid] = nil
        self.delegate?.messagesDeselector(message)
    }
    
    public func selectedMessages() -> [ChatMessageModelProtocol] {
        let msgs:[ChatMessageModelProtocol] = Array(self.selectedMessagesDictionary.values)
        return msgs.sorted(by: { (msg1:ChatMessageModelProtocol,msg2:ChatMessageModelProtocol) -> Bool in
            return msg1.messageID < msg2.messageID
        })
    }
    
    // MARK: - Private
    private var selectedMessagesDictionary = [String: ChatMessageModelProtocol]()
}

protocol MessagesSelectorDelegate: class {
    func messagesSelector(_ message: ChatMessageModelProtocol)
    func messagesDeselector(_ message: ChatMessageModelProtocol)
}

protocol MessagesSelectorProtocol: class {
    weak var delegate: MessagesSelectorDelegate? { get set }
    var isActive: Bool { get set }
    func canSelectMessage(_ message: ChatMessageModelProtocol) -> Bool
    func isMessageSelected(_ message: ChatMessageModelProtocol) -> Bool
    func selectMessage(_ message: ChatMessageModelProtocol)
    func deselectMessage(_ message: ChatMessageModelProtocol)
    func selectedMessages() -> [ChatMessageModelProtocol]
}
