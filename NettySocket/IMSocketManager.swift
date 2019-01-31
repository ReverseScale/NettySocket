//
//  IMSocketManager.swift
//  NettySocket
//
//  Created by Steven Xie on 2019/1/31.
//  Copyright © 2019 Steven Xie. All rights reserved.
//

import UIKit
import CocoaAsyncSocket

enum SocketManagerCommands: String {
    case someComand = "W1"
}

enum ConnectionState: String {
    case connecting = "Connecting..."
    case connected = "Connected"
    case disconnected = "Disconnected"
    case failedToConnect = "Failed to connect to host."
}

protocol SocketManagerDelegate: class {
    func socketManager(didConnectToHost host: String, port: UInt16)
    func socketManager(didDisconnectWithError err: Error?)
    func socketManager(didReadString data: String, withTag tag: Int)
    func socketManager(didFailToConnect failureMsg: String)
}

class IMSocketManager: NSObject {

    static let shared = IMSocketManager()
    
    private var kSocketHost: String = ""
    private var kSocketPORT: UInt16 = 0
    private var tcpSocket: GCDAsyncSocket?
    weak var delegate: SocketManagerDelegate?
    
    func connect(host: String, port: UInt16) {
        self.kSocketHost = host
        self.kSocketPORT = port
        tcpSocket = GCDAsyncSocket(delegate: self, delegateQueue: DispatchQueue.main)
        
        do {
            try tcpSocket!.connect(toHost: kSocketHost, onPort: kSocketPORT)
        } catch let error {
            Logger(identifier: #file, message: error.localizedDescription)
            delegate?.socketManager(didFailToConnect: error.localizedDescription)
        }
    }
    
    func sendMessage(messageString msg: String) {
        if let _data = msg.data(using: .utf8), let _carriageReturn = "\r".data(using: .utf8) {
            tcpSocket?.write(_data, withTimeout: -1, tag: 0)
            tcpSocket?.write(_carriageReturn, withTimeout: -1, tag: 99)
        }
    }
    
    func sendCommand(command: SocketManagerCommands) {
        if let _data = command.rawValue.data(using: .utf8), let _carriageReturn = "\r".data(using: .utf8) {
            tcpSocket?.write(_data, withTimeout: -1, tag: 0)
            tcpSocket?.write(_carriageReturn, withTimeout: -1, tag: 99)
        }
    }
}

extension IMSocketManager: GCDAsyncSocketDelegate {
    func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        tcpSocket?.readData(withTimeout: -1, tag: 0)
        delegate?.socketManager(didConnectToHost: host, port: port)
    }
    
    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        tcpSocket?.readData(withTimeout: -1, tag: 0)
        
        if let stringData = String(bytes: data, encoding: .utf8) {
            delegate?.socketManager(didReadString: stringData, withTag: tag)
        }
    }
    
    func socket(_ sock: GCDAsyncSocket, didWriteDataWithTag tag: Int) {
        sock.readData(withTimeout: -1, tag: tag)
    }
    
    func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        delegate?.socketManager(didDisconnectWithError: err)
    }
}
