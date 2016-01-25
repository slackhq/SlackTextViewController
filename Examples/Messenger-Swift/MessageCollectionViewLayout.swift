//
//  MessageCollectionViewLayout.swift
//  Messenger
//
//  Created by Ignacio Romero on 1/23/16.
//  Copyright © 2016 Slack Technologies, Inc. All rights reserved.
//

import UIKit

protocol MessageCollectionViewDelegateLayout: UICollectionViewDelegateFlowLayout {
    func collectionView(collectionView: UICollectionView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
}

class MessageCollectionViewLayout: UICollectionViewFlowLayout {

    var layoutDelegate: MessageCollectionViewDelegateLayout {
        get {
            return self.collectionView!.delegate as! MessageCollectionViewDelegateLayout
        }
    }
    
    override init() {
        super.init()
        self.commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }
    
    func commonInit() {
        self.scrollDirection = .Vertical
        self.sectionInset = UIEdgeInsetsMake(10, 4, 10, 4)
        self.minimumLineSpacing = 4
    }
    
    override func prepareLayout() {
        super.prepareLayout()
    }
    
    override func collectionViewContentSize() -> CGSize {
        return super.collectionViewContentSize()
    }
}
