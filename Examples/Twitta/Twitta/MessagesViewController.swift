//
//  MessagesViewController.swift
//  Twitta
//
//  Created by Ignacio Romero Z. on 9/29/14.
//  Copyright (c) 2014 Slack Technologies, Inc. All rights reserved.
//

class MessagesViewController: SLKTextViewController {
    
    var searchResult:NSMutableArray!
    
    // MARK: - Initializers

//    // init with TableView
//    override init() {
//        //#warning Potentially incomplete method implementation.
//        super.init(tableViewStyle: UITableViewStyle.Plain)
//    }
//    
//    // init with CollectionView
//    override init() {
//        //#warning Potentially incomplete method implementation.
//        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
//        super.init(collectionViewLayout: layout)
//    }
//
//    required init(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
    
    class override func tableViewStyleForCoder(decoder: NSCoder) -> UITableViewStyle {
        return UITableViewStyle.Plain
    }
    
//    class override func collectionViewLayoutForCoder(decoder: NSCoder) -> UICollectionViewLayout {
//        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
//        layout.sectionInset = UIEdgeInsets(top: 20, left: 10, bottom: 10, right: 10)
//        layout.itemSize = CGSize(width: 90, height: 120)
//        return layout
//    }
    
    
    // MARK: - View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.bounces = false;
        self.undoShakingEnabled = true;
        self.keyboardPanningEnabled = true;
        self.inverted = true;
        
        self.textInputbar.autoHideRightButton = false;
        self.textView.placeholder = "Start a new message"
        
        registerPrefixesForAutoCompletion(["@","#"])
    }
    
    
    // MARK: - SlackTextViewController

    override func textWillUpdate() {
        super.textWillUpdate()
    }
    
    override func textDidUpdate(animated: Bool) {
        super.textDidUpdate(animated)
    }
    
    override func didPressRightButton(sender: AnyObject!) {
        super.didPressRightButton(sender)
    }
    
    override func didPressLeftButton(sender: AnyObject!) {
        super.didPressLeftButton(sender)
    }
    
    override func canPressRightButton() -> Bool {
        return super.canPressRightButton()
    }
    
    override func didPasteImage(image: UIImage!) {
        // Useful for sending an image
    }
    
    override func willRequestUndo() {
        super.willRequestUndo()
    }
    
    override func canShowAutoCompletion() -> Bool {
        
        let prefix = self.foundPrefix;
        let word = self.foundWord;
        
        return false;
    }
    
    override func heightForAutoCompletionView() -> CGFloat {
        return 0.0
    }
    
    
    // MARK: - <UITableViewDataSource>

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 20
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var cell = tableView.dequeueReusableCellWithIdentifier("CELL") as UITableViewCell!
        if (cell == nil) {
            cell = UITableViewCell(style:.Default, reuseIdentifier: "CELL")
        }
        
        cell.textLabel?.text = "cell"
        cell.transform = tableView.transform
        
        return cell
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 40.0
    }
    
    
    // MARK: - <UITableViewDelegate>

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
    }
}
