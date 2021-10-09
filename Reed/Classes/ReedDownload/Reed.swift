//
//  DownloadManager.swift
//  Reed
//
//  Created by kai zhou on 06/12/2016.
//  Copyright © 2016 kevin. All rights reserved.
//

import UIKit

import ZKORM
import GRDB
import CocoaLumberjack

extension Reed{
    /// 通知：object 是 ReedInfo
    public static let downloadAddToDownlaodListNotification = NSNotification.Name(rawValue: "ReedDownloadAddToDownlaodListNotification")
    public static let downloadStartNotification = NSNotification.Name(rawValue: "ReedDownloadStartNotification")
    public static let downloadProgressNotification = NSNotification.Name(rawValue: "ReedDownloadProgressNotification")
    public static let downloadCompleteNotification = NSNotification.Name(rawValue: "ReedDownloadCompleteNotification")
    public static let downloadFailsNotification = NSNotification.Name(rawValue: "ReedDownloadFailsNotification")
    public static let downloadWaitingNotification = NSNotification.Name(rawValue: "ReedownloadWaitingNotification")
    public static let downloadPauseNotification = NSNotification.Name(rawValue: "ReedDownloadPauseNotification")
    public static let downloadDeleteNotification = NSNotification.Name(rawValue: "ReedDownloadDeleteNotification")
    ///磁盘空间即将满: object 是 ReedInfo。 无论单个reedInfo还是批量reedInfo通知，都追加发一个object == nil的通知。
    ///reedInfo: whenever how many notification with reedInfo object be post, the notification with nil reedInfo will be post after thems.
    public static let downloadFullSpaceNotification = NSNotification.Name(rawValue: "ReedDownloadFullSpaceNotification")
}


public protocol ReedDelegate:AnyObject{
//    func md5FromFile(filePath:URL) -> String?
    func getURL(downloadKey:String) -> String?
}

extension ReedDelegate{
    func getURL(downloadKey:String) -> String?{
        return nil
    }
}
@objc public class Reed:NSObject {
    
    @objc public static let shared:Reed = Reed()
    public weak var delegate:ReedDelegate?
    
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
    
    public var needUrlEncoding:Bool{
        get{
            return DownloadManager.shared.needUrlEncoding
        }
        set{
            DownloadManager.shared.needUrlEncoding = newValue
        }
    }
    
    public var allowCellularDownload:Bool = false{
        didSet{
            if allowCellularDownload != oldValue{
                checkReabilityChanged()
            }
        }
    }
    
    private override init() {
        super.init()
        isMultiSession = true
        
        Log.i("Download db path：\(dbPath)")
        ZKORMConfigration.setDB(path: dbPath, name: DBNAME_ReedDownload)
        try! ReedInfo.createTable()
        cache = ReedCache(manager: self)
        
        //打开监听
        ReedReachability.startMonitor()
        addNotifications()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
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
        
        ZKORM.save(dbQueue: try! downloadInfo.getDBQueue(), {db in
            try downloadInfo.update(db)
        }, completion: {[weak self] (error) in
            if error == nil {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: Reed.downloadFailsNotification, object: downloadInfo, userInfo: nil)
                }
                
            }
            if isTryStart {
                self?.checkToStart()
            }
        })
    }
    
    func pauseStatusAndPost(downloadInfo:ReedInfo,isTryStart:Bool = false){
        downloadInfo.downloadStatus = .pause
        ZKORM.save(dbQueue: try! downloadInfo.getDBQueue(), {db in
            try downloadInfo.update(db)
        }, completion: {[weak self] (error) in
            if error == nil {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: Reed.downloadPauseNotification, object: downloadInfo, userInfo: nil)
                }
                
            }
            if isTryStart {
                self?.checkToStart()
            }
            
        })
    }
    
    func waitingStatus(downloadInfo:ReedInfo){
        downloadInfo.downloadStatus = .waiting
        ZKORM.save(dbQueue: try! downloadInfo.getDBQueue(), {db in
            try downloadInfo.update(db)
        }, completion: nil)
        
    }
    
    
    func waitingStatusAndPost(downloadInfo:ReedInfo,isTryStart:Bool = false){
        downloadInfo.downloadStatus = .waiting
        ZKORM.save(dbQueue: try! downloadInfo.getDBQueue(), {db in
            try downloadInfo.update(db)
        }, completion: {[weak self] (error) in
            if error == nil {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: Reed.downloadWaitingNotification, object: downloadInfo, userInfo: nil)
                }

            }
            if isTryStart {
                self?.checkToStart()
            }
        })

    }

    
    func downloadingStatusAndPost(downloadInfo:ReedInfo){
        downloadInfo.downloadStatus = .downloading
        ZKORM.save(dbQueue: try! downloadInfo.getDBQueue(), {db in
            try downloadInfo.update(db)
        }, completion: {(error) in
            if error == nil {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: Reed.downloadProgressNotification, object: downloadInfo, userInfo: nil)
                }
                
            }
        })
        
    }
    
    func completeStatusAndPost(downloadInfo:ReedInfo,isTryStart:Bool = false){
        downloadInfo.downloadStatus = .completed
        ZKORM.save(dbQueue: try! downloadInfo.getDBQueue(), {db in
            try downloadInfo.update(db)
        }, completion: {[weak self](error) in
            if error == nil {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: Reed.downloadCompleteNotification, object: downloadInfo, userInfo: nil)
                }
                
            }
            if isTryStart {
                self?.checkToStart()
            }
        })
    }

    func deleteAndPost(downloadInfo:ReedInfo,isTryStart:Bool = false){
        ZKORM.save(dbQueue: try! downloadInfo.getDBQueue(), {db in
            try downloadInfo.delete(db)
        }) { [weak self] (error) in
            if error == nil {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: Reed.downloadDeleteNotification, object: downloadInfo, userInfo: nil)
                }
            }
            
            if isTryStart {
                self?.checkToStart()
            }
            
        }
    }
}


