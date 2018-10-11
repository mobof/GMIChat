//
//  ChatMessageDecorator.swift
//  VIMDemo
//
//  Created by 熊清 on 2017/8/18.
//  Copyright © 2017年 GMI. All rights reserved.
//

import Foundation
import Chatto
import ChattoAdditions

final class ChatMessageDecorator: ChatItemsDecoratorProtocol {
    struct Constants {
        static let shortSeparation: CGFloat = 3
        static let normalSeparation: CGFloat = 10
        static let timeIntervalThresholdToIncreaseSeparation: TimeInterval = 120
    }
    
    weak var handler:ChatMessageViewProtocol?
    weak var selector:MessagesSelectorProtocol?
    init(_ handler:ChatMessageViewProtocol,_ selector: MessagesSelectorProtocol) {
        self.handler = handler
        self.selector = selector
    }
    
    func decorateItems(_ chatItems: [ChatItemProtocol]) -> [DecoratedChatItem] {
        var decoratedChatItems = [DecoratedChatItem]()
        let calendar = Calendar.current
        
        for (index, chatItem) in chatItems.enumerated() {
            let prev: ChatItemProtocol? = (index > 0) ? chatItems[index - 1] : nil
            var additionalItems =  [DecoratedChatItem]()
            
            if let currentMessage = chatItem as? ChatMessageModelProtocol {
                //显示时间分区
                var addTimeSeparator = false
                if let previousMessage = prev as? MessageModelProtocol {
                    addTimeSeparator = !calendar.isDate(currentMessage.date, equalTo: previousMessage.date, toGranularity: .minute)
                } else {
                    addTimeSeparator = true
                }
                if addTimeSeparator {
                    let dateTimeStamp = DecoratedChatItem(
                        chatItem: (self.handler?.timeSeparator("\(currentMessage.uid)-time-separator", currentMessage.date)!)!,
                        decorationAttributes: nil)
                    decoratedChatItems.append(dateTimeStamp)
                }
                
                //提示类消息
                if currentMessage.isPrompt {
                    let promptStamp = DecoratedChatItem(
                        chatItem: (self.handler?.promptMessage("\(currentMessage.uid)-prompt-separator", currentMessage)!)!,
                        decorationAttributes: nil)
                    decoratedChatItems.append(promptStamp)
                }else{
                    //非提示类消息
                    let bottomMargin:CGFloat = currentMessage.showsSender ? 0 : 15//cell下方的margin
                    let showSelection:Bool = currentMessage.showsSelectionIndicator
                    let isSelected = (self.selector?.isMessageSelected(currentMessage))!
                    let isShowingSelectionIndicator = self.selector!.isActive && self.selector!.canSelectMessage(currentMessage)
                    let messageDecorationAttributes = BaseMessageDecorationAttributes(
                        canShowFailedIcon: true,
                        isShowingTail: currentMessage.showsTail,
                        isShowingAvatar: currentMessage.showsTail,
                        isShowingSelectionIndicator: isShowingSelectionIndicator && showSelection,
                        isSelected: isSelected && showSelection
                    )
                    decoratedChatItems.append(DecoratedChatItem(
                        chatItem: chatItem,
                        decorationAttributes: ChatItemDecorationAttributes.init(bottomMargin: bottomMargin, messageDecorationAttributes: messageDecorationAttributes)
                        )
                    )
                }
                
                //发送者信息
                if currentMessage.showsSender {
                    additionalItems.append(
                        DecoratedChatItem(
                            chatItem: (self.handler?.messageSenderInfo("\(currentMessage.uid)-sender-separator",currentMessage)!)!,
                            decorationAttributes: nil
                        )
                    )
                }
                decoratedChatItems.append(contentsOf: additionalItems)
            }
        }
        return decoratedChatItems
    }
    
    func separationAfterItem(_ current: ChatItemProtocol?, next: ChatItemProtocol?) -> CGFloat {
        guard let nexItem = next else { return 0 }
        guard let currentMessage = current as? MessageModelProtocol else { return Constants.normalSeparation }
        guard let nextMessage = nexItem as? MessageModelProtocol else { return Constants.normalSeparation }
        
        if self.showsStatusForMessage(currentMessage) {
            return 0
        } else if currentMessage.senderId != nextMessage.senderId {
            return Constants.normalSeparation
        } else if nextMessage.date.timeIntervalSince(currentMessage.date) > Constants.timeIntervalThresholdToIncreaseSeparation {
            return Constants.normalSeparation
        } else {
            return Constants.shortSeparation
        }
    }
    
    func showsStatusForMessage(_ message: MessageModelProtocol) -> Bool {
        return message.status == .failed || message.status == .sending
    }
}
