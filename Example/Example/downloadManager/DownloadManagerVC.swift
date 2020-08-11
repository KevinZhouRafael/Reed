//
//  DownloadManagerVC.swift
//  Example
//
//  Created by zhoukai on 2018/4/23.
//  Copyright © 2018 wumingapie@gmail.com. All rights reserved.
//

import Foundation
import UIKit
import Reed
import ZKORM

class DownloadManagerVC: UIViewController,UITableViewDelegate,UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    
    var infos:[ReedInfo] = [ReedInfo]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        reloadSelf()
        
    }
    
    func reloadSelf(){
        let _ = Reed.shared.configDownLoadManager()
        
        infos = Reed.shared.getDownloadInfos()
        tableView.reloadData()
    }

    @IBAction func startAll(_ sender: Any) {
        Reed.shared.startBatch(keys: infos.map({ (info) -> String in
            info.key
        }))
    }
    
    
    @IBAction func pauseAll(_ sender: Any) {
        Reed.shared.pauseBatch(keys: infos.map({ (info) -> String in
            info.key
        }))
    }
    
    @IBAction func shutDown(_ sender: Any) {
        Reed.shared.stopDownload()
    }
    
//    @IBAction func checkToStart(_ sender: Any){
//        Reed.shared.checkToStart()
//    }
    
    @IBAction func deleteAll(_ sender:Any){
        Reed.shared.deleteBatch(keys: infos.map({ (info) -> String in
            info.key
        }))
        
        reloadSelf()
    }
    
    // MARK: - Table view data source
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return infos.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DownloadManagerCell", for: indexPath) as! DownloadManagerCell
        
        let info = infos[indexPath.row]
        cell.updateData(info)
        //多个下载列表 two download lists
        if info.url.hasSuffix(".dmg") {
            cell.backgroundColor = UIColor.red.withAlphaComponent(0.5)
        }else{
            cell.backgroundColor = UIColor.blue.withAlphaComponent(0.5)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let info = infos[indexPath.row]
        let key = info.key
        
        if Reed.shared.isPause(key) || Reed.shared.isFailed(key){
            Reed.shared.start( key)
        }else if Reed.shared.isDownloading(key) || Reed.shared.isWaiting(key) {
            Reed.shared.pause(key)
        }else{
            
        }
    }
        
}
