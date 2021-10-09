//
//  FilePath.swift
// Reed
//
//  Created by zhoukai on 2018/4/16.
//  Copyright © 2018 wumingapie@gmail.com. All rights reserved.
//

import Foundation
public struct FilePath{
    
    //./
    public static func homeDictionary() -> String{
        return NSHomeDirectory()
    }

    // ./Documents
    public static func documentDictionary() -> String{
        return  NSSearchPathForDirectoriesInDomains(.documentDirectory,.userDomainMask, true).first!
    }

    // ./Library
    public static func libraryDictionary() -> String{
        return  NSSearchPathForDirectoriesInDomains(.libraryDirectory,.userDomainMask, true).first!
    }
    
    // ./Library/Caches
    public static func cacheDictionary() -> String{
        return NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!
    }
    
    // ./Library/Application Support
    public static func applicationSupportDictionary() -> String{
        return  NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory,.userDomainMask, true).first!
    }
    
    // ./Library/Preferences -> UserDefault
    
    //./tmp
    public static func tempDictionary() -> String {
        return NSTemporaryDirectory()
    }
    
    // bundle -> Bundle.main
}

public extension FilePath{
    @discardableResult
    static func checkOrCreateDic(dicPath:String) -> Bool {
        var isDir:ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: dicPath, isDirectory: &isDir)
        if exists && isDir.boolValue {
            return true
        }else{
            do{
                try FileManager.default.createDirectory(at:URL(fileURLWithPath: dicPath, isDirectory: true), withIntermediateDirectories: true, attributes: nil)
            }catch{
                return false
            }
            return true
        }
    }
    
    static func checkOrCreateFile(filePath:String){
        if !FileManager.default.fileExists(atPath: filePath) {
            FileManager.default.createFile(atPath: filePath, contents: nil, attributes: nil)
        }
    }
}
