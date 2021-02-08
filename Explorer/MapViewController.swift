//
//  MapViewController.swift
//  Explorer
//
//  Created by Home on 7/16/18 updated on 2/16/20
//  Copyright © 2018 Home. All rights reserved.
//

import UIKit
import GoogleMaps
import CoreLocation
import CoreFoundation
import Foundation
import Darwin

class MapViewController: UIViewController, CLLocationManagerDelegate, GMSMapViewDelegate {
    var locationManager: CLLocationManager!
    var mapView: GMSMapView!
    var camera: GMSCameraPosition!
    var markers: [GMSMarker] = []
    var userPreference = UserPreference.shared
    var park: CLLocation = CLLocation(latitude: 0, longitude: 0)
    var firstCall: Bool = true // One-time check to get user's names from ground
    var lox: LocationEx? // ground data location set
    var pid: UInt = 0 // self id
    var tid: UInt = 1 // tracking id
    var eye: UInt = 1 // My marker index
    var timeMultiple: UInt = 0
    var timer: Timer?
    var p1: CLLocationCoordinate2D? // tracking user last location
    var theading: Double?
    var users = [User]() // 'User' is defined in UserPreference file
    var button: UIButton?

    var location: [CLLocation] = [] // current location set
    var isOutage: Bool = true  // status of outage-buffer - sql-based un-sent data on app startup
    let deltaCount:Int32 = 10  // threshold for no of locations not sent - after which use sql
    let distFilter: CLLocationDistance = 50.0
    var updateLocFlag: Bool = false
    var sql = SQLite()
    var isExpensive: Bool {
        return NetStatus.tell.isExpensive
    }
    var isOnline: Bool {
        return NetStatus.tell.isConnected
    }
/////////////////////////////////////////////////////////////////////////////////////
    override func viewDidLoad() {
        super.viewDidLoad()

        NetMonitor()
        configureLocationManager()
        let info = userPreference.pid
        if  info != nil {
            self.pid = info!
            park = userPreference.lox
            
            initMapView()
            installSendReceiveTasks()
        }
    }
    
    func initMapView() {
        camera = GMSCameraPosition.camera(withLatitude: park.coordinate.latitude, longitude: park.coordinate.longitude, zoom: 13)
        mapView = GMSMapView.map(withFrame: .zero, camera: camera)
        mapView.mapType = GMSMapViewType.normal

        mapView.isMyLocationEnabled = true
        mapView.settings.compassButton = true
        mapView.settings.myLocationButton = true
        mapView.delegate = self
        self.view = mapView
        theading = 0.0
        
        owner = false
        AddButton()
    }

    func installSendReceiveTasks() {
        // For Receive only service
        timer = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(receiveOnly), userInfo: nil, repeats: true)
        
        // For Send/Receive service
        let locDespQueue = DispatchQueue(label: "locDespQueue", qos: .background)
        locDespQueue.async {
            while true {
                if self.isOnline {
                    if self.isOutage { self.clearSqlData() }
                    else if self.location.count > 0 { self.sendLocationArray() }
                    else { self.recvLocation(); usleep(1500000) }
                }
                else { usleep(3000000) } // not reachable

                DispatchQueue.main.sync {
                    self.updateMarkers()
                }
            }
        }
    }

    @objc func receiveOnly() {
        if self.isOnline {
            if !updateLocFlag {
                if firstCall {
                    self.sendLocation(loc: self.park)
                } else {
                    self.recvLocation()
                }
                self.updateMarkers()
            }
            updateLocFlag = false
            timeMultiple += 1
            if(timeMultiple==50) {
                updateMyPreferences()
                timeMultiple = 0
            }
        }
    }

    func mapView(_ mapView: GMSMapView, didLongPressInfoWindowOf marker: GMSMarker) {
        if tid != eye {
            markers[Int(tid)].zIndex = 0
            markers[Int(tid)].icon = GMSMarker.markerImage(with: .red)
        }
        
        tid = UInt(Int(marker.snippet!)!-1)
        
        if tid != eye {
            markers[Int(tid)].zIndex = 2
            markers[Int(tid)].icon = GMSMarker.markerImage(with: .cyan)
            p1 = markers[Int(tid)].position
        }
        
        let alert = UIAlertController(title: "\(marker.title!)" , message: "location(\(marker.position.latitude), \(marker.position.longitude))\r\n@ \(userPreference.url)", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    func initializeMarkers() {
        guard let userLocations = self.lox?.lox else { return }
        
        markers = [GMSMarker]()
        for loc in userLocations {
            let uid = UInt(loc.id)!
            let idx = users.firstIndex(where: { user in return user.pid==uid })!
            
            let mark = GMSMarker();
            mark.title = loc.name!
            mark.position = CLLocationCoordinate2DMake(loc.lat, loc.lng)
            mark.snippet = String(idx+1)
            if  uid==self.pid { // This is you
                mark.icon = GMSMarker.markerImage(with: UIColor.green)
                p1 = mark.position
                mark.zIndex = 1
                eye = UInt(idx)
                tid = eye
            }
            
            markers.append(mark)
            if(idx < markers.count) { markers[idx].map = mapView }
        }
    }

    func configureLocationManager() {
        locationManager = CLLocationManager()
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters //kCLLocationAccuracyBestForNavigation
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.requestAlwaysAuthorization() // requestWhenInUseAuthorization()
        locationManager.delegate = self

        locationManager.distanceFilter = distFilter
        locationManager.startUpdatingLocation()

        locationManager.headingFilter = 25.0
        locationManager.startUpdatingHeading()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationManager.stopUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        self.park = loc
        if self.park.horizontalAccuracy <= distFilter && self.park.verticalAccuracy <= distFilter {
            if firstCall {
                self.sendLocation(loc: self.park)
            } else {
                location.append(self.park)
            }
            if location.count >= deltaCount { saveSqlData() }
        }
        
        if(!isOnline) { mapView.animate(toLocation: self.park.coordinate) }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading heading: CLHeading) {
        if tid == eye {
            theading = heading.trueHeading
            if(!firstCall) { mapView.animate(toBearing: heading.trueHeading) }
        }
        if(!isOnline) { mapView.animate(toBearing: heading.trueHeading) }
    }
   
    func updateMarkers() {
        updateLocFlag = true
        if firstCall == true {
            if(self.lox != nil) {
                saveUserList()
                initializeMarkers()
                firstCall = false
            }
            if !firstCall { welcomeToMorningWalk() }
        }
        else {
            guard let userLocations = self.lox?.lox else { return }
            
            for loc in userLocations {
                let uid = UInt(loc.id)!
                let idx = users.firstIndex(where: { user in return user.pid==uid })!
                
                if uid == self.pid { markers[idx].position = self.park.coordinate }
                else {
                    markers[idx].position = CLLocationCoordinate2DMake(loc.lat, loc.lng)
                }
            }
            
            if tid != eye { getHeading(); mapView.animate(toBearing: theading!) }
            if(tid < markers.count) { mapView.animate(toLocation: markers[Int(tid)].position) }
        }
    }

    func welcomeToMorningWalk() {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            let alertController = UIAlertController(title: String("Morning Walk\nVersion \(version)"), message: "© Copyright 2018-20, PQR & Co\nAll rights reserved.", preferredStyle: UIAlertController.Style.alert)
            alertController.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            present(alertController, animated: true, completion: nil)
        }
    }

    func saveUserList() {
        var dict = [User]()
        guard let userLocations = self.lox?.lox else { return }
        for loc in userLocations {
            let id = UInt(loc.id)!
            dict.append(User(pid: id, name: loc.name!))
        }
        
        self.users = dict
    }

    func sendLocation(loc: CLLocation) {
        let url = URL(string: userPreference.url + "/" + "setLocationi.php")
        var request = URLRequest(url: url!, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 60)
        request.httpMethod = "POST"
        
        var postString = String("pid=") + String(pid) + String("&par=") +
            String(loc.coordinate.latitude) + "," +
            String(loc.coordinate.longitude) + "," +
            String(loc.altitude) + "," +
            String(loc.speed)

        postString += (firstCall==true ? ",1" : ",2")
        request.httpBody = postString.data(using: .utf8, allowLossyConversion: true)
        URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
 
            do {
                if data == nil {
                    return
                }
                let decoder = JSONDecoder()
                self.lox = try decoder.decode(LocationEx.self, from: data!)
                DispatchQueue.main.sync {
                    self.lox = self.lox
                }
            }
            catch let parsingError {
                print("Error: ", parsingError)
            }
        }).resume()
    }

    func recvLocation() {
        let url = URL(string: userPreference.url + "/" + "setLocationi.php")
        var request = URLRequest(url: url!, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 60)
        request.httpMethod = "POST"
        
        if(pid==0) {
            let alert = UIAlertController(title: "Caution" , message: "It seems to be a fresh installation - restart your app please!!!", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            present(alert, animated: true, completion: nil)
        }
        
        let postString = String("pid=") + String(pid) + String("&par=0,0,0,0,0") // Don't use setLocation
        request.httpBody = postString.data(using: .utf8, allowLossyConversion: true)
        URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in

            do {
                if data == nil {
                    return
                }
                let decoder = JSONDecoder()
                self.lox = try decoder.decode(LocationEx.self, from: data!)
                DispatchQueue.main.sync {
                    self.lox = self.lox
                }
            }
            catch let parsingError {
                print("Error: ", parsingError)
            }
        }).resume()
    }

    func sendLocationArray() {
        while location.count > 0 {
            self.sendLocation(loc: location[0])
            location.remove(at: 0)
            usleep(1500000)
        }
    }
    
    func saveSqlData() {
        while location.count > 0 {
            sql.addLocation(loc: location[0])
            location.remove(at: 0)
        }
        if !isOutage { isOutage = true }
    }

    func clearSqlData() {
        let sqlLocations = sql.readLocations(deltaCount)
        for i in 0..<sqlLocations.count {
            self.sendLocation(loc: sqlLocations[i])
            usleep(250000)
        }
        
        if sqlLocations.count < deltaCount {
            isOutage = false
        }
    }

    func getHeading() {
        let id = Int(tid)
        let d2r = 1.74532925199433e-2;
        let p2 = CLLocationCoordinate2DMake(markers[id].position.latitude, markers[id].position.longitude)
        if(p1!.latitude==p2.latitude && p1!.longitude==p2.longitude) { return }
        
        let cphi = cos(p2.latitude*d2r)
        let dlam = (p2.longitude - p1!.longitude)*d2r
        let x = cos(p1!.latitude*d2r)*sin(p2.latitude*d2r) - cphi*cos(dlam)*sin(p1!.latitude*d2r)
        theading = atan2(cphi*sin(dlam),x)/d2r
        p1 = p2
    }
    
    func NetMonitor() {
        NetStatus.tell.didStartMonitoringHandler = {
        }
           
        NetStatus.tell.didStopMonitoringHandler = {
        }
    
        NetStatus.tell.netStatusChangeHandler = {
            DispatchQueue.main.async {}
        }
        NetStatus.tell.startMonitoring()
    }
    
    func updateMyPreferences() {
        userPreference.lox = park
        userPreference.saveUserInfo()
    }
    
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// Following code is linked to Dynamic TableView Implementation - Calling Website scripts
///
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// TableView support data block
    var backView = UIView()
    var tableView = UITableView()
    var imageNames = [[String]]()
    var groups = [CGroup]()

    var groupViewOn: Bool = false
    var tableViewOn: Bool = false
    var adminOption: Bool = true
    var height: CGFloat = 290
    var info = Info()
    var fox = Infox()
    var owner: Bool?
    var searchMap = [Int]()
    var isSearchActive = true
    var searchBar = UISearchBar()
    var messages = [Response]()
    var xmsg = Messager()
 
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)

        coordinator.animate(alongsideTransition: nil) { _ in
            if(self.tableViewOn==true) { self.showGroupView() }
        }
    }

    func AddButton() {
        button = UIButton(type: UIButton.ButtonType.roundedRect)
        button!.frame = CGRect(x: UIScreen.main.bounds.width/3, y: 5, width: UIScreen.main.bounds.width/3, height: 40)
        button!.setTitle("Groups", for: UIControl.State.normal)
        button!.tintColor = self.isOnline ? .blue : .lightGray
        button!.backgroundColor = self.isOnline ? .lightText : .clear
        button!.layer.cornerRadius = 10
        button!.layer.shadowColor = UIColor(named: "#0000FF Match 1")?.cgColor
        button!.layer.shadowOffset = CGSize(width: 5, height: 5)
        button!.layer.shadowRadius = 4.0
        button!.layer.shadowOpacity = 0.4
        
        button!.frame = button!.frame.offsetBy(dx: 0, dy: UIScreen.main.bounds.height-button!.intrinsicContentSize.height-20)

        self.mapView.padding = UIEdgeInsets(top: self.view.safeAreaInsets.top, left: 0, bottom: button!.intrinsicContentSize.height, right: 0)
        self.mapView.addSubview(button!)
        
/**/        button!.addTarget(self, action: #selector(userMessageGroupOptions), for: .touchDown)
//      button!.addTarget(self, action: #selector(groupOptions), for: .touchDown)
    }
    
/**/   @objc func groupOptions(message: String?) {
//   @objc func groupOptions() { // referred inside  - userMessageGroupOptions
         if(self.groupViewOn) { return }
         let title = "\(self.userPreference.name!) - Groups"
         
/**/         let optionMenu = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
//         let optionMenu = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)
         let newGroup  = UIAlertAction(title: "New group", style: .default, handler: { (action) in
             self.newGroup(act: action)
         })
         let admGroup = UIAlertAction(title: "Admins View", style: .default, handler: { (action) in
             self.adminOption = true
             self.showGroup(option: 14)
         })
         let memGroup = UIAlertAction(title: "Members View", style: .default, handler: { (action) in
             self.adminOption = false
             self.showGroup(option: 15)
         })
         optionMenu.addAction(newGroup)
         optionMenu.addAction(admGroup)
         optionMenu.addAction(memGroup)
         
         let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
         optionMenu.addAction(cancelAction)
         
         searchBar.delegate = self
         tableView.delegate = self
         tableView.dataSource = self
         tableView.isScrollEnabled = true
         tableView.register(MemberViewCell.self, forCellReuseIdentifier: "Member")
         self.present(optionMenu, animated: true, completion: nil)
    }

    func showGroupView() {
         self.groupViewOn = true
         self.isSearchActive = false
         self.tableView.reloadData()
         if let window = UIApplication.shared.keyWindow {
             backView.backgroundColor = UIColor(white: 0, alpha: 0.5)
             backView.frame = window.frame
             window.addSubview(backView)
             backView.alpha = 0
         
             let screenSize = UIScreen.main.bounds.size;
             self.height = 2*screenSize.height/3 // height - defined in MapViewController.swift
             tableView.frame = CGRect(x: 0, y: screenSize.height, width: screenSize.width, height: self.height)

             tableView.tableHeaderView = searchBar
             searchBar.showsCancelButton = true
             searchBar.sizeToFit()
             window.addSubview(tableView)
             
             let gesture = UITapGestureRecognizer(target: self, action: #selector(hideGroupView))
             backView.addGestureRecognizer(gesture)
             
             UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 1.0, options: .curveEaseOut, animations: {
                 self.backView.alpha = 1
                 self.tableView.frame = CGRect(x: 0, y: screenSize.height-self.height, width: screenSize.width, height: self.height)
                 self.tableViewOn = true
             }, completion: nil)
         }
    }
     
    @objc func hideGroupView() {
         let screenSize = UIScreen.main.bounds.size;
         UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 1.0, options: .curveEaseOut, animations: {
             self.backView.alpha = 0
             self.tableView.frame = CGRect(x: 0, y: screenSize.height, width: screenSize.width, height: self.height)
             self.searchBar.resignFirstResponder()
             self.tableViewOn = false
             self.groupViewOn = false
         }, completion: nil)
     }
    
     @objc func userMessageGroupOptions() {
        if !self.isOnline { return }
        if self.isExpensive { return }
        
        userMessage(addressString: "message.php", withCompletionHandler: { (message) -> Void in
            if(self.groupViewOn) { return }
/**/            self.groupOptions(message: (message.count > 0 ? message : nil))
        })
    }
    
    func userMessage(addressString: String, withCompletionHandler completionHandler: @escaping((String) -> Void)) {
        let url = URL(string: userPreference.url + "/" + addressString)
        var request = URLRequest(url: url!, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 60)
        request.httpMethod = "POST"

        let postString = String("uid=") + String(self.userPreference.pid) + String("&opt=0&msg=")
        request.httpBody = postString.data(using: .utf8, allowLossyConversion: true)
        URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in

            if error != nil || data == nil {
//                 print("Failed to get message from url")
                completionHandler("")
            }

            do {
                let decoder = JSONDecoder()
                self.messages = [try decoder.decode(Response.self, from: data!)]
                DispatchQueue.main.async {
                    if(self.messages[0].success > 0) {
                        completionHandler(self.messages[0].message)
                    }
                    else {
                        completionHandler("")
                    }
                }
            }
            catch let parsingError {
                print("Error: ", parsingError)
            }
        }).resume()
    }
 }
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
