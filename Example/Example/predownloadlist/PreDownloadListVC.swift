//
//  PreDownloadListVC.swift
//  Demo
//
//  Created by zhoukai on 2018/4/16.
//  Copyright © 2018 wumingapie@gmail.com. All rights reserved.
//

import UIKit
import Reed
import CryptoSwift
import ActiveSQLite
import SQLite

class PreDownloadListVC: UITableViewController {

   var items:[PreDownloadItem] = [PreDownloadItem]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let data = getJSON().data(using: .utf8)!
        do {
            items = try JSONDecoder().decode([PreDownloadItem].self, from: data)
            print(items)
        } catch let error {
            print(error)
        }
        

        tableView.reloadData()
    }


    func refresh(){
        
        
    }
    
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PreDownloadCell", for: indexPath) as! PreDownloadCell

        let item = items[indexPath.row]
        cell.updateData(name: item.name)
        //多个下载列表 mutable download lists
        if item.url.hasSuffix(".dmg") {
            cell.backgroundColor = UIColor.red.withAlphaComponent(0.5) //DownloadList1
        }else{
            cell.backgroundColor = UIColor.blue.withAlphaComponent(0.5) //DownloadList2
        }
        return cell
    }
 
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let item = items[indexPath.row]
        let url = item.url
        let fileName = String(item.url.split(separator: "/").last!)
        
        let destPath = "Documents/" + fileName
        
        let savedInfo = ReedInfo.findFirst(ReedInfo.KEY == url.md5())
        if savedInfo == nil {

            if url.hasSuffix(".dmg"){
                
                Reed.shared.start(key: url.md5(), url: url, destinationFilePath: destPath, downloadListKey:"list1", md5:item.md5)
            }else{
                Reed.shared.start(key: url.md5(), url: url, destinationFilePath: destPath, downloadListKey:"list2", md5:item.md5)
            }
        }
        
    }


    func getJSON()->String{
            return """
        [
        {
        "url": "http://m4.pc6.com/cjh3/VicomsoftFTPClient.dmg"
        },
        {
        "url": "http://download3.navicat.com/download/navicat121_pgsql_en.dmg"
        },
        {
        "url": "http://gxiami.alicdn.com/xiami-desktop/update/XiamiMac-03051058.dmg"
        },
        {
        "url": "http://pcclient.download.youku.com/ikumac/youkumac_1.6.7.04093.dmg?spm=a2hpd.20022519.m_235549.5!2~5~5~5!2~P!3~A&file=youkumac_1.6.7.04093.dmg"
        },
        {
        "url": "http://codown.youdao.com/cidian/download/MacDict.dmg"
        },
        {
        "md5": "8c58fe5cb4d539gc375uccf3ff7ba961",
        "url": "http://static-oss.live.kaochong.com/bundle/NB151695460366616508208380275259_8c58fe5cb485396c3758ccf3ff7ba961.zip"
        },
        {
        "url": "http://static-oss.live.kaochong.com/bundle/NB151798606520207094095900609319_92d03fe094941478be3d2992db76959d.zip",
        "md5":"92d03fe094941478be3d2992db76959d"
        },
        {
        "url": "http://static-oss.live.kaochong.com/bundle/NB151798606520207094095900609319_92d03fe094941478be3d2992db76959d.zip",
        "md5":"92d03fe094941478be3d2992db76959d"
        },
        {
        "url": "https://www.battlenet.com.cn/download/getInstaller?os=mac&installer=StarCraft-II-Setup-CN.zip"
        },
        {
        "url": "https://qd.myapp.com/myapp/qqteam/pcqq/QQ9.0.8_2.exe"
        },
        {
        "url": "https://updates.signal.org/desktop/signal-desktop-mac-1.26.2.zip"
        }
        ]
        """
    }
    
}
