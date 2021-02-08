//
//  UserPreference.swift
//  Explorer
//
//  Created by Home on 8/2/18 updated on 14/2/20
//  Copyright © 2018 Home. All rights reserved.
//

import Foundation
import GoogleMaps

struct User: Equatable {
    var pid: UInt
    var name: String
}

final class UserPreference {
    var pid : UInt!
    var name: String!
    var count:Int!
    var lat:  Double! // home
    var long: Double! // home

    let COUNT = 1
//    let url = "http://192.168.100.24"
//    let url = "http://3.92.12.25"
    let url = "http://idzeropoint.com"
    var lox: CLLocation!
    static var shared = UserPreference()
    
    init() {
        self.pid = 0;//5
        self.name = "unknown"
        self.lox = CLLocation(latitude: 33.6938, longitude: 73.0652) // zero point, Islamabad
        self.count = COUNT
    }

    func saveUserInfo() {
        self.lat = self.lox.coordinate.latitude
        self.long = self.lox.coordinate.longitude

        let userDefaults = UserDefaults.standard
        userDefaults.set(self.pid,   forKey: "pid")
        userDefaults.set(self.name,  forKey: "name")
        userDefaults.set(self.count, forKey: "count")
        userDefaults.set(self.lat,   forKey: "lat")
        userDefaults.set(self.long,  forKey: "long")
        userDefaults.synchronize()
    }

    func loadUserInfo() -> Optional<Any> {
        if let key = UserDefaults.standard.object(forKey: "pid") {
            self.pid   = key as? UInt
            self.name  = (UserDefaults.standard.object(forKey: "name")  as! String)
            self.count = (UserDefaults.standard.object(forKey: "count") as! Int)
            self.lat   = (UserDefaults.standard.object(forKey: "lat")   as! Double)
            self.long  = (UserDefaults.standard.object(forKey: "long")  as! Double)
            self.lox = CLLocation(latitude: self.lat, longitude: self.long)
            return self.pid
        }

        return nil
    }

    func update(pid:UInt, name:String) {
        self.pid = pid
        self.name = name
    }
}
