//
//  TableView.swift
//  Explorer
//
//  Created by Home on 3/31/20.
//  Copyright © 2020 Home. All rights reserved.
//  Dynamic TableView Implementation - Calling Website for updated Groups and Members lists
//  An extention to MapViewController class - it is referenced in MapViewController.swift file
//
import UIKit

extension MapViewController : UITableViewDelegate, UITableViewDataSource {
    func translateIndexPath(indexPath: IndexPath) -> IndexPath {
//        print("xtrans called \(indexPath)")
        return isSearchActive ? IndexPath(row: indexPath.row, section: self.searchMap[indexPath.section]) : indexPath
    }
    
/// MARK:- tableView delegate overrides
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "Member", for: indexPath) as? MemberViewCell else {fatalError()}
        
        let ip = translateIndexPath(indexPath: indexPath)
        let tag = self.imageNames[ip.section][ip.row]
        let hereYou = self.groups[ip.section].members!.contains(self.userPreference.name)

        cell.label.text = self.groups[ip.section].members?[ip.row]
        let itsYou = cell.label.text == self.userPreference.name
        cell.icons.image = UIImage(named: tag)!

        cell.option.text = tag //self.fox.groups[ip.section].members[ip.row].of
        if(adminOption==true) { cell.accessoryType = (tag == "request" ? .detailButton : .none) }
        else if(tag == "admin") { cell.accessoryType = (itsYou || hereYou) ? .none : .detailButton }
        else { cell.accessoryType = .none }

        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.isSearchActive ? self.searchMap.count : self.groups.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sector = self.isSearchActive ? self.searchMap[section] : section
        return self.groups[sector].members!.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sector = self.isSearchActive ? self.searchMap[section] : section
        return self.groups[sector].name
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath1: IndexPath) {
        let indexPath = translateIndexPath(indexPath: indexPath1)
        if(self.groups[indexPath.section].members?[indexPath.row] == userPreference.name!) {
//            print("Sec \(indexPath.section) Row \(indexPath.row) is selected")
        }
    }

    func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath1: IndexPath) {
        let indexPath = translateIndexPath(indexPath: indexPath1)
        let member = self.groups[indexPath.section].members![indexPath.row]
        let group = self.groups[indexPath.section].name
        
        if(adminOption == true) {
            let alert = UIAlertController(title: "Hello \(userPreference.name!)",
                message: "Do you want to add \(member) to \(group!) group?", preferredStyle: .alert)
            let act1 = UIAlertAction(title: "Accept", style: .default, handler: { action in
                self.approveMember(n: indexPath)
            })
            let act2 = UIAlertAction(title: "Decline", style: .destructive, handler: { action in

                // we don't have name's id - take it from fox of last called service 15(of glogin)
                if(member==self.fox.groups[indexPath.section].members[indexPath.row].name) {
                    let mid = self.fox.groups[indexPath.section].members[indexPath.row].id
                    
                    let fgroup = self.fox.group[indexPath.section].name
                    let message = String("Sorry \(member): Your request to join \(fgroup) group is declined!")
                    self.denyMembership(option: 13, usr: mid, message: message, indexPath: indexPath, indexPath1: indexPath1)
                }
            })
            let act3 = UIAlertAction(title: "Defer", style: .cancel, handler: nil)
            alert.addAction(act1)
            alert.addAction(act2)
            alert.addAction(act3)

            present(alert, animated: true, completion: nil)
        }
        else {
            let alert = UIAlertController(title: "Hello \(userPreference.name!)",
                message: "Do you want to join \(self.groups[indexPath.section].name!) group?", preferredStyle: .alert)
            let act1 = UIAlertAction(title: "Yes", style: .default, handler: { action in
                self.updateMembers(option: 12, usr: String(self.pid), group: group!, indexPath: indexPath, indexPath1: indexPath1)
            })
            let act2 = UIAlertAction(title: "No", style: .cancel)
            alert.addAction(act1)
            alert.addAction(act2)
            
            present(alert, animated: true, completion: nil)
        }
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath1: IndexPath) -> UITableViewCell.EditingStyle {
        let indexPath = translateIndexPath(indexPath: indexPath1)
        if(groups[indexPath.section].members?[indexPath.row] == userPreference.name! || adminOption) {
            if(groups[indexPath.section].members!.count > 1) {
                if(imageNames[indexPath.section][indexPath.row] == "member") { return .delete }
            }
            else if(adminOption) { return .delete }
        }
        
        return .none
    }
/*
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath1: IndexPath) -> UISwipeActionsConfiguration? {
        let indexPath = translateIndexPath(indexPath: indexPath1)
        let configuration = UISwipeActionsConfiguration(actions: [
                  UIContextualAction(style: .destructive, title: "Delete", handler: { (action, view, completionHandler) in
                    self.groups[indexPath.section].members!.remove(at: indexPath.row)
                    self.imageNames[indexPath.section].remove(at: indexPath.row)
                    self.tableView.reloadData()
                    completionHandler(true)
            })
        ])
        return configuration
    }
*/
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath1: IndexPath) {
        let indexPath = translateIndexPath(indexPath: indexPath1)
        guard editingStyle == .delete else {return}
        let group = self.groups[indexPath.section].name!
        
        if( adminOption) {
            let member = self.groups[indexPath.section].members![indexPath.row]
            let mid = self.fox.groups[indexPath.section].members[indexPath.row].id
            if(self.groups[indexPath.section].members?.count==1) {
                warnBeforeRemoval(member: member, group: group, n: indexPath)
                return
            }
            let message = String("Do you want to remove \(member) from \(group) group?")
            let alert = UIAlertController(title: "Hello \(userPreference.name!)", message: message, preferredStyle: .alert)
            let act1 = UIAlertAction(title: "Yes", style: .default, handler: { action in
                let message = String("Sorry \(member): You are no more present in \(group) group!")
                self.denyMembership(option: 13, usr: mid, message: message, indexPath: indexPath, indexPath1: indexPath1)
            })
            
            let act2 = UIAlertAction(title: "No", style: .cancel)
            alert.addAction(act1)
            alert.addAction(act2)
            
            present(alert, animated: true, completion: nil)
        }
        else {
            let alert = UIAlertController(title: "Hello \(userPreference.name!)", message: "Do you want to leave \(group) group?", preferredStyle: .alert)
            let act1 = UIAlertAction(title: "Yes", style: .default, handler: { action in
                self.updateMembers(option: 13, usr: String(self.pid), group: group, indexPath: indexPath, indexPath1: indexPath1)
            })
            
            let act2 = UIAlertAction(title: "No", style: .cancel)
            alert.addAction(act1)
            alert.addAction(act2)
            
            present(alert, animated: true, completion: nil)
        }
    }

    func populateTable(option: UInt) {
        self.groups.removeAll()
        self.imageNames.removeAll()
        
        self.owner = self.fox.groups.contains(where: { group in group.admin == self.userPreference.name })
        if(option == 14 && !self.owner!) { return } // Only admin can see group fellows
        for i in 0..<self.fox.groups.count {
            let admin = self.fox.groups[i].admin
            self.groups.append(CGroup(name: self.fox.group[i].name, members: self.fox.groups[i].members.filter({ member in
                if(option == 15 && member.of == "0") { // requesting members in members view
                    return (member.name == self.userPreference.name) // show only his/hers
                }
                return true // registered members
            }).map({ mr in mr.name })))
            self.imageNames.append(self.fox.groups[i].members.filter({ member in
                if(option == 15 && member.of == "0") { // requesting members  in members view
                    return (member.name == self.userPreference.name) // show only his/hers
                }
                return true // registered members
            }).map({ mr in mr.name==admin ? "admin" : (mr.of=="1" ? "member" : "request") }))
        }

        self.showGroupView()
    }
}

extension MapViewController: UISearchBarDelegate {
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.searchBar.resignFirstResponder()
        searchBar.text = ""
        self.isSearchActive = false
        self.tableView.reloadData()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        self.searchBar.becomeFirstResponder()
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        self.searchBar.resignFirstResponder()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.searchMap.removeAll()
        for index in 0..<self.groups.count {
            if self.groups[index].name!.lowercased().hasPrefix(searchText.lowercased()) {
                self.searchMap.append(index)
            }
        }
        self.isSearchActive = true
        self.tableView.reloadData()
    }
}
