//
//  FilePath+Reed.swift
//  Reed
//
//  Created by zhoukai on 2018/4/26.
//  Copyright © 2018 kai zhou. All rights reserved.
//

import Foundation
public extension FilePath{
    static func getDownloadDBPath() -> String {
        let dbPath = documentDictionary() + "/ActiveSQLite_DBNAME_ReedDownload.db"
        FilePath.checkOrCreateFile(filePath: dbPath)
        return dbPath
    }
    
    static func getCacheFilePath(key:String) -> String{
        let tempDic = FilePath.cacheDictionary() + "/temp"
        FilePath.checkOrCreateDic(dicPath: tempDic)
        let cachePath = tempDic + "/" + key
        return cachePath
    }
    
    static func getRelativeCacheFilePath(key:String) -> String{
        let tempDic = FilePath.cacheDictionary() + "/temp"
        FilePath.checkOrCreateDic(dicPath: tempDic)
        
        return "Library/Caches/temp/\(key)"
    }
    
    static func getDestinationFilePath(relativeFilePath:String) -> String{
        let destinationPath = homeDictionary() + "/" + relativeFilePath
        return destinationPath
    }
    
    @discardableResult
    static func deleteCacheFile(key:String) -> Bool{
        let cacheFilePath = getCacheFilePath(key: key)
        do{
            try FileManager.default.removeItem(atPath: cacheFilePath)
            return true
        }catch {
            return false
        }
    }
//    static func getDestinationFilePathTest(fileName:String) -> String{
//        let destDic = FilePath.cacheDictionary() + "/dest"
//        FilePath.checkOrCreateDic(withPath: destDic)
//
//        let destinationPath = destDic + "/" + fileName
//        return destinationPath
//    }
}
