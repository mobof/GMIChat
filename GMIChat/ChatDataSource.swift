//
//  ChatMessagesDataSource.swift
//  VIMDemo
//
//  Created by 熊清 on 2017/7/26.
//  Copyright © 2017年 GMI. All rights reserved.
//

import Foundation
import Chatto
import ChattoAdditions

enum InsertPosition {
    case top
    case bottom
}
class SlidingDataSource<Element> {
    private var pageSize: Int
    var windowOffset: Int
    private var windowCount: Int
    private var items = [Element]()
    var itemsInWindow: [Element] {
        return Array(items[0..<self.windowCount])
    }

    init(count: Int, pageSize: Int) {
        self.windowOffset = count
        self.windowCount = 0
        self.pageSize = pageSize
    }

    convenience init(items: [Element], pageSize: Int) {
        self.init(count: 0, pageSize: pageSize)
        for item in items {
            self.insertItem(item, position: .bottom)
        }
    }

    func insertItems(_ items:[Element]){
        for item in items {
            insertItem(item, position: .top)
        }
    }

    func insertItem(_ item: Element, position: InsertPosition) {
        self.windowCount += 1
        if position == .top {
            self.items.insert(item, at: 0)
        } else {
            self.items.append(item)
        }
    }

    func clearItem() -> Void {
        items.removeAll()
    }

    func deletItem(msg:Element) -> Void {
        windowCount -= 1
        let msgs = items as NSArray
        let index = msgs.index(of: msg)
        items.remove(at: index)
    }

    func hasPrevious() -> Bool {
        return self.windowOffset > 0
    }

    @discardableResult
    func adjustWindow(focusPosition: Double, maxWindowSize: Int) -> Bool {
        assert(0 <= focusPosition && focusPosition <= 1, "")
        guard 0 <= focusPosition && focusPosition <= 1 else {
            assert(false, "focus should be in the [0, 1] interval")
            return false
        }
        let sizeDiff = self.windowCount - maxWindowSize
        guard sizeDiff > 0 else { return false }
        self.windowOffset +=  Int(focusPosition * Double(sizeDiff))
        self.windowCount = maxWindowSize
        return true
    }
}

class ChatDataSource: ChatDataSourceProtocol {
    weak var delegate: ChatDataSourceDelegateProtocol?
    private var slidingWindow: SlidingDataSource<ChatItemProtocol>!
    private var messages: [MessageModelProtocol]!

    weak var handler:ChatMessageViewProtocol?
    init(_ pageSize:Int,_ handler:ChatMessageViewProtocol) {
        self.handler = handler
        self.slidingWindow = SlidingDataSource(count: 0, pageSize: pageSize)
    }

    init(_ msgs:Array<ChatMessageModelProtocol>,_ pageSize:Int, _ handler:ChatMessageViewProtocol) {
        self.handler = handler
        self.slidingWindow = SlidingDataSource(items: msgs, pageSize: pageSize)
    }

    lazy var messageSender: ChatMessageSender = {
        let sender = ChatMessageSender(self.handler!)
        sender.onMessageChanged = { [weak self] (message) in
            guard let sSelf = self else { return }
            sSelf.delegate?.chatDataSourceDidUpdate(sSelf)
        }
        return sender
    }()
    
    lazy var messageSelector: ChatMessagesSelector = {
        let selector = ChatMessagesSelector()
        return selector
    }()

//下面为协议必须实现的
    var chatItems: [ChatItemProtocol] {
        return self.slidingWindow.itemsInWindow
    }

    var hasMorePrevious: Bool {
        return self.slidingWindow.hasPrevious()
    }
    
    final func loadPrevious() {
        self.slidingWindow.insertItems(messages)
        
        self.slidingWindow.adjustWindow(focusPosition: 0, maxWindowSize: self.slidingWindow.itemsInWindow.count)
        self.delegate?.chatDataSourceDidUpdate(self, updateType: .pagination)
        self.handler?.loadHistoryMessage()
    }

    func adjustNumberOfMessages(preferredMaxCount: Int?, focusPosition: Double, completion: (Bool) -> Void) {
        let didAdjust = self.slidingWindow.adjustWindow(focusPosition: focusPosition, maxWindowSize: preferredMaxCount ?? self.slidingWindow.itemsInWindow.count)
        completion(didAdjust)
    }

    var hasMoreNext: Bool{
        return false
    }
    func loadNext() {}

    func sendMessage(_ message:MessageModelProtocol) {
        self.slidingWindow.insertItem(message, position: .bottom)
        self.delegate?.chatDataSourceDidUpdate(self)

        self.messageSender.sendMessage(message as! ChatMessageModelProtocol)
    }

    func updateMessage(_ message:MessageModelProtocol,_ status: MessageStatus) {
        self.messageSender.updateMessage(message as! ChatMessageModelProtocol,status)
    }

    func receivedMessage(_ message:MessageModelProtocol) {
        self.slidingWindow.insertItem(message, position: .bottom)
        self.delegate?.chatDataSourceDidUpdate(self)
    }

    func loadPreviousMessages(_ messages:[MessageModelProtocol]) {
        self.slidingWindow.windowOffset = messages.count
        self.messages = messages
    }

    func clearChatItem() -> Void {
        self.slidingWindow.clearItem()
    }

    func deletItem(msg:ChatMessageModelProtocol) -> Void {
        self.slidingWindow.deletItem(msg: msg)
    }
}
