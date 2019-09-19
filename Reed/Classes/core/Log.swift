//
//  Log.swift
//  Reed
//
//  Created by Kevin on 2019/9/18.
//  Copyright © 2019 kai zhou. All rights reserved.
//

import Foundation
import CocoaLumberjack

class Log{
    static var showLogger:Bool = true
    
    static func config(level:DDLogLevel? = .info, timeFormatter:(()->String)? = nil){
        let timeFF = timeFormatter ?? timeFormatterFunction
        DDTTYLogger.sharedInstance.logFormatter = LoggerFormatter(timeFF)
        DDLog.add(DDTTYLogger.sharedInstance, with: level ?? .info) // TTY = Xcode console

        //    DDTTYLogger.sharedInstance.colorsEnabled = true
        //    DDLog.add(DDASLLogger.sharedInstance) // ASL = Apple System Logs
        
        let fileLogger = DDFileLogger()
        fileLogger.logFormatter = LoggerFormatter(timeFormatter)
        fileLogger.rollingFrequency = TimeInterval(60*60*4) //4小时一个日志文件
        fileLogger.logFileManager.maximumNumberOfLogFiles = 18 //3天一共产生18个文件
        DDLog.add(fileLogger, with: .info)
        
    }
    
    static let TimestampDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(abbreviation: "GMT+0800")
        return formatter
    }()
    static var timeFormatterFunction:(()->String) = {
//        let currentServerDate = Date.init(timeIntervalSince1970: KCNetworkCurrentTime.now())
        let currentServerDate = Date()
        return TimestampDateFormatter.string(from: currentServerDate)
    }
    
    
    /// 日志级别：verbose
    static func v(_ message:  Any?,tag:String? = nil,
                         file: StaticString = #file, line: UInt = #line,function: StaticString = #function) {
        
        v(format:"%@", String(describing: message),tag:tag,file:file,line:line,function:function)
    }
    static func v(_ message:  String,tag:String? = nil,
                         file: StaticString = #file,line: UInt = #line,function: StaticString = #function) {
        
        v(format:"%@", message,tag:tag,file:file,line:line,function:function)
    }
    
    static func v(_ message:  String ...,tag:String? = nil,
                         file: StaticString = #file,line: UInt = #line,function: StaticString = #function) {
        
        v(format:"%@", message.reduce("",{$0 + $1 + " "}),tag:tag,file:file,line:line,function:function)
    }
    
    static func v(format:  @autoclosure () -> String, _ arguments: CVarArg...,tag:String? = nil,
                         file: StaticString = #file, line: UInt = #line,function: StaticString = #function) {
        
        DDLogVerbose((tag != nil ? "tag:\(tag!) ": "") + String(format: format(), arguments: arguments),file:file,function:function, line:line)
    }
    
    /// 日志级别：debug
    static func d(_ message:  Any?,tag:String? = nil,
                         file: StaticString = #file,line: UInt = #line,function: StaticString = #function) {
        
        d(format:"%@", String(describing: message),tag:tag,file:file,line:line,function:function)
    }
    static func d(_ message:  String,tag:String? = nil,
                         file: StaticString = #file,line: UInt = #line,function: StaticString = #function) {
        
        d(format:"%@", message,tag:tag,file:file,line:line,function:function)
    }
    
    static func d(_ message:  String ...,tag:String? = nil,
                         file: StaticString = #file,line: UInt = #line,function: StaticString = #function) {
        
        d(format:"%@", message.reduce("",{$0 + $1 + " "}),tag:tag,file:file,line:line,function:function)
    }
    
    static func d(format:  @autoclosure () -> String, _ arguments: CVarArg...,tag:String? = nil,
                        file: StaticString = #file,line: UInt = #line,function: StaticString = #function) {
        DDLogDebug((tag != nil ? "tag:\(tag!) ": "") + String(format: format(), arguments: arguments),file:file,function:function, line:line)
    }
    

    /// 日志级别：info
    static func i(_ message:  Any?,tag: String? = nil,
                         file: StaticString = #file,line: UInt = #line,function: StaticString = #function) {
        i(format:"%@", String(describing: message),tag:tag,file:file,line:line,function:function)
    }
    
    static func i(_ message:  String,tag:String? = nil,
                         file: StaticString = #file,line: UInt = #line,function: StaticString = #function) {
        
        i(format:"%@", message,tag:tag,file:file,line:line,function:function)
    }
    
    static func i(_ message:  String ..., tag: String? = nil,
                         file: StaticString = #file,line: UInt = #line,function: StaticString = #function) {
        
        i(format:"%@", message.reduce("",{$0 + $1 + " "}),tag:tag,file:file,line:line,function:function)
    }
    
    
    static func i(format:  @autoclosure () -> String, _ arguments: CVarArg...,tag:String? = nil,
                         file: StaticString = #file,line: UInt = #line,function: StaticString = #function) {
        
        DDLogInfo((tag != nil ? "tag:\(tag!) ": "") + String(format: format(), arguments: arguments),file:file,function:function, line:line)
    }
    
    /// 日志级别：warn
    static func w(_ message:  Any?,tag:String? = nil,
                         file: StaticString = #file,line: UInt = #line,function: StaticString = #function) {
        w(format:"%@", String(describing: message),tag:tag,file:file,line:line,function:function)
    }
    
    static func w(_ message:  String,tag:String? = nil,
                         file: StaticString = #file,line: UInt = #line,function: StaticString = #function) {
        
        w(format:"%@", message,tag:tag,file:file,line:line,function:function)
    }
    
    static func w(_ message:  String ...,tag:String? = nil,
                         file: StaticString = #file,line: UInt = #line,function: StaticString = #function) {
        
        w(format:"%@", message.reduce("",{$0 + $1 + " "}),tag:tag,file:file,line:line,function:function)
    }
    
    static func w(format:  @autoclosure () -> String, _ arguments: CVarArg...,tag:String? = nil,
                         file: StaticString = #file,line: UInt = #line,function: StaticString = #function) {
        
        DDLogWarn((tag != nil ? "tag:\(tag!) ": "") + String(format: format(), arguments: arguments),file:file,function:function, line:line)
    }
    
    /// 日志级别：error
    static func e(_ message: Any?,tag:String? = nil,
                         file: StaticString = #file,line: UInt = #line,function: StaticString = #function) {
        
        e(format:"%@", String(describing: message),tag:tag,file:file,line:line,function:function)
    }
    
    static func e(_ message:  String,tag:String? = nil,
                         file: StaticString = #file,line: UInt = #line,function: StaticString = #function) {
        
        e(format:"%@", message,tag:tag,file:file,line:line,function:function)
    }
    
    static func e(_ message:  String ...,tag:String? = nil,
                         file: StaticString = #file,line: UInt = #line,function: StaticString = #function) {
        
        e(format:"%@", message.reduce("",{$0 + $1 + " "}),tag:tag,file:file,line:line,function:function)
    }
    
    static func e(format:  @autoclosure () -> String, _ arguments: CVarArg...,tag:String? = nil,
                         file: StaticString = #file,line: UInt = #line,function: StaticString = #function) {
        
        DDLogError((tag != nil ? "tag:\(tag!) ": "") + String(format: format(), arguments: arguments),file:file,function:function, line:line)
    }
    
    static func name(of file:String) -> String {
        return URL(fileURLWithPath: file).lastPathComponent
    }

}

class LoggerFormatter:NSObject, DDLogFormatter {
    
    var timeFormatter:(()->String)?
    init(_ timeFormatter:(()->String)? = nil) {
        self.timeFormatter = timeFormatter
        super.init()
    }
    
    func format(message logMessage: DDLogMessage) -> String? {
        var logLevel = ""
        switch logMessage.flag {
        case .verbose:
            logLevel = "v"
            break
        case .debug:
            logLevel = "d"
            break
        case .info:
            logLevel = "i"
            break
        case .warning:
            logLevel = "w"
            break
        case .error:
            logLevel = "e"
            break
        default:
            logLevel = ""
            break
        }

        let timestamp = timeFormatter != nil ? timeFormatter!() : String(describing: logMessage.timestamp)
        return "\(timestamp) \(logMessage.fileName)[\(logMessage.function ?? ""):\(logMessage.line)] ***[\(logLevel)]*** \(logMessage.message)"

    }
    
}

