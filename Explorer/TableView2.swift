//
//  TableView2.swift
//  Explorer
//
//  Created by Home on 4/2/20.
//  Copyright © 2020 Home. All rights reserved.
//

import UIKit

extension MapViewController {
    func newGroup(act: UIAlertAction) {
        let alertController = UIAlertController(title: "Create new group", message: nil, preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: "Done", style: .default) { (_) in
            if let txtField = alertController.textFields?.first, let text = txtField.text {
                self.addGroup(option: 11, group: text)   // update server
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in }
        alertController.addTextField { (textField) in
            textField.placeholder = "Tag"
        }
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }

    func showGroup(option: UInt) {
        let url = URL(string: userPreference.url + "/" + "glogin.php")
        var request = URLRequest(url: url!, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 60)
        request.httpMethod = "POST"
        
        // name field does not do anything for case 14 & 15
        let postString = String("uid=") + String(self.pid) + String("&name=test&option=\(option)")
        request.httpBody = postString.data(using: .utf8, allowLossyConversion: true)
        URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in

            do {
                if data == nil { return }
                let decoder = JSONDecoder()
                let grpx = try decoder.decode(Infox.self, from: data!)

                DispatchQueue.main.sync {
                    if grpx.result > 0 {
                        self.fox = grpx
                        self.owner = self.fox.group.count > 0 ? true : false
                        if(option > 10) { self.populateTable(option: option) } // defined in TableView.swift
                    }
                }
            }
            catch let parsingError {
                print("Error: ", parsingError)
            }
        }).resume()
    }
    
    func addGroup(option: UInt, group: String) {
        let url = URL(string: userPreference.url + "/" + "glogin.php")
        var request = URLRequest(url: url!, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 60)
        request.httpMethod = "POST"

        let postString = String("uid=") + String(self.pid) + String("&name=\(group)&option=\(option)")
        request.httpBody = postString.data(using: .utf8, allowLossyConversion: true)
        URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in

            do {
                if data == nil { return }
                    
                let decoder = JSONDecoder()
                let grpx = try decoder.decode(Infox.self, from: data!)
                
                self.fox.result = 0
                DispatchQueue.main.sync {
                    if grpx.result > 0 {
                        self.fox.group = grpx.group
                        self.fox.groups = grpx.groups
                        if(self.fox.group.count > 0) {
                            self.NewGroupCreated(group: group, admin: self.userPreference.name, result: 1)
                            self.owner = true
                        }
                    } else {
                        self.NewGroupCreated(group: group, admin: self.userPreference.name, result: grpx.result)
                    }
                }
            }
            catch let parsingError {
                print("Error: ", parsingError)
            }
        }).resume()
    }
    
    func NewGroupCreated(group: String, admin: String, result: Int) {
        let msg1 = String("\(group) created successfully !!!")
        let msg2 = String("A group with name \(group) already there!!!")
        let msg3 = String("Too many groups!!! Group limit over!")
        let alert = UIAlertController(title: "Hello \(admin)",
            message: (result < -1 ? msg3 : (result == 1 ? msg1 : msg2)), preferredStyle: .alert)
        let act1 = UIAlertAction(title: "Ok", style: .default)
        alert.addAction(act1)
        
        present(alert, animated: true, completion: nil)
    }
}
