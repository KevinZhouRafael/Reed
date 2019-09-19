//
//  DownloadRequest.swift
//  Reed
//
//  Created by kai zhou on 07/12/2016.
//  Copyright © 2016 kevin. All rights reserved.

//->ready: Returns true to indicate that the operation is ready to execute, or false if there are still unfinished initialization steps on which it is dependent.
//->executing: Returns true if the operation is currently working on its task, or false otherwise.
//->finished Returns true if the operation’s task finished execution successfully, or if the operation was cancelled. An NSOperationQueue does not dequeue an operation until finished changes to true, so it is critical to implement this correctly in subclasses to avoid deadlock.
//

import UIKit

public typealias DownloadTaskStartHandler = (_ task:DownloadTask) -> ()
public typealias DownloadTaskProgressHandler = ( _ task:DownloadTask, _ progress:Float,_ writedBytes:Int64,_ totalBytes:Int64) -> ()
public typealias DownloadTaskFailHandler = (_ task:DownloadTask,_ error:Error) -> ()
public typealias DownloadTaskSuccessHandler = (_ task:DownloadTask) -> ()


/// 下载任务对象
/// Download task object
public class DownloadTask:NSObject {

    private var dataTask : URLSessionDataTask?
    private var outputStream : OutputStream?

    
    var taskID:String = ""
    var group:String?
    var urlString:String = ""
    var destFilePath = ""
    var cacheFilePath = ""
    
    var fileName:String = "" //用于打印 use to pring
    
    /// true：not execute failedHandler callback.
    /// false：execute failedHandler callback.
    var isCantnotCallback:Bool = false
    
    private var progress: Progress = Progress()
    
    private var startHandler:DownloadTaskStartHandler?
    private var progressHandler:DownloadTaskProgressHandler?
    private var failedHandler:DownloadTaskFailHandler?
    private var successHandler:DownloadTaskSuccessHandler?
    
    lazy var session:URLSession = {
        let configuration = URLSessionConfiguration.default
        let session = URLSession(configuration: configuration, delegate: DownloadManager.shared.delegate, delegateQueue: OperationQueue.main)
        return session
    }()
    
//    public func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
//        print("didBecomeInvalidWithError:\(error)")
//    }
//
    
    public init(taskID:String) {
        self.taskID = taskID
        super.init()
    }
    // MARK: 控制
    public func start(urlString:String,
                      cacheFilePath:String,
                      destFilePath:String,
                      group:String? = nil,
                      startHandler:@escaping DownloadTaskStartHandler,
                      progressHandler:@escaping DownloadTaskProgressHandler,
                      successHandler:@escaping DownloadTaskSuccessHandler,
                      failHandler:@escaping DownloadTaskFailHandler) {
        
        self.urlString = urlString
        self.cacheFilePath = cacheFilePath
        self.destFilePath = destFilePath
        self.group = group
        self.startHandler = startHandler
        self.progressHandler = progressHandler
        self.successHandler = successHandler
        self.failedHandler = failHandler
        
        self.fileName = String(urlString.split(separator: "/").last!.split(separator: ".").first!)
        
        
        
        FilePath.checkOrCreateFile(filePath: cacheFilePath)
        
        let cacheFileSize = getFileSize(cacheFilePath: cacheFilePath)
        let urlEncodingString = self.urlString.addingPercentEncoding(withAllowedCharacters:NSCharacterSet.urlQueryAllowed)
        let url = URL(string: urlEncodingString!)!
        
        var request = URLRequest(url: url)
        request.timeoutInterval = DownloadManager.shared.timeoutInterval
        request.setValue("bytes=\(cacheFileSize)-", forHTTPHeaderField: "Range")
        
//        if dataTask == nil {
            if DownloadManager.shared.isMultiSession {
                dataTask = session.dataTask(with: request) //单独session，包含单独的一个task。超时的几率大大降低。
            }else{
                dataTask = DownloadManager.shared.session.dataTask(with: request) //容易超时
            }
//        }
        
        dataTask?.taskID = self.taskID
        dataTask!.resume()
        
        progress.setUserInfoObject(progress.completedUnitCount, forKey: .fileCompletedCountKey)

    }


    
    public func suspend(){
        dataTask?.suspend()
    }
    
    public func resume(){
        dataTask?.resume()
    }
    
    public func cancel(){
        dataTask?.cancel()
    }
    
    public func stop(){
        isCantnotCallback = true
        dataTask?.cancel()
//        session.finishTasksAndInvalidate()
//        dataTask = nil
    }
    
    ///停止运行，并且删除文件
    public func delete(){
        stop()
        if(FileManager.default.fileExists(atPath: destFilePath)){
            try? FileManager.default.removeItem(atPath: destFilePath)
        }
        if(FileManager.default.fileExists(atPath: cacheFilePath)){
            try? FileManager.default.removeItem(atPath: cacheFilePath)
        }
    }
    
    // MARK: 状态
    public var state:URLSessionTask.State?{
        get{
            if let task = dataTask{
                return task.state
            }else{
                return nil
            }
        }
    }
    
    public var isRunning:Bool{
        get{
            return state == .running
        }
    }
    
    public var isSuspended:Bool{
        get{
            return state == .suspended
        }
    }
    
    public var isCanceling:Bool{
        return state == .canceling
    }
    
    public var isCompleted:Bool{
        return state == .completed
    }
}

// MARK: - download callback
extension DownloadTask:URLSessionDataDelegate {
    
     /// 下载前检测
     public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        
        progress.completedUnitCount = 0
        progress.totalUnitCount = 0
        

        
        var contentLength:Int64 = 0
        if let response = response as? HTTPURLResponse,
            let contentLengthString = response.allHeaderFields["Content-Length"] as? String,
            let contentLengthBytes = Int64(contentLengthString) {
            contentLength = contentLengthBytes
        }
        
        var breakPoint:Int64 = 0
        //"bytes=24393258-"
        if let rangeHeader = dataTask.currentRequest?.allHTTPHeaderFields!["Range"]{
            let index = rangeHeader.index(rangeHeader.startIndex, offsetBy:6)
            let endIndex = rangeHeader.firstIndex(of: "-")
            breakPoint = Int64(rangeHeader[index..<endIndex!])!
        }
        
        Log.i("已下载文件大小Downloaded file size ：\(breakPoint), content-Lenght: \(contentLength)")
        progress.completedUnitCount = breakPoint
        progress.totalUnitCount = breakPoint + contentLength
        

        outputStream = OutputStream(toFileAtPath: cacheFilePath, append: true)
        outputStream?.open()
        
        
        completionHandler(.allow)
        
        Log.i("开始下载Start Download: \(String(describing: dataTask.currentRequest?.url?.absoluteString))")
        startHandler?(self)
        
    }
    
    //下载进度
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        
        progress.completedUnitCount += Int64((data as NSData).length)
        _ = data.withUnsafeBytes { outputStream?.write($0.baseAddress!.assumingMemoryBound(to: UInt8.self), maxLength: data.count) }
//        _ = data.withUnsafeBytes { outputStream?.write($0, maxLength: data.count) }
        
//        let s = String(format: "下载进度-- url=\(urlString) \n  , 已下载\(progress.completedUnitCount), 总大小\(progress.totalUnitCount)， %.2f", progress.fractionCompleted * 100)
        let s = String(format: "下载url: \(fileName) , 下载量completedUnitCount/totalUnitCount: \(progress.completedUnitCount)/\(progress.totalUnitCount)， 进度progress,%.2f%%", progress.fractionCompleted * 100)
        Log.d(s)
        

        progressHandler?(self,Float(progress.fractionCompleted),progress.completedUnitCount,progress.totalUnitCount)
        
    }
    
}

extension DownloadTask:URLSessionTaskDelegate{
    //下载完成
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        
        outputStream?.close()
        outputStream = nil
        
        
        if let e = error as? NSError {
            
            if e.domain == NSURLErrorDomain && e.code == -999{
                
                //用户取消不做任何操作. do nothings when user cancel this task
                if isCantnotCallback {
                    isCantnotCallback = false
                    return
                }
                
                Log.e("Download failed-\(urlString)--Cancel: \(e)")
            }else if e.domain == NSURLErrorDomain && e.code == -1001 {
                Log.e("Download failed-\(urlString)--Time Out: \(e)") // "The request timed out."
            }else if e.domain == NSURLErrorDomain && e.code == -1009 {
                Log.e("Download failed-\(urlString)--no network: \(e)") // "似乎已断开与互联网的连接。","The Internet connection appears to be offline." ---无网络情况，点击下载。
            }else if e.domain == NSURLErrorDomain && e.code == -1005 {
                Log.e("Download failed-\(urlString)--offline-close the wifi: \(e)") // "网络连接已中断。" --关闭wifi。
            }else{
                Log.e("Download failed-\(urlString)--error: \(e)")
            }
            
            isCantnotCallback = false
            
            failedHandler?(self,error!)
        } else {
            
            isCantnotCallback = false
            
            do {
                if(FileManager.default.fileExists(atPath: destFilePath)){
                    try FileManager.default.removeItem(atPath: destFilePath)
                }
                try FileManager.default.moveItem(atPath: cacheFilePath, toPath: destFilePath)
                
                Log.i("Download Complete-\(urlString), saved path：\(destFilePath)")
                
                successHandler?(self)
                
            }catch let error as NSError{
                Log.e("Download failed--\(urlString)--error relate file--\(error)")
        
                //NSCocoaErrorDomain, code=513
//                Error Domain=NSCocoaErrorDomain Code=513 "“afc5b25cd2f0f9dbe8d246ebc22b52a4” couldn’t be moved because you don’t have permission to access “Macintosh HD”." UserInfo={NSSourceFilePathErrorKey=/Users/zhoukai/Library/Developer/CoreSimulator/Devices/0428D5B1-8FF3-46F8-8C0C-06177F5647E4/data/Containers/Data/Application/1CD71B03-7AC9-409B-81CD-ED99B28CFF55/Library/Caches/temp/afc5b25cd2f0f9dbe8d246ebc22b52a4, NSUserStringVariant=(
//                    Move
//                    ), NSDestinationFilePath=/kc_116_1496632449521.pdf, NSFilePath=/Users/zhoukai/Library/Developer/CoreSimulator/Devices/0428D5B1-8FF3-46F8-8C0C-06177F5647E4/data/Containers/Data/Application/1CD71B03-7AC9-409B-81CD-ED99B28CFF55/Library/Caches/temp/afc5b25cd2f0f9dbe8d246ebc22b52a4, NSUnderlyingError=0x60800005a790 {Error Domain=NSPOSIXErrorDomain Code=13 "Permission denied"}}

               failedHandler?(self,error)
            }

        }
        
//        self.dataTask = nil
    }
}

private var URLSessionTask_TaskIdentifier:String = "URLSessionTask_TaskIdentifier"
extension URLSessionTask{
    var taskID:String?{
        set{
            objc_setAssociatedObject(self, &URLSessionTask_TaskIdentifier, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get{
            return objc_getAssociatedObject(self, &URLSessionTask_TaskIdentifier) as? String
        }
    }
}


/* 返回值
 public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void)
 
// print(dataTask.currentRequest?.allHTTPHeaderFields!)
 
// Optional<Dictionary<String, String>>
 //"Accept-Language" : "en-us"
 //"Range" : "bytes=4584804-"
 //"Accept": "*//*"
 //"Accept-Encoding" : "gzip, deflate"

 print(response)
 
<NSHTTPURLResponse: 0x60c00003fc40> { URL: http://kaochong.cdn.bcebos.com/web/material/116/kc_116_1492422464362.mp3 } { Status Code: 206, Headers {
    "Accept-Ranges" =     (
    bytes
    );
    Age =     (
    1158
    );
    Connection =     (
    "keep-alive"
    );
    "Content-Disposition" =     (
    "attachment;filename=\"%E9%80%9F%E5%BA%A6%E8%A7%A3%E5%86%B3%20stage%201.mp3\";filename*=UTF-8''%E9%80%9F%E5%BA%A6%E8%A7%A3%E5%86%B3%20stage%201.mp3"
    );
    "Content-Length" =     (
    10255172
    );
    "Content-Range" =     (
    "bytes 4584804-14839975/14839976"
    );
    "Content-Type" =     (
    "audio/mp3; charset=UTF-8"
    );
    Date =     (
    "Tue, 17 Apr 2018 08:53:50 GMT"
    );
    Etag =     (
    "\"-0c1cfd9bf4e41747aa8bbf0e7b9233c6\""
    );
    Expires =     (
    "Fri, 20 Apr 2018 07:51:25 GMT"
    );
    "Last-Modified" =     (
    "Mon, 17 Apr 2017 10:35:08 GMT"
    );
    "Ohc-File-Size" =     (
    14839976
    );
    Server =     (
    "JSP3/2.0.14"
    );
    "Timing-Allow-Origin" =     (
    "*"
    );
    "x-bce-debug-id" =     (
    "LQNmMeRLzNLtNtm8X4gF1wj0YiVCipvS+kLgm9KDRX3lk+om9CFxxL+gzfv6J+wASExqz9GgY1IZO1wXGCzPhQ=="
    );
    "x-bce-request-id" =     (
    "9df85ac5-c1dd-4eb4-8589-4eda1f500e52"
    );
    "x-bce-storage-class" =     (
    STANDARD
    );
} }
*/
