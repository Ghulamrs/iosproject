//
//  Records.swift
//  Explorer
//
//  Created by Home on 8/7/18.
//  Upated by Home on 16/1/19.
//  Upated by Home on 25/2/20. In Location, converted id to UInt, lat, lng to Double
//  Copyright © 2018 Home. All rights reserved.
//

import Foundation

class LocationEx : Codable {
    var  lox : [Location]
    init(loc : [Location]) {
        self.lox = loc
    }
}

class Location : Codable {
    var id:   String
    var lat:  Double
    var lng:  Double
    var name: String?

    init(id: String, lat: Double, lng: Double, name: String) {
        self.id   = id
        self.lat  = lat
        self.lng  = lng
        self.name = name
    }
    
    convenience init(id: String, lat: Double, lng: Double) {
        self.init(id: id, lat: lat, lng: lng, name: "")
    }
}
