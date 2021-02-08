//
//  xMessages.swift
//  Explorer
//
//  Created by Home on 4/3/20.
//  Copyright © 2020 Home. All rights reserved.
//

import Foundation

class Messager {
    var count: Int = 0
    var response = [Response]()
    var userPreference = UserPreference.shared

    func SendMessage(uid: UInt, option: UInt, msg: String) {
        
        let url = URL(string: userPreference.url + "/" + "message.php")
        var request = URLRequest(url: url!, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 60)
        request.httpMethod = "POST"

        let postString = String("uid=") + String(uid) + String("&opt=\(option)&msg=\(msg)")
        request.httpBody = postString.data(using: .utf8, allowLossyConversion: true)
        URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in

            if error != nil {
                 print("Failed to get message from url")
                 return
             }

             do {
                 let decoder = JSONDecoder()
                 self.response = [try decoder.decode(Response.self, from: data!)]
                 DispatchQueue.main.async {
                    self.count = -1
                    if(self.response[0].success >= 0) {
                        self.count = Int(self.response[0].success)
                    }
                 }
             }
             catch let parsingError {
                print("Error: ", parsingError)
            }
        }).resume()
    }
}
