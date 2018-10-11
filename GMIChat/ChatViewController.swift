//
//  ChatViewController.swift
//  VIMDemo
//
//  Created by 熊清 on 2017/9/12.
//  Copyright © 2017年 GMI. All rights reserved.
//

import Foundation
import Chatto
import ChattoAdditions

open class ChatViewController: BaseChatViewController,ChatMessageViewProtocol,MessagesSelectorDelegate {
    private var targetID:Int64
    private var targetName:String
    private var unreadNumber:Int = 0
    private var messages:[ChatMessageModelProtocol]
    
    /**
     *member    target-会话对象的ID,只读
     */
    public var target:Int64 { return self.targetID }
    
    /**
     *member    targetor-会话对象的名称,只读
     */
    public var targetor: String { return self.targetName }
    
    /**
     *member    unread-未读消息数,只读
     */
    public var unread:Int { return self.unreadNumber }
    
    /**
     *member    setSelectorActive-是否激活编辑模式
     */
    public var selectorActive: Bool {
        get {
            return self.messageSelector.isActive
        }
        set {
            self.messageSelector.isActive = newValue
        }
    }
    
    /**
     *member    selectedMessages-选中的消息集合
     */
    public var selectedMessages:[ChatMessageModelProtocol] {
        get{
            return self.messageSelector.selectedMessages()
        }
    }
    
    /**
     *func      init-初始化方法(通过会话对象的ID和名称)
     *param     target-会话对象的ID
     *param     name-会话对象的名称
     *return    会话窗口界面
     */
    public init(_ target:Int64,_ name:String,_ unread:Int,_ msgs:[ChatMessageModelProtocol]) {
        targetID = target
        targetName = name
        unreadNumber = unread
        messages = msgs
        super.init(nibName: nil, bundle: nil)
    }
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        print("ChatViewController---deinit")
    }
    
    //设置界面数据代理
    weak private var messageSender:ChatMessageSender!
    weak private var messageSelector:ChatMessagesSelector!
    weak private var dataSource: ChatDataSource! {
        didSet {
            self.chatDataSource = dataSource
            self.messageSender = dataSource.messageSender
            self.messageSelector = dataSource.messageSelector
        }
    }
    
    //设置界面元素代理
    lazy private var messageHandler: ChatMessageHandler = {
        return ChatMessageHandler(self.messageSender,self.messageSelector)
    }()
    
    /**
     *func      sendMessage-发送消息时调用
     *param     msg-对应的消息对象
     *return    Void
     */
    public func sendMessage(_ msg:ChatMessageModelProtocol){
        self.dataSource.sendMessage(msg)
    }
    /**
     *func      updateMessage-更新消息(消息发送结束调用)
     *param     msg-对应的消息对象
     *return    Void
     */
    public func updateMessage(_ msg:ChatMessageModelProtocol,_ status:MessageStatus){
        self.dataSource.updateMessage(msg,status)
    }
    /**
     *func      receivedMessage-收到消息时调用
     *param     msg-对应的消息对象
     *return    Void
     */
    public func receivedMessage(_ msg:ChatMessageModelProtocol){
        self.dataSource.receivedMessage(msg)
    }
    /**
     *func      clearMessage-清空界面显示所有消息
     *return    Void
     */
    public func clearMessage() {
        self.dataSource.clearChatItem()
    }
    /**
     *func      clearMessage-清除界面显示某一条消息
     *return    Void
     */
    public func deletItem(msg:ChatMessageModelProtocol) {
        self.dataSource.deletItem(msg: msg)
    }
    /**
     *func      didTapOnFailIcon-点击消息发送失败按钮会触发,子类必须实现
     *param     msg-对应的消息对象
     *return    Void
     */
    open func didTapOnFailIcon(_ msg: ChatMessageModelProtocol) {
        assert(false, "Override in subclass")
    }
    /**
     *func      didTapOnAvatar-点击消息对应的头像,子类必须实现
     *param     msg-对应的消息对象
     *return    Void
     */
    open func didTapOnAvatar(_ msg: ChatMessageModelProtocol) {
        assert(false, "Override in subclass")
    }
    /**
     *func      didTapOnBubble-点击消息对应的气泡,子类必须实现
     *param     msg-对应的消息对象
     *return    Void
     */
    open func didTapOnBubble(_ msg: ChatMessageModelProtocol, _ bubbleView:UIView) {
        assert(false, "Override in subclass")
    }
    /**
     *func      didDoubleTapOnBubble-双击消息对应的气泡,子类必须实现
     *param     msg-对应的消息对象
     *return    Void
     */
    open func didDoubleTapOnBubble(_ msg: ChatMessageModelProtocol, _ bubbleView: UIView) {
        assert(false, "Override in subclass")
    }
    /**
     *func      didBeginLongPressOnBubble-开始长按消息气泡,子类必须实现
     *param     msg-对应的消息对象
     *return    Void
     */
    open func didBeginLongPressOnBubble(_ msg: ChatMessageModelProtocol, _ bubbleView:UIView) {
        assert(false, "Override in subclass")
    }
    /**
     *func      didEndLongPressOnBubble-结束长按消息气泡,子类必须实现
     *param     msg-对应的消息对象
     *return    Void
     */
    open func didEndLongPressOnBubble(_ msg: ChatMessageModelProtocol, _ bubbleView:UIView) {
        assert(false, "Override in subclass")
    }
    /**
     *func      messagesSelector-编辑模式选中
     *return    Bool
     */
    open func messagesSelector(_ message: ChatMessageModelProtocol) {
        self.enqueueModelUpdate(updateType: .normal)
    }
    
    /**
     *func      messagesSelector-编辑模式取消选中
     *return    Bool
     */
    open func messagesDeselector(_ message: ChatMessageModelProtocol) {
        self.enqueueModelUpdate(updateType: .normal)
    }
    /**
     *func      sendMessage-开始发送消息,子类必须实现,需要子类调用实际发送消息接口
     *param     msg-对应的消息对象
     *return    Void
     */
    open func handlerSendMessage(_ msg: ChatMessageModelProtocol) {
        assert(false, "Override in subclass")
    }
    /**
     *func      loadHistoryMessage-加载历史消息,子类必须实现
     *param     frontMessageID-从那条消息开始拉取
     *param     number-每次拉取多少条
     *param     callback-获取到历史消息回调
     *return    Void
     */
    open func loadHistoryMessage(_ frontMessageID:Int64,_ number:Int, _ callback:@escaping([ChatMessageModelProtocol]) -> ()){
        assert(false, "Override in subclass")
    }
    /**
     *func      messageSenderInfo-加载消息发送者信息,子类必须实现
     *param     uid-ui对应的id
     *param     message-消息对象
     *return    必须是ChatItemProtocol
     */
    open func messageSenderInfo(_ uid: String, _ message: ChatMessageModelProtocol) -> ChatItemProtocol? {
        assert(false, "Override in subclass")
        return nil
    }
    /**
     *func      timeSeparator-加载消息时间组UI,子类必须实现
     *param     uid-ui对应的id
     *param     date-时间组UI对应的时间
     *return    必须是ChatItemProtocol
     */
    open func timeSeparator(_ uid: String, _ date: Date) -> ChatItemProtocol? {
        assert(false, "Override in subclass")
        return nil
    }
    /**
     *func      promptMessage-提示类消息显示
     *param     uid-ui对应的id
     *param     date-时间组UI对应的时间
     *return    必须是ChatItemProtocol
     */
    open func promptMessage(_ uid: String, _ message: ChatMessageModelProtocol) -> ChatItemProtocol? {
        assert(false, "Override in subclass")
        return nil
    }
    /**
     *func      createChatItemBuilders-创建会话界面显示元素,包括时间、消息、发送者信息等,子类必须实现
     *return    必须是[ChatItemType: [ChatItemPresenterBuilderProtocol]]
     */
    open func createChatItemBuilders(_ handler: ChatMessageHandler) -> Dictionary<ChatItemType, Array<Any>> {
        assert(false, "Override in subclass")
        return [ChatItemType: [ChatItemPresenterBuilderProtocol]]()
    }
    /**
     *func      createChatInputBar-创建输入框UI
     *return    自定义的输入框
     */
    open func createChatInputBar() -> UIView {
        assert(false, "Override in subclass")
        return UIView.init()
    }
    /**
     *func      createChatInputItems-创建会话界面输入元素,包括文本输入按钮、图片输入按钮以及其他自定义输入按钮,子类必须实现
     *return    必须是[ChatInputItemProtocol]
     */
    open func createChatInputItems() -> Array<Any> {
        assert(false, "Override in subclass")
        return [ChatInputItemProtocol]()
    }
    //创建消息工厂
    final override public func createPresenterBuilders() -> [ChatItemType: [ChatItemPresenterBuilderProtocol]] {
        return self.createChatItemBuilders(self.messageHandler) as! [ChatItemType : [ChatItemPresenterBuilderProtocol]]
    }
    //创建inputBar
    var chatInputPresenter: BasicChatInputBarPresenter!
    final override public func createChatInputView() -> UIView {
        let inputBar = self.createChatInputBar()
        if inputBar is ChatInputBar {
            var appearance = ChatInputBarAppearance()
            appearance.sendButtonAppearance.title = NSLocalizedString("发送", comment: "")
            appearance.textInputAppearance.placeholderText = NSLocalizedString("请输入消息...", comment: "")
            appearance.textInputAppearance.font = UIFont.systemFont(ofSize: 14)
            appearance.textInputAppearance.placeholderFont = UIFont.systemFont(ofSize: 14)
            self.chatInputPresenter = BasicChatInputBarPresenter(chatInputBar: inputBar as! ChatInputBar, chatInputItems: createChatInputItems() as! [ChatInputItemProtocol], chatInputBarAppearance: appearance)
        }
        return inputBar
    }
    
    override open func loadView() {
        super.loadView()
        
        self.title = targetName
        //创建消息cell池
        if messages.count > 0 {
            self.dataSource = ChatDataSource(messages, messages.count, self)
        }else{
            self.dataSource = ChatDataSource(10,self)
        }
        //创建编辑模式操作对象
        self.messageSelector.delegate = self
        self.chatItemsDecorator = ChatMessageDecorator(self,self.messageSelector)
        
        self.loadHistoryMessage()
    }
    
    internal func loadHistoryMessage() {
        //开始拉取的消息ID
        var msgID:Int64 = 0
        let chatItems = self.dataSource.chatItems
        if chatItems.count > 0 {
            let message = chatItems.first  as! ChatMessageModelProtocol
            msgID = message.messageID
        }
        //拉取条数
        var number: Int = Int(unreadNumber - dataSource.chatItems.count)
        number = number > 0 && number < 50 ? number : 50
        
        weak var weakSelf = self
        self.loadHistoryMessage(msgID,number) { (msgs) in
            if (weakSelf?.dataSource.chatItems.count)! >= (weakSelf?.unreadNumber)! {
                weakSelf?.unreadNumber = 0
            }
            DispatchQueue.main.async {
                weakSelf?.dataSource.loadPreviousMessages(msgs)
            }
        }
    }
}
