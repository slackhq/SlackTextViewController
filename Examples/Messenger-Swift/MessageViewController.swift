//
//  MessageViewController.swift
//  Messenger-Swift
//
//  Created by Ignacio Romero Zurbuchen on 10/16/14.
//  Copyright (c) 2014 Slack Technologies, Inc. All rights reserved.
//

import Foundation
import UIKit

let kMessageCellIdentifier: String = "MessageCell"
let kMessageCellHeight:CGFloat = 44

let kAutoCompletionCellIdentifier:String = "AutoCompletionCell"

class MessageViewController: SLKTextViewController {

    var messages: [String] = []
    
    var channels = ["General", "Random", "iOS", "Bugs", "Sports", "Android", "UI", "SSB"]
    var users = ["Allen", "Anna", "Alicia", "Arnold", "Armando", "Antonio", "Brad", "Catalaya", "Christoph", "Emerson", "Eric", "Everyone", "Steve"]

    var searchResult: [String] = []
    
    override class func tableViewStyleForCoder(decoder: NSCoder) -> UITableViewStyle {
        return .Plain
    }
    
    override class func collectionViewLayoutForCoder(decoder: NSCoder) -> UICollectionViewLayout {
        return MessageCollectionViewLayout()
    }
    
    override var keyCommands: [UIKeyCommand]? {
        
        var commands = super.keyCommands
        
        // Edit last message
        let command = UIKeyCommand(input: UIKeyInputUpArrow, modifierFlags: .Command, action: "editLastMessage:")
        commands?.append(command)
        
        return commands
    }
    
    // MARK: - View lifecycle
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        for _ in 0...101 {
            let text = LoremIpsum.wordsWithNumber(20)
            self.messages.append(text)
        }
        
        self.configureViews()
    }
    
    func configureViews() {
        
        self.bounces = true
        self.shakeToClearEnabled = true
        self.keyboardPanningEnabled = true
        self.inverted = false
        
        self.textView.placeholder = "Message"
        self.textView.placeholderColor = UIColor.lightGrayColor()
        
        self.leftButton.setImage(UIImage(named: "icn_upload"), forState: UIControlState.Normal)
        self.leftButton.tintColor = UIColor.grayColor()
        self.rightButton.setTitle("Send", forState: UIControlState.Normal)
        
        self.textInputbar.autoHideRightButton = true
        self.textInputbar.maxCharCount = 140
        self.textInputbar.counterStyle = SLKCounterStyle.Split
        
        self.typingIndicatorView?.canResignByTouch = true
        
        let cellNib: UINib = UINib(nibName: "MessageCollectionViewCell", bundle: NSBundle.mainBundle())
        self.collectionView?.registerNib(cellNib, forCellWithReuseIdentifier: kMessageCellIdentifier)
        
        self.autoCompletionView.registerClass(UITableViewCell.self, forCellReuseIdentifier: kAutoCompletionCellIdentifier)
        
        self.registerPrefixesForAutoCompletion(["@", "#"])
        
        self.textView.registerMarkdownFormattingSymbol("*", withTitle: "Bold")
    }
    
    
    // MARK: - SLKTextViewController
    
    override func didPressLeftButton(sender: AnyObject!) {
        
        // Notifies the view controller when the left button's action has been triggered, manually.
        
        super.didPressLeftButton(sender)
    }
    
    override func didPressRightButton(sender: AnyObject!) {
        
        // Notifies the view controller when the right button's action has been triggered, manually or by using the keyboard return key.
        
        // This little trick validates any pending auto-correction or auto-spelling just after hitting the 'Send' button
        textView.refreshFirstResponder()
        
        if let text = self.textView.text, let collectionView = collectionView {
            
            self.messages.append(text)
            
            let idxPath = NSIndexPath(forItem: 0, inSection: 0)
            collectionView.insertItemsAtIndexPaths([idxPath])
            
            collectionView.slk_scrollToBottomAnimated(true)
        }
        
        super.didPressRightButton(sender)
    }
    
    override func didCommitTextEditing(sender: AnyObject) {
        
        let message:String = self.textView.text
        
        self.messages.removeAtIndex(0)
        self.messages.insert(message, atIndex: 0)
        
        self.tableView!.reloadData()
        
        super.didCommitTextEditing(sender)
    }
    
    override func didCancelTextEditing(sender: AnyObject) {
        
        super.didCancelTextEditing(sender)
    }
    
    override func keyForTextCaching() -> String? {
        return NSBundle.mainBundle().bundleIdentifier
    }

    // MARK: - Overriden Methods
    // MARK: ----
    // MARK: Auto-Completion
    
    override func didChangeAutoCompletionPrefix(prefix: String, andWord word: String) {
        
        var array: NSArray = []
        var show = false
        
        if prefix == "#" {
            array = channels as [AnyObject]
        }
        else if prefix == "@" {
            array = users as [AnyObject]
        }
        
        if array.count > 0 {
            if word.characters.count > 0 {
                array = array.filteredArrayUsingPredicate(NSPredicate(format: "self BEGINSWITH[c] %@", word))
            }
            
            array = array.sort() { $0.localizedCaseInsensitiveCompare($1 as! String) == NSComparisonResult.OrderedAscending }
            
            self.searchResult = array as! [String]
            show = (self.searchResult.count > 0)
        }
        
        self.showAutoCompletionView(show)
    }
    
    override func heightForAutoCompletionView() -> CGFloat {
        return kMessageCellHeight * CGFloat(self.searchResult.count)
    }
    
    // MARK: - SLKTextViewDelegate
    
    // MARK: - UITextViewDelegate
    
    // MARK: - UICollectionViewDataSource
    
    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.messages.count
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(kMessageCellIdentifier, forIndexPath: indexPath) as! MessageCollectionViewCell
        
        let text = self.messages[indexPath.row]
        cell.titleLabel.text = text
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
        let text = self.messages[indexPath.row]
        
        let maxWidth: CGFloat = CGRectGetWidth(collectionView.frame)
        let minHeight: CGFloat = 40
        
        if (text.characters.count == 0) {
            return minHeight;
        }

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = NSLineBreakMode.ByWordWrapping
        paragraphStyle.alignment = NSTextAlignment.Left
        
        let attributes = [NSFontAttributeName: kMessageCellFont, NSParagraphStyleAttributeName: paragraphStyle]
        let boundingRect = text.boundingRectWithSize(CGSizeMake(maxWidth, 0), options:NSStringDrawingOptions.UsesLineFragmentOrigin, attributes: attributes, context: nil)
        
        let height = max(CGRectGetHeight(boundingRect), minHeight)
        print("height: ", height)
        
        return height
    }
    
    // MARK: - UITableViewDataSource
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.searchResult.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        if let cell = tableView.dequeueReusableCellWithIdentifier(kAutoCompletionCellIdentifier) {
            cell.textLabel!.text = self.searchResult[indexPath.row]
            
            return cell
        }
        
        return UITableViewCell()
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return kMessageCellHeight
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if tableView.isEqual(tableView) {
            var item = self.searchResult[indexPath.row]
            item += " "
            
            self.acceptAutoCompletionWithString(item)
        }
    }
    
    // MARK: - UIScrollViewDelegate
    
    // MARK: - Lifeterm
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
}
