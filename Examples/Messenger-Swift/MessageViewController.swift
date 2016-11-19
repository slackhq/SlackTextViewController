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
    
    var users: Array = ["Allen", "Anna", "Alicia", "Arnold", "Armando", "Antonio", "Brad", "Catalaya", "Christoph", "Emerson", "Eric", "Everyone", "Steve"]
    var channels: Array = ["General", "Random", "iOS", "Bugs", "Sports", "Android", "UI", "SSB"]
    var emojis: Array = ["-1", "m", "man", "machine", "block-a", "block-b", "bowtie", "boar", "boat", "book", "bookmark", "neckbeard", "metal", "fu", "feelsgood"]
    var commands: Array = ["msg", "call", "text", "skype", "kick", "invite"]
    
    var searchResult: [String]?
    
    var pipWindow: UIWindow?
    
    var editingMessage = Message()
    
    override var tableView: UITableView {
        get {
            return super.tableView!
        }
    }
    
    
    // MARK: - Initialisation

    override class func tableViewStyle(for decoder: NSCoder) -> UITableViewStyle {
        
        return .plain
    }
    
    func commonInit() {
        
        NotificationCenter.default.addObserver(self.tableView, selector: #selector(UITableView.reloadData), name: NSNotification.Name.UIContentSizeCategoryDidChange, object: nil)
        NotificationCenter.default.addObserver(self,  selector: #selector(MessageViewController.textInputbarDidMove(_:)), name: NSNotification.Name.SLKTextInputbarDidMove, object: nil)        
    }
    
    override func viewDidLoad() {

        // Register a SLKTextView subclass, if you need any special appearance and/or behavior customisation.
        self.registerClass(forTextView: MessageTextView.classForCoder())
        
        if DEBUG_CUSTOM_TYPING_INDICATOR == true {
            // Register a UIView subclass, conforming to SLKTypingIndicatorProtocol, to use a custom typing indicator view.
            self.registerClass(forTypingIndicatorView: TypingIndicatorView.classForCoder())
        }

        super.viewDidLoad()
        
        self.commonInit()
        
        // Example's configuration
        self.configureDataSource()
        self.configureActionItems()
        
        // SLKTVC's configuration
        self.bounces = true
        self.shakeToClearEnabled = true
        self.isKeyboardPanningEnabled = true
        self.shouldScrollToBottomAfterKeyboardShows = false
        self.isInverted = true
        
        self.leftButton.setImage(UIImage(named: "icn_upload"), for: UIControlState())
        self.leftButton.tintColor = UIColor.gray
        
        self.rightButton.setTitle(NSLocalizedString("Send", comment: ""), for: UIControlState())
        
        self.textInputbar.autoHideRightButton = true
        self.textInputbar.maxCharCount = 256
        self.textInputbar.counterStyle = .split
        self.textInputbar.counterPosition = .top
        
        self.textInputbar.editorTitle.textColor = UIColor.darkGray
        self.textInputbar.editorLeftButton.tintColor = UIColor(red: 0/255, green: 122/255, blue: 255/255, alpha: 1)
        self.textInputbar.editorRightButton.tintColor = UIColor(red: 0/255, green: 122/255, blue: 255/255, alpha: 1)
        
        if DEBUG_CUSTOM_TYPING_INDICATOR == false {
            self.typingIndicatorView!.canResignByTouch = true
        }
        
        self.tableView.separatorStyle = .none
        self.tableView.register(MessageTableViewCell.classForCoder(), forCellReuseIdentifier: MessengerCellIdentifier)
        
        self.autoCompletionView.register(MessageTableViewCell.classForCoder(), forCellReuseIdentifier: AutoCompletionCellIdentifier)
        self.registerPrefixes(forAutoCompletion: ["@",  "#", ":", "+:", "/"])
        
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
        NotificationCenter.default.removeObserver(self)
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
            message.text = LoremIpsum.words(withNumber: words)
            array.append(message)
        }
        
        let reversed = array.reversed()
        
        self.messages.append(contentsOf: reversed)
    }
    
    func configureActionItems() {
        
        let arrowItem = UIBarButtonItem(image: UIImage(named: "icn_arrow_down"), style: .plain, target: self, action: #selector(MessageViewController.hideOrShowTextInputbar(_:)))
        let editItem = UIBarButtonItem(image: UIImage(named: "icn_editing"), style: .plain, target: self, action: #selector(MessageViewController.editRandomMessage(_:)))
        let typeItem = UIBarButtonItem(image: UIImage(named: "icn_typing"), style: .plain, target: self, action: #selector(MessageViewController.simulateUserTyping(_:)))
        let appendItem = UIBarButtonItem(image: UIImage(named: "icn_append"), style: .plain, target: self, action: #selector(MessageViewController.fillWithText(_:)))
        let pipItem = UIBarButtonItem(image: UIImage(named: "icn_pic"), style: .plain, target: self, action: #selector(MessageViewController.togglePIPWindow(_:)))
        self.navigationItem.rightBarButtonItems = [arrowItem, pipItem, editItem, appendItem, typeItem]
    }
    
    // MARK: - Action Methods
    
    func hideOrShowTextInputbar(_ sender: AnyObject) {
        
        guard let buttonItem = sender as? UIBarButtonItem else {
            return
        }
        
        let hide = !self.isTextInputbarHidden
        let image = hide ? UIImage(named: "icn_arrow_up") : UIImage(named: "icn_arrow_down")
        
        self.setTextInputbarHidden(hide, animated: true)
        buttonItem.image = image
    }
    
    func fillWithText(_ sender: AnyObject) {
        
        if self.textView.text.characters.count == 0 {
            var sentences = Int(arc4random() % 4)
            if sentences <= 1 {
                sentences = 1
            }
            self.textView.text = LoremIpsum.sentences(withNumber: sentences)
        }
        else {
            self.textView.slk_insertText(atCaretRange: " " + LoremIpsum.word())
        }
    }
    
    func simulateUserTyping(_ sender: AnyObject) {
        
        if !self.canShowTypingIndicator() {
            return
        }
        
        if DEBUG_CUSTOM_TYPING_INDICATOR == true {
            guard let view = self.typingIndicatorProxyView as? TypingIndicatorView else {
                return
            }
            
            let scale = UIScreen.main.scale
            let imgSize = CGSize(width: kTypingIndicatorViewAvatarHeight*scale, height: kTypingIndicatorViewAvatarHeight*scale)
            
            // This will cause the typing indicator to show after a delay ¯\_(ツ)_/¯
            LoremIpsum.asyncPlaceholderImage(with: imgSize, completion: { (image) -> Void in
                guard let cgImage = image?.cgImage else {
                    return
                }
                let thumbnail = UIImage(cgImage: cgImage, scale: scale, orientation: .up)
                view.presentIndicator(withName: LoremIpsum.name(), image: thumbnail)
            })
        }
        else {
            self.typingIndicatorView!.insertUsername(LoremIpsum.name())
        }
    }
    
    func didLongPressCell(_ gesture: UIGestureRecognizer) {
        
        guard let view = gesture.view else {
            return
        }

        if gesture.state != .began {
            return
        }
        
        if #available(iOS 8, *) {
            let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            alertController.modalPresentationStyle = .popover
            alertController.popoverPresentationController?.sourceView = view.superview
            alertController.popoverPresentationController?.sourceRect = view.frame
            
            alertController.addAction(UIAlertAction(title: "Edit Message", style: .default, handler: { [unowned self] (action) -> Void in
                self.editCellMessage(gesture)
                }))
            
            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            
            self.navigationController?.present(alertController, animated: true, completion: nil)
        }
        else {
            self.editCellMessage(gesture)
        }
    }
    
    func editCellMessage(_ gesture: UIGestureRecognizer) {
        
        guard let cell = gesture.view as? MessageTableViewCell else {
            return
        }
        
        self.editingMessage = self.messages[cell.indexPath.row]
        self.editText(self.editingMessage.text)
        
        self.tableView.scrollToRow(at: cell.indexPath, at: .bottom, animated: true)
    }
    
    func editRandomMessage(_ sender: AnyObject) {
        
        var sentences = Int(arc4random() % 10)
        
        if sentences <= 1 {
            sentences = 1
        }
        
        self.editText(LoremIpsum.sentences(withNumber: sentences))
    }
    
    func editLastMessage(_ sender: AnyObject?) {
        
        if self.textView.text.characters.count > 0 {
            return
        }
        
        let lastSectionIndex = self.tableView.numberOfSections-1
        let lastRowIndex = self.tableView.numberOfRows(inSection: lastSectionIndex)-1
        
        let lastMessage = self.messages[lastRowIndex]
        
        self.editText(lastMessage.text)
        
        self.tableView.scrollToRow(at: IndexPath(row: lastRowIndex, section: lastSectionIndex), at: .bottom, animated: true)
    }
    
    func togglePIPWindow(_ sender: AnyObject) {
        
        if self.pipWindow == nil {
            self.showPIPWindow(sender)
        }
        else {
            self.hidePIPWindow(sender)
        }
    }
    
    func showPIPWindow(_ sender: AnyObject) {
        
        var frame = CGRect(x: self.view.frame.width - 60.0, y: 0.0, width: 50.0, height: 50.0)
        frame.origin.y = self.textInputbar.frame.minY - 60.0
        
        self.pipWindow = UIWindow(frame: frame)
        self.pipWindow?.backgroundColor = UIColor.black
        self.pipWindow?.layer.cornerRadius = 10
        self.pipWindow?.layer.masksToBounds = true
        self.pipWindow?.isHidden = false
        self.pipWindow?.alpha = 0.0
        
        UIApplication.shared.keyWindow?.addSubview(self.pipWindow!)
        
        UIView.animate(withDuration: 0.25, animations: { [unowned self] () -> Void in
            self.pipWindow?.alpha = 1.0
        }) 
    }
    
    func hidePIPWindow(_ sender: AnyObject) {
        
        UIView.animate(withDuration: 0.3, animations: { [unowned self] () -> Void in
            self.pipWindow?.alpha = 0.0
            }, completion: { [unowned self] (finished) -> Void in
                self.pipWindow?.isHidden = true
                self.pipWindow = nil
        }) 
    }
    
    func textInputbarDidMove(_ note: Notification) {
        
        guard let pipWindow = self.pipWindow else {
            return
        }
        
        guard let userInfo = (note as NSNotification).userInfo else {
            return
        }
        
        guard let value = userInfo["origin"] as? NSValue else {
            return
        }
        
        var frame = pipWindow.frame
        frame.origin.y = value.cgPointValue.y - 60.0
        
        pipWindow.frame = frame
    }
}

extension MessageViewController {
    
    // MARK: - Overriden Methods
    
    override func ignoreTextInputbarAdjustment() -> Bool {
        return super.ignoreTextInputbarAdjustment()
    }
    
    override func forceTextInputbarAdjustment(for responder: UIResponder!) -> Bool {
        
        if #available(iOS 8.0, *) {
            guard let _ = responder as? UIAlertController else {
                // On iOS 9, returning YES helps keeping the input view visible when the keyboard if presented from another app when using multi-tasking on iPad.
                return UIDevice.current.userInterfaceIdiom == .pad
            }
            return true
        }
        else {
            return UIDevice.current.userInterfaceIdiom == .pad
        }
    }
    
    // Notifies the view controller that the keyboard changed status.
    override func didChangeKeyboardStatus(_ status: SLKKeyboardStatus) {
        switch status {
        case .willShow:
            print("Will Show")
        case .didShow:
            print("Did Show")
        case .willHide:
            print("Will Hide")
        case .didHide:
            print("Did Hide")
        }
    }
    
    // Notifies the view controller that the text will update.
    override func textWillUpdate() {
        super.textWillUpdate()
    }
    
    // Notifies the view controller that the text did update.
    override func textDidUpdate(_ animated: Bool) {
        super.textDidUpdate(animated)
    }
    
    // Notifies the view controller when the left button's action has been triggered, manually.
    override func didPressLeftButton(_ sender: Any!) {
        super.didPressLeftButton(sender)
        
        self.dismissKeyboard(true)
        self.performSegue(withIdentifier: "Push", sender: nil)
    }
    
    // Notifies the view controller when the right button's action has been triggered, manually or by using the keyboard return key.
    override func didPressRightButton(_ sender: Any!) {
        
        // This little trick validates any pending auto-correction or auto-spelling just after hitting the 'Send' button
        self.textView.refreshFirstResponder()
        
        let message = Message()
        message.username = LoremIpsum.name()
        message.text = self.textView.text
        
        let indexPath = IndexPath(row: 0, section: 0)
        let rowAnimation: UITableViewRowAnimation = self.isInverted ? .bottom : .top
        let scrollPosition: UITableViewScrollPosition = self.isInverted ? .bottom : .top
        
        self.tableView.beginUpdates()
        self.messages.insert(message, at: 0)
        self.tableView.insertRows(at: [indexPath], with: rowAnimation)
        self.tableView.endUpdates()
        
        self.tableView.scrollToRow(at: indexPath, at: scrollPosition, animated: true)
        
        // Fixes the cell from blinking (because of the transform, when using translucent cells)
        // See https://github.com/slackhq/SlackTextViewController/issues/94#issuecomment-69929927
        self.tableView.reloadRows(at: [indexPath], with: .automatic)
        
        super.didPressRightButton(sender)
    }
    
    override func didPressArrowKey(_ keyCommand: UIKeyCommand?) {
        
        guard let keyCommand = keyCommand else { return }
        
        if keyCommand.input == UIKeyInputUpArrow && self.textView.text.characters.count == 0 {
            self.editLastMessage(nil)
        }
        else {
            super.didPressArrowKey(keyCommand)
        }
    }
    
    override func keyForTextCaching() -> String? {
        
        return Bundle.main.bundleIdentifier
    }
    
    // Notifies the view controller when the user has pasted a media (image, video, etc) inside of the text view.
    override func didPasteMediaContent(_ userInfo: [AnyHashable: Any]) {
        
        super.didPasteMediaContent(userInfo)
        
        let mediaType = (userInfo[SLKTextViewPastedItemMediaType] as? NSNumber)?.intValue
        let contentType = userInfo[SLKTextViewPastedItemContentType]
        let data = userInfo[SLKTextViewPastedItemData]
        
        print("didPasteMediaContent : \(contentType) (type = \(mediaType) | data : \(data))")
    }
    
    // Notifies the view controller when a user did shake the device to undo the typed text
    override func willRequestUndo() {
        super.willRequestUndo()
    }
    
    // Notifies the view controller when tapped on the right "Accept" button for commiting the edited text
    override func didCommitTextEditing(_ sender: Any) {

        self.editingMessage.text = self.textView.text
        self.tableView.reloadData()
        
        super.didCommitTextEditing(sender)
    }
    
    // Notifies the view controller when tapped on the left "Cancel" button
    override func didCancelTextEditing(_ sender: Any) {
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
    
    override func shouldProcessText(forAutoCompletion text: String) -> Bool {
        return true
    }
    
    override func didChangeAutoCompletionPrefix(_ prefix: String, andWord word: String) {
        
        var array:Array<String> = []
        let wordPredicate = NSPredicate(format: "self BEGINSWITH[c] %@", word);
        
        self.searchResult = nil
        
        if prefix == "@" {
            if word.characters.count > 0 {
                array = self.users.filter { wordPredicate.evaluate(with: $0) };
            }
            else {
                array = self.users
            }
        }
        else if prefix == "#" {
            
            if word.characters.count > 0 {
                array = self.channels.filter { wordPredicate.evaluate(with: $0) };
            }
            else {
                array = self.channels
            }
        }
        else if (prefix == ":" || prefix == "+:") && word.characters.count > 0 {
            array = self.emojis.filter { wordPredicate.evaluate(with: $0) };
        }
        else if prefix == "/" && self.foundPrefixRange.location == 0 {
            if word.characters.count > 0 {
                array = self.commands.filter { wordPredicate.evaluate(with: $0) };
            }
            else {
                array = self.commands
            }
        }

        var show = false
        
        if array.count > 0 {
            let sortedArray = array.sorted { $0.localizedCaseInsensitiveCompare($1) == ComparisonResult.orderedAscending }
            self.searchResult = sortedArray
            show = sortedArray.count > 0
        }
        
        self.showAutoCompletionView(show)
    }
    
    override func heightForAutoCompletionView() -> CGFloat {
        
        guard let searchResult = self.searchResult else {
            return 0
        }
        
        let cellHeight = self.autoCompletionView.delegate?.tableView!(self.autoCompletionView, heightForRowAt: IndexPath(row: 0, section: 0))
        guard let height = cellHeight else {
            return 0
        }
        return height * CGFloat(searchResult.count)
    }
}

extension MessageViewController {
    
    // MARK: - UITableViewDataSource Methods
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
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
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if tableView == self.tableView {
            return self.messageCellForRowAtIndexPath(indexPath)
        }
        else {
            return self.autoCompletionCellForRowAtIndexPath(indexPath)
        }
    }
    
    func messageCellForRowAtIndexPath(_ indexPath: IndexPath) -> MessageTableViewCell {
        
        let cell = self.tableView.dequeueReusableCell(withIdentifier: MessengerCellIdentifier) as! MessageTableViewCell
        
        if cell.gestureRecognizers?.count == nil {
            let longPress = UILongPressGestureRecognizer(target: self, action: #selector(MessageViewController.didLongPressCell(_:)))
            cell.addGestureRecognizer(longPress)
        }

        let message = self.messages[(indexPath as NSIndexPath).row]
        
        cell.titleLabel.text = message.username
        cell.bodyLabel.text = message.text
        
        cell.indexPath = indexPath
        cell.usedForMessage = true
        
        // Cells must inherit the table view's transform
        // This is very important, since the main table view may be inverted
        cell.transform = self.tableView.transform
        
        return cell
    }
    
    func autoCompletionCellForRowAtIndexPath(_ indexPath: IndexPath) -> MessageTableViewCell {
        
        let cell = self.autoCompletionView.dequeueReusableCell(withIdentifier: AutoCompletionCellIdentifier) as! MessageTableViewCell
        cell.indexPath = indexPath
        cell.selectionStyle = .default

        guard let searchResult = self.searchResult else {
            return cell
        }
        
        guard let prefix = self.foundPrefix else {
            return cell
        }
        
        var text = searchResult[(indexPath as NSIndexPath).row]
        
        if prefix == "#" {
            text = "# " + text
        }
        else if prefix == ":" || prefix == "+:" {
            text = ":\(text):"
        }
        
        cell.titleLabel.text = text
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        if tableView == self.tableView {
            let message = self.messages[(indexPath as NSIndexPath).row]
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineBreakMode = .byWordWrapping
            paragraphStyle.alignment = .left
            
            let pointSize = MessageTableViewCell.defaultFontSize()
            
            let attributes = [
                NSFontAttributeName : UIFont.systemFont(ofSize: pointSize),
                NSParagraphStyleAttributeName : paragraphStyle
            ]
            
            var width = tableView.frame.width-kMessageTableViewCellAvatarHeight
            width -= 25.0
            
            let titleBounds = (message.username as NSString).boundingRect(with: CGSize(width: width, height: CGFloat.greatestFiniteMagnitude), options: .usesLineFragmentOrigin, attributes: attributes, context: nil)
            let bodyBounds = (message.text as NSString).boundingRect(with: CGSize(width: width, height: CGFloat.greatestFiniteMagnitude), options: .usesLineFragmentOrigin, attributes: attributes, context: nil)
            
            if message.text.characters.count == 0 {
                return 0
            }
            
            var height = titleBounds.height
            height += bodyBounds.height
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
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if tableView == self.autoCompletionView {
            
            guard let searchResult = self.searchResult else {
                return
            }
            
            var item = searchResult[(indexPath as NSIndexPath).row]
            
            if self.foundPrefix == "@" && self.foundPrefixRange.location == 0 {
                item += ":"
            }
            else if self.foundPrefix == ":" || self.foundPrefix == "+:" {
                item += ":"
            }
            
            item += " "
            
            self.acceptAutoCompletion(with: item, keepPrefix: true)
        }
    }
}

extension MessageViewController {
    
    // MARK: - UIScrollViewDelegate Methods
    
    // Since SLKTextViewController uses UIScrollViewDelegate to update a few things, it is important that if you override this method, to call super.
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        super.scrollViewDidScroll(scrollView)
    }
    
}

extension MessageViewController {
    
    // MARK: - UITextViewDelegate Methods
    
    override func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        return true
    }
    
    override func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        // Since SLKTextViewController uses UIScrollViewDelegate to update a few things, it is important that if you override this method, to call super.
        return true
    }
    
    override func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        return super.textView(textView, shouldChangeTextIn: range, replacementText: text)
    }
    
    override func textView(_ textView: SLKTextView, shouldOfferFormattingForSymbol symbol: String) -> Bool {
        
        if symbol == ">" {
            let selection = textView.selectedRange
            
            // The Quote formatting only applies new paragraphs
            if selection.location == 0 && selection.length > 0 {
                return true
            }
            
            // or older paragraphs too
            let prevString = (textView.text as NSString).substring(with: NSMakeRange(selection.location-1, 1))
            
            if CharacterSet.newlines.contains(UnicodeScalar((prevString as NSString).character(at: 0))!) {
                return true
            }
            
            return false
        }
        
        return super.textView(textView, shouldOfferFormattingForSymbol: symbol)
    }
    
    override func textView(_ textView: SLKTextView, shouldInsertSuffixForFormattingWithSymbol symbol: String, prefixRange: NSRange) -> Bool {
        
        if symbol == ">" {
            return false
        }
        
        return super.textView(textView, shouldInsertSuffixForFormattingWithSymbol: symbol, prefixRange: prefixRange)
    }
}
