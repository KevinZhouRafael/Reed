//
//  KCswift
//  Example
//
//  Created by zhoukai on 2018/4/20.
//  Copyright © 2018 wumingapie@gmail.com. All rights reserved.
//

import Foundation
import ZKORM
import GRDB

public enum ReedDownloadStatus: String {
//    case pending
    case waiting // = "waiting"
    case downloading
//    case prePause
    case pause
    case completed
    case faild
}

public enum ReedDownloadFailReason:String{
    case unknown
    case timeout
    case noNetwork
    case fullSpace
    case md5Verification
}

public let DBNAME_ReedDownload  = "DBNAME_ReedDownload"

extension ReedInfo{
    public var progress:Float{
        if totalBytes == 0{
            return 0.0
        }else{
            return Float(writedBytes)/Float(totalBytes)
        }
    }
}

/// Also be called DownloadInfo in this project
public class ReedInfo: ZKORMModel {
    public var key:String = "" //算法生成（kcuuid+url）.md5
    public var url:String = ""
    public var md5:String?
    public var totalBytes:UInt64 = 0
    public var writedBytes:UInt64 = 0
    
    public var destFilePath = ""
    public var cacheFilePath = ""
    
    //上下文。每个app运行时只有一个context，如果要修改context，就要shutdown和clear。建议使用（用户唯一标识kcuuid）。该数值从Reed传来
    /// this context is same as Reed.context.
    public var context = ""
    
    //下载列表。每个context下，有多个downloadlistkey。建议使用 （用户唯一标识kcuuid+列表key）
    /// one context contains many downloadListKey. every download list has separate max download count.
    public var downloadListKey = ""
    
    private var status:String = ReedDownloadStatus.waiting.rawValue //隐藏属性 hide property
    public var downloadStatus:ReedDownloadStatus{ //暴露属性 public property
        get{
            return ReedDownloadStatus(rawValue: self.status)!
        }
        set{
            self.status = newValue.rawValue
        }
    }
    
    private var failReason:String?
    public var downloadFailReason:ReedDownloadFailReason?{
        get{
            return ReedDownloadFailReason(rawValue: (self.failReason ?? ReedDownloadFailReason.unknown.rawValue))
        }
        set{
            self.failReason = newValue?.rawValue
        }
    }
    
    //以下是瞬时属性，不做持久化
    var pendingCencel:Bool = false //即将取消（暂停）
    var pendingRunning:Bool = false //即将开始下载
    var forcePause:Bool = false //设为暂停状态。 If current download task status is predingRunning, then click pause, set forcePause true, when predingRunning end, not set running status, set pause status.
    var retryCount = 0 //重试次数 md5 retry times in a downloadlist
    var lastPostTimeInterval:TimeInterval = Date().timeIntervalSince1970
    
    override public class var isSaveDefaulttimestamp:Bool{
        return true
    }

    override public class var dbName:String?{
        return DBNAME_ReedDownload
    }

    override public func transientTypes() -> [String] {
        return ["pendingCencel","pendingRunning","retryCount","forcePause","lastPostTimeInterval"]
    }

    public override func needAddIndexProperties() -> [String] {
        return ["key","context","downloadListKey","status"]
    }
    
    init(retryCount:Int,key:String,url:String,cachePath:String,destPath:String,context:String,downloadListKey:String? = nil, md5:String? = nil) {
        self.retryCount = retryCount
        self.key = key
        self.url = url
        self.cacheFilePath = cachePath
        self.destFilePath = destPath
        self.context = context
        if let key = downloadListKey  {
            self.downloadListKey = key
        }else{
            self.downloadListKey = self.context
        }
        
        self.md5 = md5
        super.init()
    }
    
    
    public enum Columns: String, ColumnExpression,CaseIterable {
        case key
        case url
        case md5
        case totalBytes
        case writedBytes
        case destFilePath
        case cacheFilePath
        case context
        case downloadListKey
        case status
        case failReason
    }
    
    required init() {
        super.init()
    }
    
    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
    
    required init(row: Row) {
        super.init(row: row)
        key = row[Columns.key]
        url = row[Columns.url]
        md5 = row[Columns.md5]
        totalBytes = row[Columns.totalBytes]
        writedBytes = row[Columns.writedBytes]
        destFilePath = row[Columns.destFilePath]
        cacheFilePath = row[Columns.cacheFilePath]
        context = row[Columns.context]
        downloadListKey = row[Columns.downloadListKey]
        status = row[Columns.status]
        failReason = row[Columns.failReason]
    }
    
    public override func encode(to container: inout PersistenceContainer) {
        container[Columns.key] = key
        container[Columns.url] = url
        container[Columns.md5] = md5
        container[Columns.totalBytes] = totalBytes
        container[Columns.writedBytes] = writedBytes
        container[Columns.destFilePath] = destFilePath
        container[Columns.cacheFilePath] = cacheFilePath
        container[Columns.context] = context
        container[Columns.downloadListKey] = downloadListKey
        container[Columns.status] = status
        container[Columns.failReason] = failReason
        super.encode(to: &container)
    }
    
    //MARK: 重试
 /*   private var timer:Timer?
    private var timerRunNum:Int = 0
    private var queue:DispatchQueue?
    
    func retry() ->Bool{
        KCLoggerDebug("状态：\(downloadStatus.rawValue),重试次数:\(retryCount),是否正在取消：\(pendingCencel)")
        if downloadStatus == .downloading && retryCount > 0 && pendingCencel == false {
            if queue == nil {
                queue = DispatchQueue(label: key)
            }
            weak var weakself = self
            
            queue!.asyncAfter(deadline: .now() + 1, execute: {
                weakself?.startTimer()
            })
//            DispatchQueue.global().asyncAfter(deadline: .now() + 1, execute: {
//
//            })

            return true
        }else{
            return false
        }
        
    }
    
    private func startTimer(){
        if timer == nil {
            timerRunNum = 0
            timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(retryDownload), userInfo: nil, repeats: true) //只执行一次，因为runloop销毁了。
            timer?.fire()
            //                timer = Timer(timeInterval: 3, target: self, selector: #selector(retryDownload), userInfo: nil, repeats: true) //一次也不执行。
            //                RunLoop.current.add(timer!, forMode: .commonModes)
        }
    }
    //跳过第一次的立即执行，只执行第二次
    @objc private func retryDownload(){
//        timerRunNum += 1
//        if timerRunNum == 2 {
            weak var weakself = self
            DispatchQueue.global().async {
                weakself?.download()
            }
//        }
        
    }
    
    private func download(){
        Log.e("下载重试：\(url),第\(Reed.shared.retryCount - retryCount + 1)次。")
        Reed.shared.startDownload(url)
        retryCount = retryCount - 1
        timer?.invalidate()
        timer = nil
        timerRunNum = 0
    }
 */
    
}
