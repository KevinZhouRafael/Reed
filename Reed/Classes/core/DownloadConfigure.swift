//
//  DownloadConfigure.swift
//  Reed
//
//  Created by zhoukai on 2018/4/12.
//  Copyright © 2018 kai zhou. All rights reserved.
//

import Foundation

/// 暴露key的算法给外部。key algorithm.
//public protocol URLToKeyProtocol:class {
//    func urlToKey(url:String) -> String
//}
//
//public class DownloadConfigure {
//    public static let shared:DownloadConfigure = DownloadConfigure()
//
//    public weak var delegate:URLToKeyProtocol?
//
//
//    public func urlToKey(url:String) -> String {
//        if delegate != nil{
//            return delegate!.urlToKey(url: url)
//        }else{
//            return url
//        }
//    }
//
//}


public func getFileSize(cacheFilePath:String)->Int64{
    var fileSize:Int64 = 0
    //try resumeData = Data(contentsOf: URL(fileURLWithPath:resumeDataPath))
    if let fileInfo = try? FileManager().attributesOfItem(atPath: cacheFilePath),
        let fileLength = fileInfo[.size] as? Int64{
        let createdData = fileInfo[.creationDate] as! Date
        let modificationDate = fileInfo[.modificationDate] as! Date
        
        Log.i("Downloaded file：size:\(fileLength), created date:\(createdData), modify date：\(modificationDate)")
        fileSize = fileLength
    }
    return fileSize
}

