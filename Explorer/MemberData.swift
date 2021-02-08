//
//  MemberData.swift
//  Explorer
//
//  Created by Home on 3/19/20.
//  Copyright © 2020 Home. All rights reserved.
//

import Foundation

struct Member: Codable, Hashable, Identifiable {
    var id: String
    var name: String
    var of: String
}

// Info group/members data
struct Info: Codable, Hashable {
    var result: Int
    var group: [Member]
    var members: [Member]
    
    init() {
        result = 0
        group = []
        members = []
    }
}

struct Group: Codable, Hashable, Identifiable {
    var id: String
    var admin: String
    var members: [Member]
}

// Infox group/[group.members] data
struct Infox: Codable, Hashable {
    var result: Int
    var group: [Member]
    var groups: [Group]
    
    init() {
        result = 0
        group = []
        groups = []
    }
}

// For tableview usage of info/infox data
class CGroup {
    var name: String?
    var members: [String]?

    init(name: String, members: [String]) {
        self.name = name
        self.members = members
    }
}

struct Response : Codable {
    var success: Int
    var message: String
    
    init(json: [String: Any]) {
        success = json["success"] as? Int ?? 0
        message = json["message"] as? String ?? ""
    }
}
