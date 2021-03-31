//
//  Reed+Status.swift
//  Reed
//
//  Created by zhoukai on 2018/4/26.
//  Copyright © 2018 kai zhou. All rights reserved.
//

import Foundation

extension Reed{
    
    /// 下载中（下载中，等待，暂停，失败）
    /// Downloading progress (Downloading, waiting,pause,failed)
    ///
    /// - Parameter key:
    /// - Returns:
    public func isDownloadingProgress(_ key:String) -> Bool{
        if isUnDownload(key) || isComplete(key) {
            return false
        }else{
            return true
        }
    }
    
    /// 未下载 undownload
    ///
    /// - Parameter key:
    /// - Returns:
    public func isUnDownload(_ key:String) -> Bool{
        return cache.get(key:key) == nil
    }
    
    /// 已下载 downloaded
    ///
    /// - Parameter key:
    /// - Returns:
    public func isComplete(_ key:String) -> Bool{
        if let info = cache.get(key:key),
            info.downloadStatus == .completed{
            return true
        }
        return false
    }
    
    /// is downloading
    /// - Parameter key:
    public func isDownloading(_ key:String) -> Bool {
        if let info = cache.get(key:key) {
            return info.downloadStatus == .downloading
        }
        return false
    }
    
    
    /// is pause
    /// - Parameter key:
    public func isPause(_ key:String) -> Bool{
        if let info = cache.get(key:key) {
            return info.downloadStatus == .pause
        }
        return false
    }
    
    
    /// is waiting
    /// - Parameter key:
    public func isWaiting(_ key:String) -> Bool{
        if let info = cache.get(key:key) {
            return info.downloadStatus == .waiting
        }
        return false
    }
    
    
    /// is failed
    /// - Parameter key:
    public func isFailed(_ key:String) -> Bool {
        if let info = cache.get(key:key) {
            return info.downloadStatus == .faild
        }
        return false
    }
    
    
    /// get downloadInfo by key
    /// - Parameter key: <#key description#>
    public func getDownloadInfo(key:String) -> ReedInfo?{
        return cache.get(key: key)
    }
    
    /// 获取所有model（所有状态）
    /// Get all download infos in this downloadlistkey
    /// - Returns:
    public func getDownloadInfos(downloadListKey:String? = nil) -> [ReedInfo]{
        
        return cache.getAll(downloadListKey: downloadListKey)
    }
    
    
    /// 获取所有下载中的model（下载中，等待，暂停，失败）
    /// Get all download progress infos(downloading, waiting, pause,failed)
    /// - Returns:
    public func getDownloadProgressInfos(downloadListKey:String? = nil) -> [ReedInfo]{
        let downloadProgress = [ReedDownloadStatus.downloading,ReedDownloadStatus.waiting,ReedDownloadStatus.pause,ReedDownloadStatus.faild]
        return cache.getAll(downloadListKey: downloadListKey).filter{ downloadProgress.contains($0.downloadStatus) }
        
//        return ReedInfo()
//            .where(ReedInfo.CONTEXT == context && (downloadProgress.contains(ReedInfo.STATUS)))
//            .order(ReedInfo.created_at.asc).run()  as! [ReedInfo]
        
    }
    
    
    /// 获取所有下载完成的model
    /// Get all download complete infos in this downloadlistkey
    public func getCompleteInfos(downloadListKey:String? = nil) -> [ReedInfo]{
        return cache.getAll(downloadListKey: downloadListKey).filter{ $0.downloadStatus ==  ReedDownloadStatus.completed}
       
//        return ReedInfo.findAll( ReedInfo.CONTEXT == context && ReedInfo.STATUS == ReedDownloadStatus.completed.rawValue, order:ReedInfo.created_at.asc) as! [ReedInfo]
    }
    
    
    @objc public func getDownloadProgressCount(downloadListKey:String? = nil) -> Int{
        return getDownloadProgressInfos(downloadListKey:downloadListKey).count
    }
    
    @objc public func getDownloadingCount(downloadListKey:String? = nil) -> Int{
        return getDownloadingInfos(downloadListKey:downloadListKey).count
    }
    
    @objc public func getWaitingCount(downloadListKey:String? = nil) -> Int{
        return getWaitingInfos(downloadListKey:downloadListKey).count
    }
    
    @objc public func getPauseCount(downloadListKey:String? = nil) -> Int{
        return getPauseInfos(downloadListKey:downloadListKey).count
    }
    
    
    //MARK: internal
    /// 获取所有等待的model
    /// Get all waiting infos in this downloadlistkey
    /// - Returns:
    func getWaitingInfos(downloadListKey:String? = nil) -> [ReedInfo]{
        return cache.getAll(downloadListKey: downloadListKey).filter{ $0.downloadStatus ==  ReedDownloadStatus.waiting}
        
//        return ReedInfo.findAll(ReedInfo.STATUS == ReedDownloadStatus.waiting.rawValue && ReedInfo.CONTEXT == context, order:ReedInfo.created_at.asc) as! [ReedInfo]
    }
    
    /// 获取下载中的model
    /// Get all downloadting infos in this downloadlistkey
    ///
    /// - Returns: <#return value description#>
    func getDownloadingInfos(downloadListKey:String? = nil) -> [ReedInfo]{
        return cache.getAll(downloadListKey: downloadListKey).filter{ $0.downloadStatus ==  ReedDownloadStatus.downloading}
        
//        return ReedInfo.findAll(ReedInfo.STATUS == ReedDownloadStatus.downloading.rawValue && ReedInfo.CONTEXT == context, order:ReedInfo.created_at.asc) as! [ReedInfo]
    }
    
    /// 获取暂停中的model
    /// Get all pause infos in this downloadlistkey
    ///
    func getPauseInfos(downloadListKey:String? = nil) -> [ReedInfo]{
        return cache.getAll(downloadListKey: downloadListKey).filter{ $0.downloadStatus ==  ReedDownloadStatus.pause}
    }
    
    /// 获取running count
    /// Get all running count in this downloadlistkey
    ///
    func runningCount(downloadListKey:String? = nil) -> Int{
        return DownloadManager.shared.runningCount(group: downloadListKey)
    }
    
    
    /// 是否有剩余空间
    /// 下载中（包含预下载的）的和剩余空间判断大小
    /// 暂停所有处理中的下载
    /// - Parameter preDownloadInfo: 预备下载，还未标记下载状态的info。
    /// - Returns: 是否有剩余空间
    
    
    /// has free space
    /// - Parameter preDownloadInfo: pre download info
    /// downloading infos spaces + predownloadinfos spaces compare(==) system free size
    func hasFreeSpace(preDownloadInfo:ReedInfo? = nil) -> Bool{
        let downloadingInfos = self.getDownloadingInfos()
        //let waitingInfos = self.getWaitingInfos()
        let preDownloadingInfos = downloadingInfos
        var preDownloadingBytes = preDownloadingInfos.reduce(0) { (result, info) -> Int64 in
            return result + (Int64(info.totalBytes) - Int64(info.writedBytes))
        }
        
        if let info = preDownloadInfo {
            preDownloadingBytes += (Int64(info.totalBytes) - Int64(info.writedBytes))
        }
        
        //空间已满 full
        if let systemFreeSize = UIDevice.current.systemFreeSize ,
            preDownloadingBytes >= systemFreeSize {
            
            DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 0.3) {
                
                //设置full状态 Set full status
                downloadingInfos.forEach { (downloadInfo) in
                    downloadInfo.downloadFailReason = .fullSpace
                }
                if let info = preDownloadInfo {
                    info.downloadFailReason = .fullSpace
                }
                
                //暂停。延时 pause. exist delay
                Reed.shared.pauseAllUndone()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    //发送full通知 post full notifications
                    downloadingInfos.forEach { (downloadInfo) in
                        NotificationCenter.default.post(name: Reed.downloadFullSpaceNotification, object: downloadInfo)
                    }
                    if let info = preDownloadInfo {
                        NotificationCenter.default.post(name: Reed.downloadFullSpaceNotification, object: info)
                    }

                    NotificationCenter.default.post(name: Reed.downloadFullSpaceNotification, object: nil)
                }
            }
            
            return false
        }else{
            return true
        }
    }

}
