//
//  PreDownloadCell.swift
//  Demo
//
//  Created by zhoukai on 2018/4/16.
//  Copyright © 2018 wumingapie@gmail.com. All rights reserved.
//

import UIKit

class PreDownloadCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
//    @IBOutlet weak var statusLabel: UILabel!
//    @IBOutlet weak var sizeLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func updateData(name:String?) -> Void {
        titleLabel.text = name
//        statusLabel.text = status
//        sizeLabel.text = size
    }

}
