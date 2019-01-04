//
//  AlamofireRequests.swift
//  TwitComeDup
//
//  Created by 中原陸 on 2018/09/03.
//  Copyright © 2018年 中原陸. All rights reserved.
import Alamofire
import SwiftyJSON

class AlamofireRequests{
    
    var req_url:String?
    var Auth_header:[String:String]?
    
    init(req_url: String?, auth_header:Dictionary<String,String>?) {
        self.req_url = req_url
        self.Auth_header = auth_header
    }
    func getComment(callback: @escaping(JSON) -> ()) {
        print(req_url!)
        print(Auth_header!)
        
        Alamofire.request(URL(string:req_url!)!, method: .get, parameters: nil, headers: Auth_header)
            .responseJSON { (response) -> Void in
                if let object = response.result.value {
                     let jsonObject = JSON(object)
                    callback(jsonObject)
                }
    
            }
        }
    
}
