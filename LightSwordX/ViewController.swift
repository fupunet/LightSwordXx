//
//  ViewController.swift
//  LightSwordX
//
//  Created by Neko on 12/17/15.
//  Copyright © 2015 Neko. All rights reserved.
//

import Cocoa
import SINQ

class ViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        serverDetailsView.hidden = servers.count == 0 ? true : false
    }
    
    override func awakeFromNib() {
        
        let jsonStr = SettingsHelper.loadValue(defaultValue: "", forKey: self.serversKey)
        
        if (jsonStr.length == 0) {
            self.servers = [UserServer]()
            return
        }
        
        let jObjs = JSON(string: jsonStr)
        self.servers = jObjs.map{ obj, jObj in
            let server = UserServer()
            
            server.address = jObj["address"].asString!
            server.port = jObj["port"].asInt!
            server.cipherAlgorithm = jObj["cipherAlgorithm"].asString!
            server.password = jObj["password"].asString!
            server.keepConnection = jObj["keepConnection"].asBool!
            server.listenAddr = jObj["listenAddr"].asString!
            server.listenPort = jObj["listenPort"].asInt!
            
            return server
        }
        
        sinq(servers).whereTrue({ s in s.keepConnection }).forEach { s in
            startServer(s)
        }
    }
    
    let serversKey = "Servers";
    var servers: [UserServer]!
    var runningServers = [Socks5Server]()
    var selectedServer: UserServer!
    var isDirty = false
    
    @IBOutlet weak var serversTableView: NSTableView!
    @IBOutlet weak var serverDetailsView: NSView!
    @IBOutlet weak var serverAddressTextField: NSTextField!
    @IBOutlet weak var serverPortTextField: NSTextField!
    @IBOutlet weak var cipherAlgorithmComboBox: NSComboBox!
    @IBOutlet weak var passwordTextField: NSSecureTextField!
    @IBOutlet weak var keepConnectionCheckBox: NSButton!
    @IBOutlet weak var connectionStatus: NSTextField!
    
    func startServer(userServer: UserServer) {
        let server = Socks5Server()
        server.listenAddr = userServer.listenAddr
        server.listenPort = userServer.listenPort
        server.serverAddr = userServer.address
        server.serverPort = userServer.port
        server.bypassLocal = true
        server.cipherAlgorithm = userServer.cipherAlgorithm
        server.password = userServer.password
        server.timeout = 60 * 1000
        
        server.startAsync({ s in
            if (!s) {
                return
            }
            
            self.runningServers.append(server)
            self.updateStatusText(self.runningServers.count)
        })
    }
    
    func saveServers() {
        if !isDirty {
            return
        }
        
        isDirty = false
        let list = servers.map{ s in return [
            "address": s.address,
            "port": s.port,
            "cipherAlgorithm": s.cipherAlgorithm,
            "password": s.password,
            "keepConnection": s.keepConnection,
            "listenAddr": s.listenAddr,
            "listenPort": s.listenPort
        ]}
        
        SettingsHelper.saveValue(JSON(list).toString(), forKey: serversKey)
    }
    
    func updateStatusText(runningCount: Int) {
        dispatch_async(dispatch_get_main_queue()) {
            let color = runningCount == 0 ? NSColor.grayColor() : NSColor(red: 92.0 / 255, green: 214.0 / 255, blue: 92.0 / 255, alpha: 1)
            let text = runningCount == 0 ? "Stopped" : "Running: \(runningCount)"
            
            self.connectionStatus.textColor = color
            self.connectionStatus.stringValue = "◉ \(text)"
        }
    }
}

