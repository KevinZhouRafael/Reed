//
// Created by kai zhou on 09/03/2017.
// Copyright (c) 2017 com.wumingapie@gmail.com. All rights reserved.
//

import Foundation

class PreDownloadItem:Codable{
    var md5:String?
    var url:String = ""
   
    var name:String{
        (url as! NSString).lastPathComponent
    }
    var enabled:Bool = true //代表点击下载。
    
    enum CodingKeys : String, CodingKey {
        case md5
        case url
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        url = try container.decode(String.self, forKey: .url)
        md5 = try container.decodeIfPresent(String.self, forKey: .md5)
    }
    
}
