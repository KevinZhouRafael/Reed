//
//  Reed+Control.swift
//  Reed
//
//  Created by zhoukai on 2018/4/26.
//  Copyright © 2018 kai zhou. All rights reserved.
//

import Foundation
import ZKORM


extension Reed{
    
    //MARK: start
    //添加到下载列表 Add one task to download list
    ///
    ///
    /// - Parameters:
    ///   - key: 下载的唯一标识. unique identifier
    ///   - url: url
    ///   - destinationFilePath: 传相对路径。调用时候保证目录存在. This is relative path, make sure the dic exist.
    ///   - md5: 是否md5校验
    ///   - isReplace: 是否替换老文件. replace old file
    ///
    ///  Absolute path 绝对路径：/var/mobile/Containers/Data/Application/B28D3FB7-13A7-418D-A2F7-BA2F477CA55D/Documents/3292341151221648096/jz4567dbf9b5384b9ea6647da1a3a7cdf1-7121.mp4
    ///  Relative path 相对路径: Documents/3292341151221648096/jz4567dbf9b5384b9ea6647da1a3a7cdf1-7121.mp4
    public func addToStartList(key:String, url:String, destinationFilePath:String,downloadListKey:String? = nil,md5:String? = nil,isReplace:Bool = false){
        let cacheFilePath = FilePath.getCacheFilePath(key: key)
        let destFilePath = FilePath.homeDictionary() + "/" + destinationFilePath
        
        var info:ReedInfo? = cache.get(key:key)
        if info == nil {
            info = ReedInfo(retryCount: maxRetryCount, key: key, url: url,cachePath:FilePath.getRelativeCacheFilePath(key: key),destPath:destinationFilePath,context:context, downloadListKey:downloadListKey ?? context, md5:md5)
            cache.save(info!, forKey: info!.key) { (success) in
                if success {
                    DispatchQueue.main.async {
                         NotificationCenter.default.post(name: Noti_ReedDownload_Add_To_Downlaod_List, object: info!)
                    }
                }
            }
            
        }
        
    }
    
    @objc public func startForOC(key:String){
        start(key)
    }
    /// 开始下载：非首次开始下载
    /// Start download. should be execute after addToStartList
    /// - Parameter key:
    public func start(_ key:String, isReplace:Bool = false){
        
        guard let info = cache.get(key:key) else {
            return
        }
        
        start(key: info.key, url: info.url, destinationFilePath: info.destFilePath,downloadListKey:info.downloadListKey,md5:info.md5, isReplace: isReplace)
//        start(key: info.key, url: info.url, destinationFilePath: info.destFilePath)
    }
    
    /// 开始下载： 此方法暂时未用。 参数参考 addToStartList 方法。
    /// 调用方式用 addToStartList 和 checkToStart的组合
    /// Suggest don't use this method.
    /// Suggest use addToStartList and then checkToStart
    public func start(key:String, url:String, destinationFilePath:String, downloadListKey:String? = nil,md5:String? = nil,isReplace:Bool = false){
        
        let cacheFilePath = FilePath.getCacheFilePath(key: key)
        let destFilePath = FilePath.homeDictionary() + "/" + destinationFilePath
        
        //1.init Info
        var info:ReedInfo? = cache.get(key:key)
        if info == nil {
            info = ReedInfo(retryCount: maxRetryCount, key: key, url: url,cachePath:FilePath.getRelativeCacheFilePath(key: key),destPath:destinationFilePath,context:context,downloadListKey:downloadListKey ?? context, md5:md5)
            cache.save(info!, forKey: info!.key)
            
        }
        
        let currentInfo = info!
        
        //2、判断是否满足下载条件  Satisfy download conditions
        guard !DownloadManager.shared.isRunning(taskID: info!.key),
            currentInfo.downloadStatus != .completed,
            currentInfo.pendingCencel == false,
            currentInfo.pendingRunning == false else{
            return
        }
        
        guard hasFreeSpace(preDownloadInfo: currentInfo) else {
            return
        }
        
        //不满足下载条件，设置为等待状态 Set waiting status when not satisfy download conditions
//        guard !(self.getDownloadingCount() >= maxCount
//            && currentInfo.downloadStatus != .downloading) else {
//            waitingStatusAndPost(downloadInfo: currentInfo,isStart: false)
//            return
//        }
        

        if self.getDownloadingCount(downloadListKey: downloadListKey) >= maxCount {
            if currentInfo.downloadStatus != .downloading {
                waitingStatusAndPost(downloadInfo: currentInfo,isTryStart: false)
                return
            }
        }
        
        //3、开始下载 start downloading
        currentInfo.pendingRunning = true
        Log.i("即将下载start-- preDownloading status start")
        DispatchQueue.main.async {
             NotificationCenter.default.post(name: Noti_ReedDownload_Start, object: currentInfo, userInfo: nil)
        }
       
        if currentInfo.downloadStatus == .faild || isReplace {
            currentInfo.writedBytes = 0
            try? FileManager.default.removeItem(atPath: cacheFilePath)
            try? FileManager.default.removeItem(atPath: destFilePath)
        }
        currentInfo.downloadFailReason = nil
        
        //4,设置下载状态（应该是preDownloading,此处省略预下载状态，直接设置为下载状态）
        //Set download status to Downloading. ingore preDownloading.
        downloadingStatusAndPost(downloadInfo: currentInfo)
        
        
        //5，下载 Download
        DownloadManager.shared.start(taskID: info!.key, url: url, cacheFilePath: cacheFilePath, destinationFilePath: destFilePath, group: downloadListKey,start: { [weak self,currentInfo] (task) in
            
                Log.i("即将下载end-- preDownloading status end")
                currentInfo.pendingRunning = false
                if currentInfo.forcePause {
                    currentInfo.forcePause = false
                    self?.pause(currentInfo.key)
                }
            
            },progress: {[weak self,currentInfo] (task, progress, writedBytes, totalBytes) in

                currentInfo.writedBytes = UInt64(writedBytes)
                currentInfo.totalBytes = UInt64(totalBytes)
                currentInfo.downloadStatus = .downloading
                
                try? currentInfo.update()
                
                let currentTimeInterval = Date().timeIntervalSince1970
                if currentInfo.lastPostTimeInterval + Reed.shared.progressPostTimeInterval <= currentTimeInterval {
                    currentInfo.lastPostTimeInterval = currentTimeInterval
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: Noti_ReedDownload_Progress, object: currentInfo, userInfo: nil)
                    }
                }
                
                
            }, success: {[weak self,currentInfo,maxRetryCount] (task) in
                
                if let md5 = currentInfo.md5, !md5.isEmpty {
                    
                    if let fileMd5 = self?.md5FromFile(url: FilePath.getDestinationFilePath(relativeFilePath: currentInfo.destFilePath)),
                        fileMd5 == md5{
                        //校验成功
                        Log.i("MD5校验成功 md5 validate correct")
                        currentInfo.retryCount = maxRetryCount
                        self?.completeStatusAndPost(downloadInfo: currentInfo, isTryStart: true)

                    }else{
                        //校验失败 md5 validate incorrect
                        
                        //重试三次。（一共4次） retry 3 times
                        if currentInfo.retryCount > 0 {
                            Log.e("MD5校验剩余次数 md5 retry remain times :\(currentInfo.retryCount)，url:\(currentInfo.url)")
                            currentInfo.retryCount -= 1
                            weak var weakSelf = self
                            DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 0.1, execute: {
                                weakSelf?.start(currentInfo.key,isReplace:true)
                            })
                            
                        }else{
                            Log.e("MD5校验失败 md5 validate incorrect")
                            
                            task.delete() //停止运行，并删除文件
                            currentInfo.retryCount = maxRetryCount
                            currentInfo.writedBytes = 0
                            
                            self?.failedStatusAndPost(downloadInfo: currentInfo, reason:.md5Verification,  isTryStart: true)
                        }
                       
                    }
                
                }else{
                    currentInfo.retryCount = maxRetryCount
                    self?.completeStatusAndPost(downloadInfo: currentInfo, isTryStart: true)
                }
        
                
        }) {[weak self,currentInfo,maxRetryCount] (task, error) in

            currentInfo.pendingRunning = false
            
            if currentInfo.forcePause {
                currentInfo.forcePause = false
                self?.pause(currentInfo.key)
                return
            }

            let e = error as! NSError
            if  e.domain == NSURLErrorDomain && e.code == -999 {
                Log.e(e.localizedDescription) //取消（暂停）  cancel(pause)
                currentInfo.pendingCencel = false
                
                self?.pauseStatusAndPost(downloadInfo: currentInfo,isTryStart: false)
                
                //downloadInfo.retryCount = maxRetryCount
           
            }else if e.domain == NSURLErrorDomain && e.code == -1005{
                //网络连接已中断。（关闭wifi）-> 不做任何操作
                //offline. (close wifi)
                Log.e(e.localizedDescription)
                self?.failedStatusAndPost(downloadInfo: currentInfo, reason: .noNetwork,isTryStart: true)
            }else if e.domain == NSURLErrorDomain && e.code == -1009 {
                // 无网络情况点击下载
                // click to start download when offline
                Log.e(e.localizedDescription) //  "The Internet connection appears to be offline."
            
            }else{
                
                if e.domain == NSURLErrorDomain && e.code == -1001 {
                    Log.e(e.localizedDescription) // 超时  "The request timed out."
                    self?.failedStatusAndPost(downloadInfo: currentInfo, reason: .timeout,isTryStart: true)
                }else{
                     Log.e(e.localizedDescription) 
                    self?.failedStatusAndPost(downloadInfo: currentInfo, reason: .unknown,isTryStart: true)
                }
                

            }
            
            
        }
        
    }
    
    
    /// 开始全部
    ///
    /// - Parameter keys:
    @objc public func startBatch(keys:[String]) -> Void{
        waitingBatch(keys: keys)
    }
    
    
    /// 1,无网到有网。对应 shutdown.  1.noNetwork -> network
    /// 2.用户登录。 对应 shutdown.   2.user login
    /// 3，app启动。                 3.start up app
    /// 4,框架内部调用                4. Invoke in Reed framework( when one item's status changes)
    /// 自动检测剩余空间是否满，下载列表中最大数量是否超标，按照添加时间顺序，开始下载等待中的任务。
    /// auto check free space on device, check max download count in download list, download the waiting status tasks order add date.
    public func checkToStart(){
        var downloadListKeys = [String]()
        cache.getAll().forEach { (info) in
            if !downloadListKeys.contains(info.downloadListKey){
                downloadListKeys.append(info.downloadListKey)
            }
        }
        
        for key in downloadListKeys {
            checkToStart(downloadListKey: key)
        }
        
    }
    
    public func checkToStart(downloadListKey:String){
        
        let runningCount = self.runningCount(downloadListKey: downloadListKey)
        let downloadingInfos = self.getDownloadingInfos(downloadListKey: downloadListKey)
        let waitingInfos = self.getWaitingInfos(downloadListKey: downloadListKey)
        
        guard runningCount < maxCount else {
            return
        }
        
        //空间已满
        if hasFreeSpace() {
            
            //下载个数
            let canDownloadingInfos = downloadingInfos + waitingInfos
            
            let canStartNum = min(maxCount, canDownloadingInfos.count)
            for i in 0 ..< canStartNum  {
                let canDownloadingInfo = canDownloadingInfos[i]
                start(canDownloadingInfo.key)
            }
        }

    }
    
    //MARK: pause
    
    /// 暂停
    ///
    /// - Parameter key: <#key description#>
    public func pause(_ key:String, isTryStart:Bool? = true) -> Void {
        guard let downloadInfo = cache.get(key: key) else {
            return
        }
        
        guard downloadInfo.pendingCencel == false else {
            return
        }
        guard downloadInfo.pendingRunning == false else {
            downloadInfo.forcePause = true
            return
        }
        
        if downloadInfo.downloadStatus == .downloading && DownloadManager.shared.isRunning(taskID: key) {
            
            downloadInfo.pendingCencel = true
            //注意cancel完执行回调中的处理
            //Cancel will cost some times, after canceled ,will call some callback functions.
            DownloadManager.shared.cancel(taskID: key)
            
            pauseStatusAndPost(downloadInfo: downloadInfo, isTryStart: false)
            
            if isTryStart ?? true {
                DispatchQueue.global().asyncAfter(deadline: .now() + 0.3) { [weak self] in
                    self?.checkToStart()
                }
            }
            
        }else if downloadInfo.downloadStatus == .downloading && !DownloadManager.shared.isRunning(taskID: key) {
            
            pauseStatusAndPost(downloadInfo: downloadInfo, isTryStart: isTryStart ?? true )
        
        }else if downloadInfo.downloadStatus == .waiting{
    
            pauseStatusAndPost(downloadInfo: downloadInfo, isTryStart: isTryStart ?? true )
        }
    }
    
    @objc public func pauseForOC(key:String)->Void{
        pause(key)
    }

    /// 全部暂停
    ///
    /// - Parameter keys: <#keys description#>
    public func pauseBatch(keys:[String],isTryStart:Bool? = true){
        //  copy pause方法，最后checkToStart
        
        let infos = cache.get(keys: keys)
        infos.forEach { (downloadInfo) in
            
           pause(downloadInfo.key, isTryStart: false)
        }
        
        if isTryStart == true {
            checkToStart()
            
//            DispatchQueue.global().asyncAfter(deadline: .now() + 0.3) { [weak self] in
//                self?.checkToStart()
//            }
        }

    }
    
    @objc public func pauseBatchForOC(keys:[String]){
        pauseBatch(keys: keys)
    }

    
    //终止所有下载任务
    //用户退出； 断网；进入后台。执行
    
    /// terminate all download tasks
    /// Call this function when : user logout; no network; go to background;
    internal func shutDown(){

//        cache.getAll().forEach { (downloadInfo) in
//            DownloadManager.shared.stop(downloadInfo.url)
//        }
        DownloadManager.shared.stopAll()
        cache.clear()
        
    }

    
    /// 删除多个
    ///
    /// - Parameter keys:
    public func deleteBatch(keys:[String],isTryStart:Bool? = true) {
        
        let infos = cache.get(keys: keys)
        infos.forEach { (downloadInfo) in
            delete(downloadInfo.key,isTryStart: false)
        }
        
        if isTryStart == true{
            checkToStart()
        }
        
    }
    
    /// 删除一个
    ///
    /// - Parameter key:
    public func delete(_ key:String,isTryStart:Bool? = true){
        if let info = cache.get(key:key){
            //终止一个任务， terminate one download task, and clear its memory
            //删除下载model的内存cache。 clear memory cache of download model:
            //删除文件cache， delete file cache
            //保留不删除dest文件, keep dest file
            //删除下载model，delete download db record
            //检测下一个下载, check to start new task
            DownloadManager.shared.stop(taskID: key)
            cache.remove(key: info.key)
            FilePath.deleteCacheFile(key: info.key)
            deleteAndPost(downloadInfo: info, isTryStart: isTryStart ?? true )
        }
        
    }
    
    //MARK: waiting
    func waiting(_ key:String,isTryStart:Bool? = true) -> Void{
        
        guard let downloadInfo = cache.get(key:key) else{
            return
        }
        
        if downloadInfo.downloadStatus == .pause || downloadInfo.downloadStatus == .faild{
            DownloadManager.shared.cancel(taskID: key)
            downloadInfo.retryCount = 3
            waitingStatusAndPost(downloadInfo: downloadInfo, isTryStart: isTryStart ?? true )
            
        }
    }
    
    //copy waiting方法，最后checkToStart
    func waitingBatch(keys:[String]){
        let infos = cache.get(keys: keys)
        infos.forEach { (downloadInfo) in
            waiting(downloadInfo.key, isTryStart: false)
        }
        checkToStart()
    }
   
    /// 暂停所有未现在完成的，不启动新的下载。
    /// 未完成的包括（下载中，等待，暂停，失败）
    
    /// Pause all undone(downloading,waiting,pause,fails), not start new task
    /// - Parameter downloadListKey:
    func pauseAllUndone(downloadListKey:String? = nil){
        let undoneKeys = getDownloadProgressInfos(downloadListKey: downloadListKey).map{ $0.key}
        pauseBatch(keys: undoneKeys, isTryStart: false)
    }
    
}

extension UIDevice {
    var systemSize: Int64? {
        guard let systemAttributes = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()),
            let totalSize = (systemAttributes[.systemSize] as? NSNumber)?.int64Value else {
                return nil
                
        }
        return totalSize
        
    }
    var systemFreeSize: Int64? {
        guard let systemAttributes = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()),
            let freeSize = (systemAttributes[.systemFreeSize] as? NSNumber)?.int64Value else {
                return nil
                
        }
        return freeSize
        
    }
    
}

//    func deviceRemainingFreeSpaceInBytes() -> Int64? {
//        let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory,. userDomainMask, true).last!
//        guard
//            let systemAttributes = try? FileManager.default.attributesOfFileSystem(forPath: documentDirectory),
//            let freeSize = systemAttributes[.systemFreeSize] as? NSNumber
//            else {
//                //something failed
//                return nil
//        }
//        return freeSize.int64Value
//    }
