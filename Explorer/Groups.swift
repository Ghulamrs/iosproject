//
//  Groups.swift
//  Explorer
//
//  Created by Home on 3/19/20.
//  Copyright © 2020 Home. All rights reserved.
//

import UIKit
import Foundation

class GroupSettings: NSObject {
    var backView = UIView()
    var tableView = UITableView()
    var height:CGFloat = 250
    
    override init() {
        super.init()
        tableView.isScrollEnabled = true
        tableView.delegate = self
        tableView.dataSource = self
    }

    @objc func dismiss() {
        let screenSize = UIScreen.main.bounds.size;
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 1.0, options: .curveEaseOut, animations: {
            self.backView.alpha = 0
            self.tableView.frame = CGRect(x: 0, y: screenSize.height, width: screenSize.width, height: self.height)
        }, completion: nil)
    }
    
    func show() {
        if let window = UIApplication.shared.keyWindow {
            backView.backgroundColor = UIColor(white: 0, alpha: 0.5)
            backView.frame = window.frame
            window.addSubview(backView)
            backView.alpha = 0
            
            let screenSize = UIScreen.main.bounds.size;
            tableView.frame = CGRect(x: 0, y: screenSize.height, width: screenSize.width, height: height)
            window.addSubview(tableView)
            
            let gesture = UITapGestureRecognizer(target: self, action: #selector(dismiss))
            backView.addGestureRecognizer(gesture)
            
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 1.0, options: .curveEaseOut, animations: {
                self.backView.alpha = 1
                self.tableView.frame = CGRect(x: 0, y: screenSize.height-self.height, width: screenSize.width, height: self.height)
            }, completion: nil)
        }
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return members.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "Member", for: <#T##IndexPath#>) as? MemberViewCell else {}
        cell.label.text = members[IndexPath.Row]
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
}
