//
//  Reed+Net.swift
//  Reed
//
//  Created by Kevin Zhou on 2020/8/11.
//  Copyright © 2020 kai zhou. All rights reserved.
//

import Foundation
import Reachability

private var reedTimerKey: Void?

public extension Reed{
    var timer:Timer?{
        set{
            objc_setAssociatedObject(self, &reedTimerKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get{
            return objc_getAssociatedObject(self, &reedTimerKey) as? Timer
        }
    }
    
    func configDownLoadManager(){
//        if !KCUserDefaultsManager.isLogin(){return}
//
//        let manager = KCDownloadManager.shared
//        if let uuid = KCUserDefaultsManager.getKCUUID(){
//            manager.context = uuid.stringValue
            checkNetToStart()
//        }
    }
    
    //MARK: Notification
    func addNotifications(){
        
//            //登陆成功
//            NotificationCenter.default.addObserver(self, selector: #selector(loginHandler), name: NSNotification.Name(rawValue: "com.kaochong.account.loginSuccess"), object: nil)
//            //登出
//            NotificationCenter.default.addObserver(self, selector: #selector(logoutHandler), name: NSNotification.Name(rawValue: "com.kaochong.account.will.logout"), object: nil)
//            
//            NotificationCenter.default.addObserver(self, selector: #selector(logoutHandler), name: NSNotification.Name(rawValue: "com.kaochong.account.kickout"), object: nil)
//            
//            NotificationCenter.default.addObserver(self, selector: #selector(logoutHandler), name: NSNotification.Name(rawValue: "com.kaochong.account.tokenDisable"), object: nil)
        
        //网络改变
//        NotificationCenter.default.addObserver(self, selector: #selector(networkChangeHandler(noti:)), name: NSNotification.Name.AFNetworkingReachabilityDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector:  #selector(reachabilityChangedHandler(noti:)), name: Notification.Name.reachabilityChanged, object: nil)
        
        //进入后台
        NotificationCenter.default.addObserver(self, selector: #selector(appEnterBackground(noti:)), name: UIApplication.didEnterBackgroundNotification, object: nil)
        
        //进入前台
        NotificationCenter.default.addObserver(self, selector: #selector(appEnterForeground(noti:)), name: UIApplication.willEnterForegroundNotification, object: nil)
        
        //空间已满
        NotificationCenter.default.addObserver(self, selector: #selector(diskSpaceFullHandler(noti:)), name: Noti_ReedDownload_FullSpace, object: nil)
        
        //下载错误
        NotificationCenter.default.addObserver(self, selector: #selector(downloadFailsHandler(noti:)), name: Noti_ReedDownload_Fails, object: nil)
        
    }
    
    func removeNotifications(){
        NotificationCenter.default.removeObserver(self)
    }
        
    //示例代码
//    @objc func loginHandler(){
//        configDownLoadManager()
//    }
//
//    @objc func logoutHandler(){
//        stopDownload()
//    }
    
    @objc func appEnterBackground(noti:Notification){
        stopDownload()
    }
        
    @objc func appEnterForeground(noti:Notification){
        checkReabilityChanged()
    }
    

    @objc func diskSpaceFullHandler(noti:Notification){
//            if noti.object == nil && fullHUD == nil{
//                fullHUD = KCHUDManagement.sharedInstance()?.showFailureHUD(withMessage: "手机存储空间已满，请清理手机空间再开始下载", completion: {[unowned self] (hud, view)  in
//                    self.fullHUD = nil
//                })
//            }
    }
    
    @objc func downloadFailsHandler(noti:Notification){
        if let info = noti.object as? ReedInfo{
            if info.downloadStatus == .faild, let failReason = info.downloadFailReason, failReason == .md5Verification{
//                    Event.event(OfflineDownload_DownloadManagement_MD5Mismatching)

//                    if (Lesson.find(key: info.key) != nil){
//                        Event.event(OfflineDownload_DownloadManagement_Pause, label: Pause_MD5Mismatching)
//                    }else{
//                        Event.event(DataDownload_DownloadManagement_Pause, label: Pause_MD5Mismatching)
//                    }
            }
        }
    }
    
    @objc func reachabilityChangedHandler(noti:Notification){
        if let reachability = noti.object as? Reachability{
            reachabilityDownloadOrNot(reachability: reachability)
        }
    }
        


    //MARK: public
    func checkNetToStart(){
        if ReedReachability.isReachability(),
            (ReedReachability.isWIFI() || (ReedReachability.isCellular()) ){
//                    && KCUserDefaultsManager.getAllowCellularFileDownload()) ){
            startDownloadDelay()
        }
    }
    
    //调整设置的，是否允许手机网络下载的时候，可能会调用。
    func stopDownload(){
        stopTimer()
        shutDown()
    }
    
    //MARK: timer
    private func stopTimer(){
        timer?.invalidate()
        timer = nil
    }
    
    @objc private func timerHandler(){
        checkToStart()
        stopTimer()
    }
    
    //MARK: control
    private func startDownloadDelay(){
        stopTimer()
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(timerHandler), userInfo: nil, repeats: false)
        RunLoop.main.add(timer!, forMode: .common)
        timer?.fire()
    }
    
    func checkReabilityChanged(){
        reachabilityDownloadOrNot(reachability: ReedReachability.reachability)
    }
    
    private func reachabilityDownloadOrNot(reachability:Reachability){
        
        let connection = reachability.connection
        switch connection {
        case .unavailable:
            print("+++++++++++++++++++++++++网络状态+++无网络+++++++++++++++++++++++++++++++++++++")
            stopDownload()
            break
        case .wifi:
            print("+++++++++++++++++++++++++网络状态+++WIFI+++++++++++++++++++++++++++++++++++++")
            startDownloadDelay()
            break
        case .cellular:
            print("+++++++++++++++++++++++++网络状态+++蜂窝+++++++++++++++++++++++++++++++++++++")
            if allowCellularDownload{
                print("+++++++++++++++++++++蜂窝数据下载+++++++++++++++++++++++++++++++++++++")
                startDownloadDelay()
            }else{
                Log.i("+++++++++++++++++++++蜂窝数据停止下载+++++++++++++++++++++++++++++++++++++")
                stopDownload()
            }
            break
        default:
            print("+++++++++++++++++++++++++网络状态+++未知+++++++++++++++++++++++++++++++++++++")
            break

        }
    }
}
