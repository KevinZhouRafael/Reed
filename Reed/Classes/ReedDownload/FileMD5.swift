//
//  String+MD5.swift
//  Reed

import Foundation
import ZKCommonCrypto


extension Reed {
    func md5FromFile(url:String) -> String? {
        return ZKCrypto.fileMD5(withPath: url)
    }

}
