//
//  DownloadManager.swift
//  Reed
//
//  Created by kai zhou on 06/12/2016.
//  Copyright © 2016 kevin. All rights reserved.
//

import UIKit

import ActiveSQLite
import SQLite
import CocoaLumberjack

/// 通知：object 是 ReedInfo
public let Noti_ReedDownload_Add_To_Downlaod_List = NSNotification.Name(rawValue: "Noti_ReedDownload_Add_To_Downlaod_List")
public let Noti_ReedDownload_Start = NSNotification.Name(rawValue: "Noti_ReedDownload_Start")
public let Noti_ReedDownload_Progress = NSNotification.Name(rawValue: "Noti_ReedDownload_Progress")
public let Noti_ReedDownload_Complete = NSNotification.Name(rawValue: "Noti_ReedDownload_Complete")
public let Noti_ReedDownload_Fails = NSNotification.Name(rawValue: "Noti_ReedDownload_Fails")
public let Noti_ReedDownload_Waiting = NSNotification.Name(rawValue: "Noti_ReedDownload_Waiting")
public let Noti_ReedDownload_Pause = NSNotification.Name(rawValue: "Noti_ReedDownload_Pause")
public let Noti_ReedDownload_Delete = NSNotification.Name(rawValue: "Noti_ReedDownload_Delete")

///磁盘空间即将满: object 是 ReedInfo。 无论单个reedInfo还是批量reedInfo通知，都追加发一个object == nil的通知。
///reedInfo: whenever how many notification with reedInfo object be post, the notification with nil reedInfo will be post after thems.
public let Noti_ReedDownload_FullSpace = NSNotification.Name(rawValue: "Noti_ReedDownload_FullSpace")

//public protocol ReedDelegate:class{
//    func md5FromFile(filePath:URL) -> String?
//}

@objc public class Reed:NSObject {
    
    @objc public static let shared:Reed = Reed()
//    public weak var delegate:ReedDelegate?
    
    var cache:ReedCache!
    
    /// 同时最大下载数 Concurrency downloading count
    public var maxCount = 3
    
    /// md5重试次数  retry count when md5 fails
    public var maxRetryCount = 3

    ///上下文。每个app运行时只有一个context，用来表明用户。建议使用用户唯一标识。
    ///Reed is a singleton, context is unique when the app run.
    ///If there is one user login at same time, suggest set the context be uid.
    public var context = ""{
        didSet{
            cache.clear()
        }
    }
    
    /// 下载进度刷新间隔最短时间
    /// min timeinterval between two download progress delegate
    public var progressPostTimeInterval:TimeInterval = 0.3
    
    public private(set) var dbPath = FilePath.getDownloadDBPath()
    
    var isMultiSession:Bool{
        get{
            return DownloadManager.shared.isMultiSession
        }
        set{
            DownloadManager.shared.isMultiSession = newValue
        }
    }
    var timeoutInterval:TimeInterval{
        get{
            return DownloadManager.shared.timeoutInterval
        }
        set{
            DownloadManager.shared.timeoutInterval = newValue
        }
    }
    
    
    private override init() {
        super.init()
        isMultiSession = true
        
        Log.i("Download db path：\(dbPath)")
        ASConfigration.setDB(path: dbPath, name: DBNAME_ReedDownload)
        cache = ReedCache(manager: self)
    }
    
    public var showLogger:Bool = true {
        didSet{
            Log.showLogger = showLogger
        }
    }
    
    public func configLogger(level:DDLogLevel? = .info, timeFormatter:(()->String)? = nil){
        showLogger = true
        Log.config(level: level, timeFormatter: timeFormatter)
    }
    
    //MARK: Save and post notification
    func failedStatusAndPost(downloadInfo:ReedInfo, reason:ReedDownloadFailReason, isTryStart:Bool = false) {
        
        downloadInfo.downloadStatus = .faild
        
        switch reason {
        case .md5Verification:
            downloadInfo.retryCount = maxRetryCount
            downloadInfo.downloadFailReason = reason
            downloadInfo.writedBytes = 0
            break
        default:
            break
        }
        
        ActiveSQLite.save(db: downloadInfo.db, {
            try downloadInfo.update()
        }, completion: {[weak self] (error) in
            if error == nil {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: Noti_ReedDownload_Fails, object: downloadInfo, userInfo: nil)
                }
                
            }
            if isTryStart {
                self?.checkToStart()
            }
        })
    }
    
    func pauseStatusAndPost(downloadInfo:ReedInfo,isTryStart:Bool = false){
        downloadInfo.downloadStatus = .pause
        ActiveSQLite.save(db: downloadInfo.db, {
            try downloadInfo.update()
        }, completion: {[weak self] (error) in
            if error == nil {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: Noti_ReedDownload_Pause, object: downloadInfo, userInfo: nil)
                }
                
            }
            if isTryStart {
                self?.checkToStart()
            }
            
        })
    }
    
    func waitingStatus(downloadInfo:ReedInfo){
        downloadInfo.downloadStatus = .waiting
        ActiveSQLite.save(db: downloadInfo.db, {
            try downloadInfo.update()
        }, completion: nil)
        
    }
    
    
    func waitingStatusAndPost(downloadInfo:ReedInfo,isTryStart:Bool = false){
        downloadInfo.downloadStatus = .waiting
        ActiveSQLite.save(db: downloadInfo.db, {
            try downloadInfo.update()
        }, completion: {[weak self] (error) in
            if error == nil {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: Noti_ReedDownload_Waiting, object: downloadInfo, userInfo: nil)
                }

            }
            if isTryStart {
                self?.checkToStart()
            }
        })

    }

    
    func downloadingStatusAndPost(downloadInfo:ReedInfo){
        downloadInfo.downloadStatus = .downloading
        ActiveSQLite.save(db: downloadInfo.db, {
            try downloadInfo.update()
        }, completion: {(error) in
            if error == nil {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: Noti_ReedDownload_Progress, object: downloadInfo, userInfo: nil)
                }
                
            }
        })
        
    }
    
    func completeStatusAndPost(downloadInfo:ReedInfo,isTryStart:Bool = false){
        downloadInfo.downloadStatus = .completed
        ActiveSQLite.save(db: downloadInfo.db, {
            try downloadInfo.update()
        }, completion: {[weak self](error) in
            if error == nil {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: Noti_ReedDownload_Complete, object: downloadInfo, userInfo: nil)
                }
                
            }
            if isTryStart {
                self?.checkToStart()
            }
        })
    }

    func deleteAndPost(downloadInfo:ReedInfo,isTryStart:Bool = false){
        ActiveSQLite.save(db: downloadInfo.db, {
            try downloadInfo.delete()
        }) { [weak self] (error) in
            if error == nil {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: Noti_ReedDownload_Delete, object: downloadInfo, userInfo: nil)
                }
            }
            
            if isTryStart {
                self?.checkToStart()
            }
            
        }
    }
}


