//
//  DownloadManagerCell.swift
//  Example
//
//  Created by zhoukai on 2018/4/23.
//  Copyright © 2018 wumingapie@gmail.com. All rights reserved.
//

import Foundation
import UIKit

import ZKORM
import Reed

class DownloadManagerCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var sizeLabel: UILabel!
    
    var downloadInfo:ReedInfo!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        NotificationCenter.default.addObserver(self, selector: #selector(downloadStart(noti:)), name: Noti_ReedDownload_Start, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(downloadFails(noti:)), name: Noti_ReedDownload_Fails, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(downloadWaiting(noti:)), name: Noti_ReedDownload_Waiting, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(downloadProgress(noti:)), name: Noti_ReedDownload_Progress, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(downloadComplete(noti:)), name: Noti_ReedDownload_Complete, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(downloadPause(noti:)), name: Noti_ReedDownload_Pause, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
    }
    
    func updateData(_ downloadInfo:ReedInfo) -> Void {
        self.downloadInfo = downloadInfo
        titleLabel.text = String(downloadInfo.url.split(separator: "/").last!)
        statusLabel.text = downloadInfo.downloadStatus.rawValue
        sizeLabel.text = "\(downloadInfo.writedBytes)   /  \(downloadInfo.totalBytes)"
        
    }
    
    @objc func downloadStart(noti:Notification) {
        if let info = noti.object as? ReedInfo,info.key == downloadInfo!.key{
            updateData(info)
        }
    }
    @objc func downloadFails(noti:Notification) {
        if let info = noti.object as? ReedInfo,info.key == downloadInfo!.key{
            updateData(info)
        }
    }

    @objc func downloadProgress(noti:Notification) {
        if let info = noti.object as? ReedInfo,info.key == downloadInfo!.key{
            updateData(info)
        }
    }
    @objc func downloadComplete(noti:Notification) {
        if let info = noti.object as? ReedInfo,info.key == downloadInfo!.key{
            updateData(info)
        }
    }
    @objc func downloadPause(noti:Notification) {
        if let info = noti.object as? ReedInfo,info.key == downloadInfo!.key{
            updateData(info)
        }
    }
    @objc func downloadWaiting(noti:Notification) {
        if let info = noti.object as? ReedInfo,info.key == downloadInfo!.key{
            updateData(info)
        }
    }
}
