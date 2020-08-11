//
//  ReedReachability.swift
//  Reed
//
//  Created by Kevin Zhou on 2020/8/11.
//  Copyright © 2020 kai zhou. All rights reserved.
//


import Foundation
import Reachability

public class ReedReachability{
    public static let reachability = try! Reachability()
    public static func startMonitor(){
        reachability.whenReachable = { reachability in
            if reachability.connection == .wifi {
//                print("Reachable via WiFi")
            } else {
//                print("Reachable via Cellular")
            }
        }
        reachability.whenUnreachable = { _ in
//            print("Not reachable")
        }
        
        do {
            try reachability.startNotifier()
        } catch {
//            print("Unable to start notifier")
        }
    }
    
    public static func stopMonitor(){
        reachability.stopNotifier()
    }
    
    public static func isReachability() -> Bool{
        return reachability.connection != .unavailable
    }
    
    public static func isWIFI() -> Bool{
        return reachability.connection == .wifi
    }
    
    public static func isCellular() -> Bool{
        return reachability.connection == .cellular
    }
}
