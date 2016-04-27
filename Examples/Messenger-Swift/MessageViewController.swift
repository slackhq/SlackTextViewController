//
//  MessageViewController.swift
//  Messenger
//
//  Created by Ignacio Romero Zurbuchen on 10/16/14.
//  Copyright (c) 2014 Slack Technologies, Inc. All rights reserved.
//

let DEBUG_CUSTOM_TYPING_INDICATOR = false

class MessageViewController: SLKTextViewController {
    
    var messages = [Message]()
    
    var users = ["Allen", "Anna", "Alicia", "Arnold", "Armando", "Antonio", "Brad", "Catalaya", "Christoph", "Emerson", "Eric", "Everyone", "Steve"]
    var channels = ["General", "Random", "iOS", "Bugs", "Sports", "Android", "UI", "SSB"]
    var emojis = ["-1", "m", "man", "machine", "block-a", "block-b", "bowtie", "boar", "boat", "book", "bookmark", "neckbeard", "metal", "fu", "feelsgood"]
    var commands = ["msg", "call", "text", "skype", "kick", "invite"]
    
    var searchResult: [AnyObject]?
    
    var pipWindow: UIWindow?
    
    var editingMessage = Message()
    
    override var tableView: UITableView {
        get {
            return super.tableView!
        }
    }
    
    
    // MARK: - Initialisation

    override class func tableViewStyleForCoder(decoder: NSCoder) -> UITableViewStyle {
        
        return .Plain
    }
    
    func commonInit() {
        
        NSNotificationCenter.defaultCenter().addObserver(self.tableView, selector: #selector(UITableView.reloadData), name: UIContentSizeCategoryDidChangeNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self,  selector: #selector(MessageViewController.textInputbarDidMove(_:)), name: SLKTextInputbarDidMoveNotification, object: nil)
        
        // Register a SLKTextView subclass, if you need any special appearance and/or behavior customisation.
        self.registerClassForTextView(MessageTextView.classForCoder())
        
        if DEBUG_CUSTOM_TYPING_INDICATOR == true {
            // Register a UIView subclass, conforming to SLKTypingIndicatorProtocol, to use a custom typing indicator view.
            self.registerClassForTypingIndicatorView(TypingIndicatorView.classForCoder())
        }
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.commonInit()
        
        // Example's configuration
        self.configureDataSource()
        self.configureActionItems()
        
        // SLKTVC's configuration
        self.bounces = true
        self.shakeToClearEnabled = true
        self.keyboardPanningEnabled = true
        self.shouldScrollToBottomAfterKeyboardShows = false
        self.inverted = true
        
        self.leftButton.setImage(UIImage(named: "icn_upload"), forState: .Normal)
        self.leftButton.tintColor = UIColor.grayColor()
        
        self.rightButton.setTitle(NSLocalizedString("Send", comment: ""), forState: .Normal)
        
        self.textInputbar.autoHideRightButton = true
        self.textInputbar.maxCharCount = 256
        self.textInputbar.counterStyle = .Split
        self.textInputbar.counterPosition = .Top
        
        self.textInputbar.editorTitle.textColor = UIColor.darkGrayColor()
        self.textInputbar.editorLeftButton.tintColor = UIColor(red: 0/255, green: 122/255, blue: 255/255, alpha: 1)
        self.textInputbar.editorRightButton.tintColor = UIColor(red: 0/255, green: 122/255, blue: 255/255, alpha: 1)
        
        if DEBUG_CUSTOM_TYPING_INDICATOR == false {
            self.typingIndicatorView!.canResignByTouch = true
        }
        
        self.tableView.separatorStyle = .None
        self.tableView.registerClass(MessageTableViewCell.classForCoder(), forCellReuseIdentifier: MessengerCellIdentifier)
        
        self.autoCompletionView.registerClass(MessageTableViewCell.classForCoder(), forCellReuseIdentifier: AutoCompletionCellIdentifier)
        self.registerPrefixesForAutoCompletion(["@",  "#", ":", "+:", "/"])
        
        self.textView.placeholder = "Message";
        
        self.textView.registerMarkdownFormattingSymbol("*", withTitle: "Bold")
        self.textView.registerMarkdownFormattingSymbol("_", withTitle: "Italics")
        self.textView.registerMarkdownFormattingSymbol("~", withTitle: "Strike")
        self.textView.registerMarkdownFormattingSymbol("`", withTitle: "Code")
        self.textView.registerMarkdownFormattingSymbol("```", withTitle: "Preformatted")
        self.textView.registerMarkdownFormattingSymbol(">", withTitle: "Quote")
    }
    
    
    // MARK: - Lifeterm

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
}

extension MessageViewController {
    
    // MARK: - Example's Configuration
    
    func configureDataSource() {
        
        var array = [Message]()
        
        for _ in 0..<100 {
            let words = Int((arc4random() % 40)+1)
            let message = Message()
            message.username = LoremIpsum.name()
            message.text = LoremIpsum.wordsWithNumber(words)
            array.append(message)
        }
        
        let reversed = array.reverse()
        
        self.messages.appendContentsOf(reversed)
    }
    
    func configureActionItems() {
        
        let arrowItem = UIBarButtonItem(image: UIImage(named: "icn_arrow_down"), style: .Plain, target: self, action: #selector(MessageViewController.hideOrShowTextInputbar(_:)))
        let editItem = UIBarButtonItem(image: UIImage(named: "icn_editing"), style: .Plain, target: self, action: #selector(MessageViewController.editRandomMessage(_:)))
        let typeItem = UIBarButtonItem(image: UIImage(named: "icn_typing"), style: .Plain, target: self, action: #selector(MessageViewController.simulateUserTyping(_:)))
        let appendItem = UIBarButtonItem(image: UIImage(named: "icn_append"), style: .Plain, target: self, action: #selector(MessageViewController.fillWithText(_:)))
        let pipItem = UIBarButtonItem(image: UIImage(named: "icn_pic"), style: .Plain, target: self, action: #selector(MessageViewController.togglePIPWindow(_:)))
        self.navigationItem.rightBarButtonItems = [arrowItem, pipItem, editItem, appendItem, typeItem]
    }
    
    // MARK: - Action Methods
    
    func hideOrShowTextInputbar(sender: AnyObject) {
        
        guard let buttonItem = sender as? UIBarButtonItem else {
            return
        }
        
        let hide = !self.textInputbarHidden
        let image = hide ? UIImage(named: "icn_arrow_up") : UIImage(named: "icn_arrow_down")
        
        self.setTextInputbarHidden(hide, animated: true)
        buttonItem.image = image
    }
    
    func fillWithText(sender: AnyObject) {
        
        if self.textView.text.characters.count == 0 {
            var sentences = Int(arc4random() % 4)
            if sentences <= 1 {
                sentences = 1
            }
            self.textView.text = LoremIpsum.sentencesWithNumber(sentences)
        }
        else {
            self.textView.slk_insertTextAtCaretRange(" " + LoremIpsum.word())
        }
    }
    
    func simulateUserTyping(sender: AnyObject) {
        
        if !self.canShowTypingIndicator() {
            return
        }
        
        if DEBUG_CUSTOM_TYPING_INDICATOR == true {
            guard let view = self.typingIndicatorProxyView as? TypingIndicatorView else {
                return
            }
            
            let scale = UIScreen.mainScreen().scale
            let imgSize = CGSizeMake(kTypingIndicatorViewAvatarHeight*scale, kTypingIndicatorViewAvatarHeight*scale)
            
            // This will cause the typing indicator to show after a delay ¯\_(ツ)_/¯
            LoremIpsum.asyncPlaceholderImageWithSize(imgSize, completion: { (image) -> Void in
                guard let cgImage = image.CGImage else {
                    return
                }
                let thumbnail = UIImage(CGImage: cgImage, scale: scale, orientation: .Up)
                view.presentIndicatorWithName(LoremIpsum.name(), image: thumbnail)
            })
        }
        else {
            self.typingIndicatorView!.insertUsername(LoremIpsum.name())
        }
    }
    
    func didLongPressCell(gesture: UIGestureRecognizer) {
        
        guard let view = gesture.view else {
            return
        }

        if gesture.state != .Began {
            return
        }
        
        if #available(iOS 8, *) {
            let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
            alertController.modalPresentationStyle = .Popover
            alertController.popoverPresentationController?.sourceView = view.superview
            alertController.popoverPresentationController?.sourceRect = view.frame
            
            alertController.addAction(UIAlertAction(title: "Edit Message", style: .Default, handler: { [unowned self] (action) -> Void in
                self.editCellMessage(gesture)
                }))
            
            alertController.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
            
            self.navigationController?.presentViewController(alertController, animated: true, completion: nil)
        }
        else {
            self.editCellMessage(gesture)
        }
    }
    
    func editCellMessage(gesture: UIGestureRecognizer) {
        
        guard let cell = gesture.view as? MessageTableViewCell else {
            return
        }
        
        self.editingMessage = self.messages[cell.indexPath.row]
        self.editText(self.editingMessage.text)
        
        self.tableView.scrollToRowAtIndexPath(cell.indexPath, atScrollPosition: .Bottom, animated: true)
    }
    
    func editRandomMessage(sender: AnyObject) {
        
        var sentences = Int(arc4random() % 10)
        
        if sentences <= 1 {
            sentences = 1
        }
        
        self.editText(LoremIpsum.sentencesWithNumber(sentences))
    }
    
    func editLastMessage(sender: AnyObject?) {
        
        if self.textView.text.characters.count > 0 {
            return
        }
        
        let lastSectionIndex = self.tableView.numberOfSections-1
        let lastRowIndex = self.tableView.numberOfRowsInSection(lastSectionIndex)-1
        
        let lastMessage = self.messages[lastRowIndex]
        
        self.editText(lastMessage.text)
        
        self.tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: lastRowIndex, inSection: lastSectionIndex), atScrollPosition: .Bottom, animated: true)
    }
    
    func togglePIPWindow(sender: AnyObject) {
        
        if self.pipWindow == nil {
            self.showPIPWindow(sender)
        }
        else {
            self.hidePIPWindow(sender)
        }
    }
    
    func showPIPWindow(sender: AnyObject) {
        
        var frame = CGRectMake(CGRectGetWidth(self.view.frame) - 60.0, 0.0, 50.0, 50.0)
        frame.origin.y = CGRectGetMinY(self.textInputbar.frame) - 60.0
        
        self.pipWindow = UIWindow(frame: frame)
        self.pipWindow?.backgroundColor = UIColor.blackColor()
        self.pipWindow?.layer.cornerRadius = 10
        self.pipWindow?.layer.masksToBounds = true
        self.pipWindow?.hidden = false
        self.pipWindow?.alpha = 0.0
        
        UIApplication.sharedApplication().keyWindow?.addSubview(self.pipWindow!)
        
        UIView.animateWithDuration(0.25) { [unowned self] () -> Void in
            self.pipWindow?.alpha = 1.0
        }
    }
    
    func hidePIPWindow(sender: AnyObject) {
        
        UIView.animateWithDuration(0.3, animations: { [unowned self] () -> Void in
            self.pipWindow?.alpha = 0.0
            }) { [unowned self] (finished) -> Void in
                self.pipWindow?.hidden = true
                self.pipWindow = nil
        }
    }
    
    func textInputbarDidMove(note: NSNotification) {
        
        guard let pipWindow = self.pipWindow else {
            return
        }
        
        guard let userInfo = note.userInfo else {
            return
        }
        
        guard let value = userInfo["origin"] as? NSValue else {
            return
        }
        
        var frame = pipWindow.frame
        frame.origin.y = value.CGPointValue().y - 60.0
        
        pipWindow.frame = frame
    }
}

extension MessageViewController {
    
    // MARK: - Overriden Methods
    
    override func ignoreTextInputbarAdjustment() -> Bool {
        return super.ignoreTextInputbarAdjustment()
    }
    
    override func forceTextInputbarAdjustmentForResponder(responder: UIResponder!) -> Bool {
        
        if #available(iOS 8.0, *) {
            guard let _ = responder as? UIAlertController else {
                // On iOS 9, returning YES helps keeping the input view visible when the keyboard if presented from another app when using multi-tasking on iPad.
                return UIDevice.currentDevice().userInterfaceIdiom == .Pad
            }
            return true
        }
        else {
            return UIDevice.currentDevice().userInterfaceIdiom == .Pad
        }
    }
    
    // Notifies the view controller that the keyboard changed status.
    override func didChangeKeyboardStatus(status: SLKKeyboardStatus) {
        // So something
    }
    
    // Notifies the view controller that the text will update.
    override func textWillUpdate() {
        super.textWillUpdate()
    }
    
    // Notifies the view controller that the text did update.
    override func textDidUpdate(animated: Bool) {
        super.textDidUpdate(animated)
    }
    
    // Notifies the view controller when the left button's action has been triggered, manually.
    override func didPressLeftButton(sender: AnyObject!) {
        super.didPressLeftButton(sender)
    }
    
    // Notifies the view controller when the right button's action has been triggered, manually or by using the keyboard return key.
    override func didPressRightButton(sender: AnyObject!) {
        
        // This little trick validates any pending auto-correction or auto-spelling just after hitting the 'Send' button
        self.textView.refreshFirstResponder()
        
        let message = Message()
        message.username = LoremIpsum.name()
        message.text = self.textView.text
        
        let indexPath = NSIndexPath(forRow: 0, inSection: 0)
        let rowAnimation: UITableViewRowAnimation = self.inverted ? .Bottom : .Top
        let scrollPosition: UITableViewScrollPosition = self.inverted ? .Bottom : .Top
        
        self.tableView.beginUpdates()
        self.messages.insert(message, atIndex: 0)
        self.tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: rowAnimation)
        self.tableView.endUpdates()
        
        self.tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: scrollPosition, animated: true)
        
        // Fixes the cell from blinking (because of the transform, when using translucent cells)
        // See https://github.com/slackhq/SlackTextViewController/issues/94#issuecomment-69929927
        self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
        
        super.didPressRightButton(sender)
    }
    
    override func didPressArrowKey(keyCommand: UIKeyCommand?) {
        
        guard let keyCommand = keyCommand else { return }
        
        if keyCommand.input == UIKeyInputUpArrow && self.textView.text.characters.count == 0 {
            self.editLastMessage(nil)
        }
        else {
            super.didPressArrowKey(keyCommand)
        }
    }
    
    override func keyForTextCaching() -> String? {
        
        return NSBundle.mainBundle().bundleIdentifier
    }
    
    // Notifies the view controller when the user has pasted a media (image, video, etc) inside of the text view.
    override func didPasteMediaContent(userInfo: [NSObject : AnyObject]) {
        
        super.didPasteMediaContent(userInfo)
        
        let mediaType = userInfo[SLKTextViewPastedItemMediaType]?.integerValue
        let contentType = userInfo[SLKTextViewPastedItemContentType]
        let data = userInfo[SLKTextViewPastedItemData]
        
        print("didPasteMediaContent : \(contentType) (type = \(mediaType) | data : \(data))")
    }
    
    // Notifies the view controller when a user did shake the device to undo the typed text
    override func willRequestUndo() {
        super.willRequestUndo()
    }
    
    // Notifies the view controller when tapped on the right "Accept" button for commiting the edited text
    override func didCommitTextEditing(sender: AnyObject) {

        self.editingMessage.text = self.textView.text
        self.tableView.reloadData()
        
        super.didCommitTextEditing(sender)
    }
    
    // Notifies the view controller when tapped on the left "Cancel" button
    override func didCancelTextEditing(sender: AnyObject) {
        super.didCancelTextEditing(sender)
    }
    
    override func canPressRightButton() -> Bool {
        return super.canPressRightButton()
    }
    
    override func canShowTypingIndicator() -> Bool {
        
        if DEBUG_CUSTOM_TYPING_INDICATOR == true {
            return true
        }
        else {
            return super.canShowTypingIndicator()
        }
    }
    
    override func shouldProcessTextForAutoCompletion(text: String) -> Bool {
        return true
    }
    
    override func didChangeAutoCompletionPrefix(prefix: String, andWord word: String) {
        
        var array: [AnyObject]?
        
        self.searchResult = nil
        
        if prefix == "@" {
            if word.characters.count > 0 {
                array = (self.users as NSArray).filteredArrayUsingPredicate(NSPredicate(format: "self BEGINSWITH[c] %@", word))
            }
            else {
                array = self.users
            }
        }
        else if prefix == "#" {
            
            if word.characters.count > 0 {
                array = (self.channels as NSArray).filteredArrayUsingPredicate(NSPredicate(format: "self BEGINSWITH[c] %@", word))
            }
            else {
                array = self.channels
            }
        }
        else if (prefix == ":" || prefix == "+:") && word.characters.count > 0 {
            array = (self.emojis as NSArray).filteredArrayUsingPredicate(NSPredicate(format: "self BEGINSWITH[c] %@", word))
        }
        else if prefix == "/" && self.foundPrefixRange.location == 0 {
            if word.characters.count > 0 {
                array = (self.commands as NSArray).filteredArrayUsingPredicate(NSPredicate(format: "self BEGINSWITH[c] %@", word))
            }
            else {
                array = self.commands
            }
        }

        var show = false
        
        if  array?.count > 0 {
            self.searchResult = (array! as NSArray).sortedArrayUsingSelector(#selector(NSString.localizedCaseInsensitiveCompare(_:)))
            show = (self.searchResult?.count > 0)
        }
        
        self.showAutoCompletionView(show)
    }
    
    override func heightForAutoCompletionView() -> CGFloat {
        
        guard let searchResult = self.searchResult else {
            return 0
        }
        
        let cellHeight = self.autoCompletionView.delegate?.tableView!(self.autoCompletionView, heightForRowAtIndexPath: NSIndexPath(forRow: 0, inSection: 0))
        guard let height = cellHeight else {
            return 0
        }
        return height * CGFloat(searchResult.count)
    }
}

extension MessageViewController {
    
    // MARK: - UITableViewDataSource Methods
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if tableView == self.tableView {
            return self.messages.count
        }
        else {
            if let searchResult = self.searchResult {
                return searchResult.count
            }
        }
        
        return 0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        if tableView == self.tableView {
            return self.messageCellForRowAtIndexPath(indexPath)
        }
        else {
            return self.autoCompletionCellForRowAtIndexPath(indexPath)
        }
    }
    
    func messageCellForRowAtIndexPath(indexPath: NSIndexPath) -> MessageTableViewCell {
        
        let cell = self.tableView.dequeueReusableCellWithIdentifier(MessengerCellIdentifier) as! MessageTableViewCell
        
        if cell.gestureRecognizers?.count == nil {
            let longPress = UILongPressGestureRecognizer(target: self, action: #selector(MessageViewController.didLongPressCell(_:)))
            cell.addGestureRecognizer(longPress)
        }

        let message = self.messages[indexPath.row]
        
        cell.titleLabel.text = message.username
        cell.bodyLabel.text = message.text
        
        cell.indexPath = indexPath
        cell.usedForMessage = true
        
        // Cells must inherit the table view's transform
        // This is very important, since the main table view may be inverted
        cell.transform = self.tableView.transform
        
        return cell
    }
    
    func autoCompletionCellForRowAtIndexPath(indexPath: NSIndexPath) -> MessageTableViewCell {
        
        let cell = self.autoCompletionView.dequeueReusableCellWithIdentifier(AutoCompletionCellIdentifier) as! MessageTableViewCell
        cell.indexPath = indexPath
        cell.selectionStyle = .Default

        guard let searchResult = self.searchResult as? [String] else {
            return cell
        }
        
        guard let prefix = self.foundPrefix else {
            return cell
        }
        
        var text = searchResult[indexPath.row]
        
        if prefix == "#" {
            text = "# " + text
        }
        else if prefix == ":" || prefix == "+:" {
            text = ":\(text):"
        }
        
        cell.titleLabel.text = text
        
        return cell
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
        if tableView == self.tableView {
            let message = self.messages[indexPath.row]
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineBreakMode = .ByWordWrapping
            paragraphStyle.alignment = .Left
            
            let pointSize = MessageTableViewCell.defaultFontSize()
            
            let attributes = [
                NSFontAttributeName : UIFont.systemFontOfSize(pointSize),
                NSParagraphStyleAttributeName : paragraphStyle
            ]
            
            var width = CGRectGetWidth(tableView.frame)-kMessageTableViewCellAvatarHeight
            width -= 25.0
            
            let titleBounds = (message.username as NSString).boundingRectWithSize(CGSize(width: width, height: CGFloat.max), options: .UsesLineFragmentOrigin, attributes: attributes, context: nil)
            let bodyBounds = (message.text as NSString).boundingRectWithSize(CGSize(width: width, height: CGFloat.max), options: .UsesLineFragmentOrigin, attributes: attributes, context: nil)
            
            if message.text.characters.count == 0 {
                return 0
            }
            
            var height = CGRectGetHeight(titleBounds)
            height += CGRectGetHeight(bodyBounds)
            height += 40
            
            if height < kMessageTableViewCellMinimumHeight {
                height = kMessageTableViewCellMinimumHeight
            }
            
            return height
        }
        else {
            return kMessageTableViewCellMinimumHeight
        }
    }
    
    // MARK: - UITableViewDelegate Methods
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if tableView == self.autoCompletionView {
            
            guard let searchResult = self.searchResult as? [String] else {
                return
            }
            
            var item = searchResult[indexPath.row]
            
            if self.foundPrefix == "@" && self.foundPrefixRange.location == 0 {
                item += ":"
            }
            else if self.foundPrefix == ":" || self.foundPrefix == "+:" {
                item += ":"
            }
            
            item += " "
            
            self.acceptAutoCompletionWithString(item, keepPrefix: true)
        }
    }
}

extension MessageViewController {
    
    // MARK: - UIScrollViewDelegate Methods
    
    // Since SLKTextViewController uses UIScrollViewDelegate to update a few things, it is important that if you override this method, to call super.
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        super.scrollViewDidScroll(scrollView)
    }
    
}

extension MessageViewController {
    
    // MARK: - UITextViewDelegate Methods
    
    override func textViewShouldBeginEditing(textView: UITextView) -> Bool {
        return true
    }
    
    override func textViewShouldEndEditing(textView: UITextView) -> Bool {
        // Since SLKTextViewController uses UIScrollViewDelegate to update a few things, it is important that if you override this method, to call super.
        return true
    }
    
    override func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        
        return super.textView(textView, shouldChangeTextInRange: range, replacementText: text)
    }
    
    override func textView(textView: SLKTextView, shouldOfferFormattingForSymbol symbol: String) -> Bool {
        
        if symbol == ">" {
            let selection = textView.selectedRange
            
            // The Quote formatting only applies new paragraphs
            if selection.location == 0 && selection.length > 0 {
                return true
            }
            
            // or older paragraphs too
            let prevString = (textView.text as NSString).substringWithRange(NSMakeRange(selection.location-1, 1))
            
            if NSCharacterSet.newlineCharacterSet().characterIsMember((prevString as NSString).characterAtIndex(0)) {
                return true
            }
            
            return false
        }
        
        return super.textView(textView, shouldOfferFormattingForSymbol: symbol)
    }
    
    override func textView(textView: SLKTextView, shouldInsertSuffixForFormattingWithSymbol symbol: String, prefixRange: NSRange) -> Bool {
        
        if symbol == ">" {
            return false
        }
        
        return super.textView(textView, shouldInsertSuffixForFormattingWithSymbol: symbol, prefixRange: prefixRange)
    }
}
