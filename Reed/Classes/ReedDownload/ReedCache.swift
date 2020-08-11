//
//  ReedCache.swift
//  Reed
//
//  Created by kai zhou on 2018/5/30.
//  Copyright © 2018 kai zhou. All rights reserved.
//

import Foundation
import GRDB
import ZKORM

class ReedCache {
    
    private var manager:Reed!
    private var downloadInfoDic:[String:ReedInfo] = [:]
    private var needReload:Bool = true
    private var mutex:pthread_mutex_t = pthread_mutex_t()
    
    init(manager:Reed) {
        self.manager = manager
        pthread_mutex_init(&mutex, nil)
        
        if needReload {
            initData()
        }
        
    }
    
    func initData() {
        pthread_mutex_lock(&mutex)
        downloadInfoDic = [:]
        
        let infos = try! ReedInfo.findAll(ReedInfo.Columns.context == manager.context, order:[ZKORMModel.Columns.created_at.asc, ZKORMModel.Columns.id.asc])
        
        if infos.count > 0 {
            for info in infos {
                info.retryCount = manager.maxRetryCount
                if downloadInfoDic[info.key] == nil {
                    downloadInfoDic[info.key] = info
                }
            }
        }
        
        needReload = false
        
        pthread_mutex_unlock(&mutex)
    }
    
    func save(_ info:ReedInfo ,forKey key:String, complete:((_ success:Bool)->())? = nil) -> Void {
        
        ZKORM.save(dbQueue: try! info.getDBQueue(), {db in
            try info.save(db)
        }, completion: {[weak self] (error) in
            if error == nil {
                if let self = self {
                    pthread_mutex_lock(&self.mutex)
                    self.downloadInfoDic[key] = info
                    pthread_mutex_unlock(&self.mutex)
                }
                
                complete?(true)
            }else{
                complete?(false)
            }
            
        })
        
    }
    
    func get(key:String) -> ReedInfo?{
        if needReload {
            initData()
        }
        
        if let info = downloadInfoDic[key] {
            return info
        }else if let info = try! ReedInfo.findOne(ReedInfo.Columns.key == key && ReedInfo.Columns.context == manager.context){
            info.retryCount = manager.maxRetryCount
            pthread_mutex_lock(&mutex)
            downloadInfoDic[key] = info
            pthread_mutex_unlock(&mutex)
            return info
        }else{
            return nil
        }
    }
    
    func get(keys:[String]) -> [ReedInfo] {
        if needReload {
            initData()
        }
        
        pthread_mutex_lock(&mutex)
        defer {pthread_mutex_unlock(&mutex)}
        
        return keys.compactMap { (key) -> ReedInfo? in
            return get(key:key)
        }
    }
    
    func getAll(downloadListKey:String? = nil) -> [ReedInfo] {
        if needReload {
            initData()
        }
        
        
        pthread_mutex_lock(&mutex)
        defer {pthread_mutex_unlock(&mutex)}
        
        //优先按照时间排序，时间相同按照id排序
        if let key = downloadListKey{
            return downloadInfoDic.values.filter{$0.downloadListKey == key}.sorted(by: {
                if $0.created_at?.timeIntervalSince1970 == $1.created_at?.timeIntervalSince1970{
                    return $0.id! < $1.id!
                }else{
                    if let created_at0 = $0.created_at,let created_at1 = $1.created_at{
                        return $0.created_at!.timeIntervalSince1970 < $1.created_at!.timeIntervalSince1970
                    }else{
                        return false
                    }
                    
                }
            })
        }else{
            return downloadInfoDic.values.sorted(by: {
                if $0.created_at?.timeIntervalSince1970 == $1.created_at?.timeIntervalSince1970{
                    return $0.id! < $1.id!
                }else{
                    if let created_at0 = $0.created_at,let created_at1 = $1.created_at{
                        return $0.created_at!.timeIntervalSince1970 < $1.created_at!.timeIntervalSince1970
                    }else{
                        return false
                    }
                }
            })
        }
        
    }
    
    func remove(key:String){
        pthread_mutex_lock(&mutex)
        downloadInfoDic[key] = nil
        pthread_mutex_unlock(&mutex)
    }
    func clear(){
        pthread_mutex_lock(&mutex)
        downloadInfoDic = [:]
        pthread_mutex_unlock(&mutex)
        needReload = true
    }
    
    deinit {
        pthread_mutex_destroy(&mutex)
    }
}
