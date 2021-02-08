//
//  ViewController.swift
//  Explorer
//
//  Created by Home on 7/16/18.
//  Copyright © 2018 Home. All rights reserved.
//

import UIKit
import CoreFoundation
import Foundation

class ViewController: UIViewController {
    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var password2: UITextField!
    var response = [Response]()
    var user = UserPreference.shared

    override func viewDidLoad() {
        super.viewDidLoad()

//       user.saveUserInfo()
//       Enable battery monitoring feature else the batteryState is .unknown
//        UIDevice.current.isBatteryMonitoringEnabled = true
//        if UIDevice.current.batteryState == .unplugged {
//          print("Do not use `kCLLocationAccuracyBestForNavigation` as the desired accuracy to save power consumption")
//          return
//        }
        
        if user.loadUserInfo() != nil { // check! if already stored profile
            print("User: \(String(describing: user.pid)), Name: \(String(describing: user.name)) ")
//            let message = String("Pid: \(user.pid), Name: \(user.name) ")
//            self.showAlert(title: "Error", message: message)
            if user.pid > 0 { self.performSegue(withIdentifier: "SkipLogin", sender: self) }
        }
    }

    @IBAction func SignUp(_ sender: UIButton) {
        if(username.hasText && password.hasText && password2.hasText) {
            let usernameLength = (username.text?.count)!
            let passwordLength = (password.text?.count)!
            if(usernameLength >= 3 && passwordLength > 5 && password.text == password2.text) {
                loginMessage()
            } else {
                let message = "Passwords enetered do not match !!!"
                self.showAlert(title: "Error", message: message)
            }
        } else {
            let message = "Please enter username and/or password !!!"
            self.showAlert(title: "Error", message: message)
        }
    }

    func showAlert(title: String, message: String, style: UIAlertController.Style = .alert) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: style)
        let action = UIAlertAction(title: title, style: .default) { (action) in
            self.dismiss(animated: true, completion: nil)
        }
        alertController.addAction(action)
        self.present(alertController, animated: true, completion: nil)
    }

    @IBAction func Cancel(_ sender: UIButton) {
        exit(0)
    }

    func loginMessage() {
        let url = URL(string: user.url + "/" + "login.php")
        var urlrequest = URLRequest(url: url!)
        urlrequest.httpMethod = "POST"

        let postString = String("name="+username.text!+"&pswd="+password.text!+"&option=0")
        urlrequest.httpBody = postString.data(using: .utf8, allowLossyConversion: true)
        URLSession.shared.dataTask(with: urlrequest, completionHandler: { (data, response, error) in
            
            if error != nil {
                print("Failed to get data from url")
                return
            }

            do {
                let decoder = JSONDecoder()
                self.response = [try decoder.decode(Response.self, from: data!)]
                DispatchQueue.main.async {
                    self.CloseUp()
                }
            }
            catch {
                print(error)
            }
        }).resume()
    }

    func CloseUp() {
        let result = Int(response[0].success)
        if  result >= 0 {
            var pid = UInt(result)
            if pid==0 { pid = ReRegister( name: username.text!) }
            user.update(pid: pid, name: username.text!)
            user.saveUserInfo()
        }
        else {
            ErrorRegistration(msg: response[0].message)
        }
    }

    func ErrorRegistration(msg: String) {
        let alert = UIAlertController(title: "Error Registration", message: msg, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func ReRegister(name: String) -> UInt {
        let existingUsers:[String] = ["unknown", "gra", "namrah", "ahsan", "erfa", "gra1", "asif", "yasin", "shan", "saeed", "samar", "gra2"]
//        let existingUsers1:[String] = ["unknown", "Allah-o-Akbar", "gra", "asif", "ahsan", "gra1", "invalid"]
  //      if user.url.contains("morningwalk") {
            for i in 1..<existingUsers.count {
                if existingUsers[i].contains(name) && name.contains(existingUsers[i]) {
                    return UInt(i)
                }
            }
    //    } else {
      //      for i in 1..<existingUsers1.count {
        //        if existingUsers1[i].contains(name) && name.contains(existingUsers1[i]) {
          //          return UInt(i)
            //    }
 //           }
   //     }
        return 0;
    }
}
