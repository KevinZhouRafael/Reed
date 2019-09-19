//
//  DownloadDelegate.swift
// Reed
//
//  Created by zhoukai on 2018/4/12.
//  Copyright © 2018 wumingapie@gmail.com. All rights reserved.
//

import Foundation
class DownloadTaskDelegate:NSObject {
    private weak var manager: DownloadManager?
    init(_ manager:DownloadManager) {
        self.manager = manager
    }
    
}

extension DownloadTaskDelegate:URLSessionDataDelegate {
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        guard let manager = manager,
            
//            let urlString = dataTask.originalRequest?.url?.absoluteString,
//            let downloadTask = manager.findTask(urlString),
            let taskID = dataTask.taskID,
            let downloadTask = manager.findTask(taskID: taskID),
            let response = response as? HTTPURLResponse else {
                return
        }
//        调试日志 Debug Logger
//        if #available(iOS 9.0, *) {
//            DownloadManager.shared.session.getAllTasks { (tasks) in
//                Log.i("Start Download：getAllTasks：\(tasks)")
//            }
//        } else {
//            // Fallback on earlier versions
//        }
//        DownloadManager.shared.session.getTasksWithCompletionHandler({ (dataTasks, uploadTasks, downloadTasks) in
//            Log.i("Start Download：getTasksWithCompletionHandler in success：\(dataTasks)")
//        })
        downloadTask.urlSession(session, dataTask: dataTask, didReceive: response, completionHandler: completionHandler)
    }

    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let manager = manager,
//            let urlString = dataTask.originalRequest?.url?.absoluteString,
//            let downloadTask = manager.findTask(urlString)
            let taskID = dataTask.taskID,
            let downloadTask = manager.findTask(taskID: taskID) else {
                return
        }
//        调试日志 Debug Logger
//        if #available(iOS 9.0, *) {
//            DownloadManager.shared.session.getAllTasks { (tasks) in
//                Log.i("Download progress：getAllTasks：\(tasks)")
//            }
//        } else {
//            // Fallback on earlier versions
//        }
//        DownloadManager.shared.session.getTasksWithCompletionHandler({ (dataTasks, uploadTasks, downloadTasks) in
//            Log.i("Download progress：getTasksWithCompletionHandler in success：\(dataTasks)")
//        })
        downloadTask.urlSession(session, dataTask: dataTask, didReceive: data)
    }


}

extension  DownloadTaskDelegate:URLSessionTaskDelegate{
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let manager = manager,
//            let urlString = task.originalRequest?.url?.absoluteString,
//            let downloadTask = manager.findTask(urlString),
        let taskID = task.taskID,
        let downloadTask = manager.findTask(taskID: taskID)else {
                return
        }
//        if #available(iOS 9.0, *) {
//            DownloadManager.shared.session.getAllTasks { (tasks) in
//                Log.i("Download Complete：getAllTasks：\(tasks)")
//            }
//        } else {
//            // Fallback on earlier versions
//        }
//        DownloadManager.shared.session.getTasksWithCompletionHandler({ (dataTasks, uploadTasks, downloadTasks) in
//            Log.i("Download Complete：getTasksWithCompletionHandler in success：\(dataTasks)")
//        })
        downloadTask.urlSession(session, task: task, didCompleteWithError: error)
        
        manager.remove(taskID: taskID)
    }
}
