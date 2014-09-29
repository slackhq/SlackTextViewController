//
//  MessagesViewController.swift
//  Twitta
//
//  Created by Ignacio Romero Z. on 9/29/14.
//  Copyright (c) 2014 Slack Technologies, Inc. All rights reserved.
//

class MessagesViewController: SLKTextViewController {
    
    class override func tableViewStyleForCoder(decoder: NSCoder) -> UITableViewStyle {
        return UITableViewStyle.Plain
    }
    
//    class override func collectionViewLayoutForCoder(decoder: NSCoder) -> UICollectionViewLayout {
//        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
//        layout.sectionInset = UIEdgeInsets(top: 20, left: 10, bottom: 10, right: 10)
//        layout.itemSize = CGSize(width: 90, height: 120)
//        return layout
//    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
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
}
