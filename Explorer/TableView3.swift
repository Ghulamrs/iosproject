//
//  TableView3.swift
//  Explorer
//
//  Created by Home on 4/2/20.
//  Copyright © 2020 Home. All rights reserved.
//

import UIKit

extension MapViewController {
    func approveMember(n: IndexPath) {
        let url = URL(string: userPreference.url + "/" + "alogin.php")
        var request = URLRequest(url: url!, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 60)
        request.httpMethod = "POST"

        let group = self.groups[n.section].name!
        let member_id = Int(self.fox.groups[n.section].members[n.row].id)!
        let postString = String("uid=") + String(self.pid) + String("&name=\(group)&option=\(member_id)")

        request.httpBody = postString.data(using: .utf8, allowLossyConversion: true)
        URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in

            do {
                if data == nil { return }
                
                let decoder = JSONDecoder()
                let info1 = try decoder.decode(Info.self, from: data!)
                self.info.result = 0
                DispatchQueue.main.sync {
                    if info1.result > 0 {
                        self.info.result = info1.result
                        self.NewUserApproved(n: n)
                    }
                }
            }
            catch let parsingError {
                print("Error: ", parsingError)
            }
        }).resume()
    }
    
    func NewRequestDispatched(requestor: String, group: String, admin: Member) {
        let alert = UIAlertController(title: "Hello \(requestor)", message: "A request for \(group) group is forwarded to the admin(\(admin.name)) !!!", preferredStyle: .alert)
        let act1 = UIAlertAction(title: "Ok", style: .default)
        alert.addAction(act1)
        
        present(alert, animated: true, completion: nil)
        
        // Send message to 'admin' that 'member' has put the request for 'group' membership
        let message = String("Hello \(admin.name): \(requestor) has requested for membership of \(group) group!")
        self.xmsg.SendMessage(uid: UInt(admin.id)!, option: 2, msg: message)
    }

    func NewUserApproved(n: IndexPath) {
        let admin = userPreference.name!
        let group = self.groups[n.section].name!
        let person = self.groups[n.section].members![n.row]
        let memid = Int(self.fox.groups[n.section].members[n.row].id)!

        self.imageNames[n.section][n.row] = "member";
        self.tableView.beginUpdates()
        self.tableView.reloadData() // update view now - online
        self.tableView.endUpdates()
        
        let alert = UIAlertController(title: "Hello \(admin)", message: "\(person) added to \(group) group and is being informed!!!", preferredStyle: .alert)
        let act1 = UIAlertAction(title: "Ok", style: .default)
        alert.addAction(act1)
        
        present(alert, animated: true, completion: nil)
        
        // Send message to 'member' that 'admin' has registered you in the 'group'
        let message = String("Hello \(person): \(admin) has acknowledged you as member of \(group) group!")
        self.xmsg.SendMessage(uid: UInt(memid), option: 2, msg: message)
    }
    
    func updateMembers(option: Int, usr: String, group: String, indexPath: IndexPath, indexPath1: IndexPath) {
        let url = URL(string: userPreference.url + "/" + "glogin.php")
        var request = URLRequest(url: url!, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 60)
        request.httpMethod = "POST"

        let postString = String("uid=") + usr + String("&name=\(group)&option=\(option)")
        request.httpBody = postString.data(using: .utf8, allowLossyConversion: true)
        URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in

            do {
                if data == nil { return }
                
                let decoder = JSONDecoder()
                let infox = try decoder.decode(Infox.self, from: data!)
                self.fox.result = 0
                DispatchQueue.main.sync {
                    if infox.result > 0 {
                        self.fox.result = infox.result
                        self.fox.groups = infox.groups
                        if(option==12) {
                            self.groups[indexPath.section].members?.append(self.userPreference.name)
                            self.imageNames[indexPath.section].append("request");
                            
                            let count = self.groups[indexPath.section].members?.count // update tableview
                            let index = IndexPath(row: count!-1, section: indexPath1.section)
                            self.tableView.beginUpdates()
                            self.tableView.insertRows(at: [index], with: .right)
                            self.tableView.endUpdates()
                            
                            let group = self.groups[indexPath.section].name!
                            let aname = self.fox.groups[indexPath.section].admin
                            let admin = self.fox.groups[indexPath.section].members.first(where: { member in
                                member.name == aname
                            })

                            self.NewRequestDispatched(requestor: self.userPreference.name, group: group, admin: admin!)
                        }
                        else if(option==13) {
                            let membr = self.groups[indexPath.section].members![indexPath.row]
                            self.groups[indexPath.section].members?.remove(at: indexPath.row) // data source update
                            self.imageNames[indexPath.section].remove(at: indexPath.row)         // ...
                            
                            self.tableView.deleteRows(at: [indexPath1], with: .fade) // update tableview
                            
                            // Send message to 'admin' that Mr 'member' has left the 'group'
                            let group = self.fox.group[indexPath.section].name
                            let admin = self.fox.groups[indexPath.section].admin
                            let admit = self.fox.groups[indexPath.section].members.firstIndex(where: { mr in
                                mr.name == admin
                            })
                            let admid = self.fox.groups[indexPath.section].members[admit!].id
                            let messg = String("Hello \(admin): \(membr) has left the \(group) group!")
                            self.xmsg.SendMessage(uid: UInt(admid)!, option: 2, msg: messg)
                        }
                    }
                    else if(infox.result == 0) { // an unapproved request is already there
                        self.MessageBox(requestor: self.userPreference.name, group: group);
                    }
                }
            }
            catch let parsingError {
                print("Error: ", parsingError)
            }
        }).resume()
    }

    func denyMembership(option: Int, usr: String, message: String, indexPath: IndexPath, indexPath1: IndexPath) {
        let url = URL(string: userPreference.url + "/" + "glogin.php")
        var request = URLRequest(url: url!, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 60)
        request.httpMethod = "POST"
        
        let group = self.groups[indexPath.section].name!
        let postString = String("uid=") + usr + String("&name=\(group)&option=\(option)")
        request.httpBody = postString.data(using: .utf8, allowLossyConversion: true)
        URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
        
            do {
                if data == nil { return }
                
                let decoder = JSONDecoder()
                let infox = try decoder.decode(Infox.self, from: data!)
                DispatchQueue.main.sync {
                    if infox.result > 0 {
                        self.groups[indexPath.section].members?.remove(at: indexPath.row) // update data source
                        self.imageNames[indexPath.section].remove(at: indexPath.row)     // ...
                        
                        self.tableView.deleteRows(at: [indexPath1], with: .fade) // update tableview
                        
                        // Send denial/removal message to 'member' from 'Admin' of the 'group'
                        self.xmsg.SendMessage(uid: UInt(usr)!, option: 2, msg: message)
                    }
                }
            }
            catch let parsingError {
                print("Error: ", parsingError)
            }
        }).resume()
    }

    func removeAdminAsWellAsGroup(n: IndexPath) {
        let url = URL(string: userPreference.url + "/" + "alogin.php")
        var request = URLRequest(url: url!, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 60)
        request.httpMethod = "POST"

        let group = self.groups[n.section].name!
        let member_id = -Int(self.fox.groups[n.section].members[n.row].id)!
        let postString = String("uid=") + String(self.pid) + String("&name=\(group)&option=\(member_id)")
        request.httpBody = postString.data(using: .utf8, allowLossyConversion: true)
        URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in

            do {
                if data == nil { return }
                
                let decoder = JSONDecoder()
                let info1 = try decoder.decode(Info.self, from: data!)
                self.info.result = 0
                DispatchQueue.main.sync {
                    if info1.result > 0 {
                        self.info.result = info1.result
                        self.imageNames[n.section].remove(at: n.row)
                        self.groups[n.section].members?.remove(at: n.row)

                        // It's admin, group too is gone - none left to be responded!
                        self.imageNames.remove(at: n.section) // remove index as well
                        self.groups.remove(at: n.section) // ...
                        if(self.isSearchActive) {
                            self.isSearchActive = false
                            self.searchBar.text = ""
                        }
                        self.tableView.reloadData()
                        if(self.groups.count == 0) { self.hideGroupView() }
                    }
                }
            }
            catch let parsingError {
                print("Error: ", parsingError)
            }
        }).resume()
    }
    
    func warnBeforeRemoval(member: String, group: String, n: IndexPath) {
        let message = String("Are you sure? you want to delete \(group) group?")
        let alert = UIAlertController(title: "Hello \(userPreference.name!)", message: message, preferredStyle: .alert)
        let act1 = UIAlertAction(title: "Yes", style: .default, handler: { action in
            self.removeAdminAsWellAsGroup(n: n) // defined in TableView3.swift file
        })
        let act2 = UIAlertAction(title: "No", style: .cancel)
        alert.addAction(act1)
        alert.addAction(act2)
        
        present(alert, animated: true, completion: nil)
    }
    
    func MessageBox(requestor: String, group: String) {
        let alert = UIAlertController(title: "Hello \(requestor)", message: "A request for \(group) group is already in progress!", preferredStyle: .alert)
        let act1 = UIAlertAction(title: "Ok", style: .default)
        alert.addAction(act1)
        
        present(alert, animated: true, completion: nil)
    }
}
