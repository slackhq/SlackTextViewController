//
//  MessageCollectionViewLayout.swift
//  Messenger
//
//  Created by Ignacio Romero on 1/23/16.
//  Copyright © 2016 Slack Technologies, Inc. All rights reserved.
//

import UIKit

let itemWidth: CGFloat = 40

protocol MessageCollectionViewDelegateLayout: UICollectionViewDelegateFlowLayout {
    func collectionView(collectionView: UICollectionView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
}

class MessageCollectionViewLayout: UICollectionViewFlowLayout {
    
    var rects = NSMutableArray()
    
    var layoutDelegate: MessageCollectionViewDelegateLayout? {
        get {
            if let collectionView = self.collectionView {
                return collectionView.delegate as? MessageCollectionViewDelegateLayout
            }
            return nil
        }
    }
    
    // MARK: - Initialisation Overrides

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
    
//    override var itemSize: CGSize {
//        get {
//            if let collectionView = self.collectionView {
//                return CGSizeMake(CGRectGetWidth(collectionView.frame), itemWidth)
//            }
//            return CGSizeMake(itemWidth, itemWidth)
//        }
//        set {}
//    }
    
    // MARK: - Private
    
    func populateAllRects() {
        
        self.rects.removeAllObjects()
        
        if let collectionView = self.collectionView {
            for section in 0..<collectionView.numberOfSections() {
                for row in 0..<collectionView.numberOfItemsInSection(section) {
                    let indexPath = NSIndexPath(forRow: row, inSection: section)
                    self.populateRect(indexPath)
                }
            }
        }
    }
    
    func populateRect(indexPath: NSIndexPath) {
        
    }
    
    func frameForRowAtIndexPath(indexPath: NSIndexPath) -> CGRect {
        
        var frame = CGRectZero
        frame.size = self.sizeForRowAtIndexPath(indexPath)
        frame.origin = self.originForRowAtIndexPath(indexPath)
        return frame
    }
    
    func sizeForRowAtIndexPath(indexPath: NSIndexPath) -> CGSize {
        
//        if let delegate = self.layoutDelegate, let collectionView = self.collectionView {
//            if delegate.respondsToSelector(Selector("collectionView:heightForRowAtIndexPath:")) {
//                let size = delegate.collectionView(collectionView, heightForRowAtIndexPath: indexPath)
//                
//                CGFloat hMargins = self.sectionInset.left+self.sectionInset.right;
//
//                
//                return  CGSizeMake(CGRectGetWidth(collectionView.frame)-hMargins, height);
//            }
//        }
        
        return CGSizeZero
    }
    
    func originForRowAtIndexPath(indexPath: NSIndexPath) -> CGPoint {
        return CGPointZero
    }
    
    // MARK: - UICollectionViewLayout Overrides

    override func prepareLayout() {
        super.prepareLayout()
    }
    
    override func collectionViewContentSize() -> CGSize {
        return super.collectionViewContentSize()
    }
    
    override func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        
        return nil
    }
    
    override func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
        
        return nil
    }
    
    override func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool {
        
        return false
    }
    
    override func shouldInvalidateLayoutForPreferredLayoutAttributes(preferredAttributes: UICollectionViewLayoutAttributes, withOriginalAttributes originalAttributes: UICollectionViewLayoutAttributes) -> Bool {
        
        return false
    }
}
