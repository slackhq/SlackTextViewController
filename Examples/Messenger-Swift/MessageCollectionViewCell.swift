//
//  MessageCollectionViewCell.swift
//  Messenger
//
//  Created by Ignacio Romero on 1/23/16.
//  Copyright © 2016 Slack Technologies, Inc. All rights reserved.
//

import UIKit

let kMessageCellFont: UIFont = UIFont.systemFontOfSize(15)

class MessageCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.titleLabel.font = kMessageCellFont
    }

}
