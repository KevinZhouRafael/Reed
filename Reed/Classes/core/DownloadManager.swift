//
//  DownloadManager.swift
//  Reed
//
//  Created by kai zhou on 06/12/2016.
//  Copyright © 2016 kevin. All rights reserved.
//

import UIKit

public class DownloadManager:NSObject {
    
    static public let shared:DownloadManager = DownloadManager()
    private override init() {

        super.init()
        
        var attr = pthread_mutexattr_t()
        pthread_mutexattr_init(&attr)
        pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_RECURSIVE)
        pthread_mutex_init(&mutex, &attr)
        pthread_mutexattr_destroy(&attr)
    }
    
    deinit {
        pthread_mutex_destroy(&mutex)
    }
    
    lazy var delegate:DownloadTaskDelegate = {
        return DownloadTaskDelegate(self)
    }()
    
    public var timeoutInterval:TimeInterval = 20
    var isMultiSession:Bool = true //not use signal configuration
    public var needUrlEncoding:Bool = true
    
//    private  let queue: DispatchQueue = DispatchQueue(label: "com.kaochong.download.queue")

    private  var tasksDic:Dictionary<String,DownloadTask> = Dictionary<String,DownloadTask>() // [taskID : DownloadTask]
    
    private var mutex:pthread_mutex_t = pthread_mutex_t()
    
    lazy var session:URLSession = {
        let configuration = URLSessionConfiguration.default
//        configuration.httpMaximumConnectionsPerHost = 2
//        configuration.timeoutIntervalForResource = 60
        let session = URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
        return session
    }()
    
    
    //MARK: CRUD task
    func getTask(taskID:String) -> DownloadTask {
        pthread_mutex_lock(&mutex)
        defer {pthread_mutex_unlock(&mutex)}
        var task = tasksDic[taskID]
        if task == nil {
           add(taskID:taskID)
           task = tasksDic[taskID]
        }
        return task!
    }
    func findTask(taskID: String) -> DownloadTask? {
        pthread_mutex_lock(&mutex)
        defer {pthread_mutex_unlock(&mutex)}
        return tasksDic[taskID]
    }
    
    
    func add(taskID:String){
        pthread_mutex_lock(&mutex)
        defer {pthread_mutex_unlock(&mutex)}
        tasksDic[taskID] = DownloadTask(taskID: taskID)
    }
    
    func remove(taskID:String){
        pthread_mutex_lock(&mutex)
        defer {pthread_mutex_unlock(&mutex)}
        if let task = tasksDic[taskID]{
            task.stop()
        }
        tasksDic[taskID] = nil
    }
    
    func removeAll(){
        pthread_mutex_lock(&mutex)
        defer {pthread_mutex_unlock(&mutex)}
        
        tasksDic.forEach { (taskID,task) in
            remove(taskID:taskID)
        }
    }
    
    //MARK: Download Control
    public  func start(taskID:String,
                       url:String,
                       cacheFilePath:String,
                       destinationFilePath:String,
                       group:String? = nil,
                       start:@escaping DownloadTaskStartHandler,
                       progress:@escaping DownloadTaskProgressHandler,
                       success:@escaping DownloadTaskSuccessHandler,
                       fails:@escaping DownloadTaskFailHandler) {
        
        let downloadTask = getTask(taskID:taskID)
        downloadTask.start(urlString: url,
                           cacheFilePath: cacheFilePath,
                           destFilePath: destinationFilePath,
                           group: group,
                           startHandler: start,
                           progressHandler:progress,
                           successHandler:success,
                           failHandler:fails)
        
    }

    
    public func remumeAll(){
        pthread_mutex_lock(&mutex)
        defer {pthread_mutex_unlock(&mutex)}
        
        tasksDic.forEach { (taskID,task) in
            task.resume()
        }
    }
    
    public  func suspend(taskID:String){
        pthread_mutex_lock(&mutex)
        defer {pthread_mutex_unlock(&mutex)}
        
        tasksDic[taskID]?.suspend()
    }
    
    
    public  func suspendAll(){
        pthread_mutex_lock(&mutex)
        defer {pthread_mutex_unlock(&mutex)}
        
        tasksDic
//            .filter { (url,task) -> Bool in
//                return task.state == .running
//            }
            .forEach { (taskID,task) in
                task.suspend()
            }
    }
    
    public func cancel(taskID:String){
        pthread_mutex_lock(&mutex)
        defer {pthread_mutex_unlock(&mutex)}
        
        tasksDic[taskID]?.cancel()
    }
    
    public func cancelAll(){
        pthread_mutex_lock(&mutex)
        defer {pthread_mutex_unlock(&mutex)}
        
        tasksDic.forEach { (taskID,task) in
            task.cancel()
        }
    }
    
    public func stop(taskID:String){
        pthread_mutex_lock(&mutex)
        defer {pthread_mutex_unlock(&mutex)}
        
        tasksDic[taskID]?.stop()
        tasksDic[taskID] = nil
    }
    
    public func stopAll(){
        pthread_mutex_lock(&mutex)
        defer {pthread_mutex_unlock(&mutex)}
        
        tasksDic.forEach { (taskID,task) in
//            task.stop()
            stop(taskID:taskID)
        }
        tasksDic = [String:DownloadTask]()
    }
    
    public func delete(taskID:String){
        pthread_mutex_lock(&mutex)
        defer {pthread_mutex_unlock(&mutex)}
        
        tasksDic[taskID]?.delete()
        tasksDic[taskID] = nil
    }
    
    public func deleteAll(){
        pthread_mutex_lock(&mutex)
        defer {pthread_mutex_unlock(&mutex)}
                
        tasksDic.forEach { (taskID,task) in
            task.delete()
        }
        tasksDic = [String:DownloadTask]()
    }
    
    //MARK: Status
    public func isRunning(taskID:String)->Bool{

        pthread_mutex_lock(&mutex)
        defer {pthread_mutex_unlock(&mutex)}
        
        guard let task = tasksDic[taskID] else {
            return false
        }
        return task.isRunning
    }

    public func isSuspended(taskID:String)->Bool{
        pthread_mutex_lock(&mutex)
        defer {pthread_mutex_unlock(&mutex)}
        
        guard let task = tasksDic[taskID] else {
            return false
        }
        return task.isSuspended
    }
    
    public func isCanceling(taskID:String)->Bool{
        pthread_mutex_lock(&mutex)
        defer {pthread_mutex_unlock(&mutex)}
        
        guard let task = tasksDic[taskID] else {
            return false
        }
        return task.isCanceling
    }
    
    public func isCompleted(taskID:String)->Bool{
        pthread_mutex_lock(&mutex)
        defer {pthread_mutex_unlock(&mutex)}
        
        guard let task = tasksDic[taskID] else {
            return false
        }
        return task.isCompleted
    }
    
    
    /// 获取下载中的所有唯一标识符
    /// Get identifiers of all running status infos
    public func runningIdentifiers() -> [String]{

        pthread_mutex_lock(&mutex)
        defer {pthread_mutex_unlock(&mutex)}
        
        return tasksDic.filter { (value) -> Bool in
                let (_, task) = value
                return task.isRunning
            }.map({ ( value ) -> String in
                
                let (taskID, _) = value
                return taskID
            })
    }
    
    /// 获取下载中的个数
    /// get count of running status
    public func runningCount(group:String? = nil) -> Int{
        pthread_mutex_lock(&mutex)
        defer {pthread_mutex_unlock(&mutex)}
        
        if group != nil {
            return tasksDic.reduce(0) { (result, value) -> Int in
                
                let (_, task) = value
                return result + (task.isRunning && task.group == group ? 1:0)
            }
        }else{
            return tasksDic.reduce(0) { (result, value) -> Int in
                
                let (_, task) = value
                return result + (task.isRunning ? 1:0)
            }
        }

    }
    
}

