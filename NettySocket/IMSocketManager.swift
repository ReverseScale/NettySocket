//
//  IMSocketManager.swift
//  NettySocket
//
//  Created by Steven Xie on 2019/1/31.
//  Copyright © 2019 Steven Xie. All rights reserved.
//

import UIKit
import CocoaAsyncSocket

protocol IMSocketManagerDelegate: class {
    /// 连接并准备好读写时调用
    func socketManager(didConnectToHost host: String, port: UInt16)
    /// 断开连接时调用
    func socketManager(didDisconnectWithError err: Error?)
    /// 完成将请求的数据读入内存时调用
    func socketManager(didReadString data: String, withTag tag: Int)
    /// 连接错误时调用
    func socketManager(didFailToConnect failureMsg: String)
}

typealias reconnetCompletionHandle = (Bool) ->()

class IMSocketManager: NSObject {

    static let shared = IMSocketManager()
    
    /// 为了后续业务上用户主动连接处理
    var reconncetStatusHandle: reconnetCompletionHandle?
    
    /// connect status：
    ///
    /// 1: connect
    /// -1: disconnect
    /// 0: connecting
    var connectStatus = 0
    var reconnectionCount = 0
    
    var beatTimer:Timer!
    var reconnectTimer:Timer!
    
    private var kSocketHost: String = ""
    private var kSocketPORT: UInt16 = 0
    
    private var tcpSocket: GCDAsyncSocket?
    weak var delegate: IMSocketManagerDelegate?
    
    /// 连接
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
    
    /// 断开连接
    func disconnect() {
        tcpSocket?.disconnect()
    }
    
    
    /// 用户主动重新连接（一般业务都有这个需求：断网后用户下拉）
    ///
    /// - Parameter handle: 回调处理
    public func getReconncetHandle(handle: @escaping reconnetCompletionHandle)  {
        self.reconncetStatusHandle = handle
        reconnection()
    }
    
    /// 发送消息
    ///
    /// - Parameter msg: 消息字符串
    /// 写入数据后发送 \r 或 \n 告诉流没有更多的数据(刷新)
    func sendMessage(messageString msg: String) {
        if let data = msg.data(using: .utf8), let carriageReturn = "\r".data(using: .utf8) {
            sendMessageData(data: data as NSData, type: "text")
            tcpSocket?.write(carriageReturn, withTimeout: -1, tag: 99)
        }
    }
    
    
    /// 发送 Builder 数据
    ///
    /// - Parameter data: Builder data
    func sendMessage(messageBuilder data: Data) {
        sendMessageData(data: data as NSData, type: "builder")
    }
    
    
    /// 发送图片
    ///
    /// - Parameter img: 图片
    func sendImageMessage(messageImage img: UIImage) {
        let imageData = img.jpegData(compressionQuality: 1)
        let imageData_Base64str = imageData!.base64EncodedString()
        var imageDict: [String:Any] = [:]

        imageDict["image"] = imageData_Base64str   
        
        let test7str = convertDictionaryToString(dict: imageDict as [String : AnyObject])
        
        let test7data = test7str.data(using: String.Encoding.utf8)
        
        sendMessageData(data: test7data! as NSData, type: "image")
    }
    
    /// 写入数据后发送 \r 或 \n 告诉流没有更多的数据
    func sendCommand(command: SocketManagerCommands) {
        if let data = command.rawValue.data(using: .utf8), let carriageReturn = "\r".data(using: .utf8) {
            tcpSocket?.write(data, withTimeout: -1, tag: 0)
            tcpSocket?.write(carriageReturn, withTimeout: -1, tag: 99)
        }
    }
    
    /// 发送数据
    func sendMessageData(data: NSData, type: String){
        let size = data.length
        print("size:\(size)")
        var headDic: [String:Any] = [:]
        headDic["type"] = type
        headDic["size"] = size
        let jsonStr = convertDictionaryToString(dict: headDic as [String : AnyObject])
        let lengthData = jsonStr.data(using: String.Encoding.utf8)
        let mData = NSMutableData.init(data: lengthData!)
        mData.append(GCDAsyncSocket.crlfData())
        mData.append(data as Data)
        
        print("mData.length \(mData.length)")
        tcpSocket?.write(mData as Data, withTimeout: -1, tag: 0)
    }
    
    // 长连接建立后 开始与服务器校验登录
    func socketDidConnectCreatLogin() {
        let login = ["c":"1","p":"ca5542d60da951afeb3a8bc5152211a7","d":"dev_"]
        guard let data: Data = try? Data(JSONSerialization.data(withJSONObject: login, options: JSONSerialization.WritingOptions(rawValue: 1))) else {
            return
        }
        sendMessageData(data: data as NSData, type: "Check")
        
        reconnectionCount = 0
        connectStatus = 1
        reconncetStatusHandle?(true)
        
        guard let timer = self.reconnectTimer else {
            return
        }
        timer.invalidate()
    }
    
    
    /// 长连接建立后 开始发送心跳包
    func socketDidConnectBeginSendBeat() {
        beatTimer = Timer.scheduledTimer(timeInterval: TimeInterval(heartBeatTimeinterval),
                                         target: self,
                                         selector: #selector(sendBeat),
                                         userInfo: nil,
                                         repeats: true)
        RunLoop.current.add(beatTimer, forMode: RunLoop.Mode.common)
        
    }
    
    /// 向服务器发送心跳包
    @objc func sendBeat() {
        let beat = ["c":"3"]
        guard let data: Data = try? Data(JSONSerialization.data(withJSONObject: beat, options: JSONSerialization.WritingOptions(rawValue: 1))) else {
            return
        }
        sendMessageData(data: data as NSData, type: "Beat")
    }
    
    
    /// 重新连接操作
    func socketDidDisconectBeginSendReconnect() -> Void {
        
        connectStatus = -1
        
        if reconnectionCount >= 0 && reconnectionCount < beatLimit  {
            reconnectionCount = reconnectionCount + 1
            timerInvalidate(timer: reconnectTimer)
            let time:TimeInterval = pow(2, Double(reconnectionCount))
            
            reconnectTimer = Timer.scheduledTimer(timeInterval: time,
                                                  target: self,
                                                  selector: #selector(reconnection),
                                                  userInfo: nil,
                                                  repeats: true)
            RunLoop.current.add(reconnectTimer, forMode: RunLoop.Mode.common)
            
        } else {
            reconnectionCount = -1
            reconncetStatusHandle?(false)
            
            timerInvalidate(timer: reconnectTimer)
        }
    }
    
    
    /// 重新连接 在网络状态不佳或者断网情况下把具体情况抛出去处理
    @objc func reconnection() -> Void {
        
        /**
         在瞬间切换到后台再切回程序时状态某些时候不改变
         但是未连接，所以添加一个重新连接时先断开连接
         */
        if connectStatus != -1 {
            disconnect()
        }
        
        // 重新初始化连接
        connect(host: kSocketHost, port: kSocketPORT)
        
    }
    
    func timerInvalidate(timer: Timer!) -> Void {
        guard let inTimer = timer else {
            return
        }
        inTimer.invalidate()
    }
}

extension IMSocketManager: GCDAsyncSocketDelegate {
    /// 连接并准备好读写时调用
    func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        delegate?.socketManager(didConnectToHost: host, port: port)
        socketDidConnectCreatLogin()
        socketDidConnectBeginSendBeat()
        sock.readData(withTimeout: -1, tag: 0)
    }
    
    /// 完成将请求的数据读入内存时调用
    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        if let stringData = String(bytes: data, encoding: .utf8) {
            delegate?.socketManager(didReadString: stringData, withTag: tag)
        }
        sock.readData(withTimeout: -1, tag: 0)
    }
    
    /// 完成写入请求的数据
    func socket(_ sock: GCDAsyncSocket, didWriteDataWithTag tag: Int) {
        sock.readData(withTimeout: -1, tag: tag)
    }
    
    /// 断开连接时调用
    func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        socketDidDisconectBeginSendReconnect()
        delegate?.socketManager(didDisconnectWithError: err)
    }
    
}

extension IMSocketManager {
    
    func convertDictionaryToString(dict:[String:AnyObject]) -> String {
        var result:String = ""
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dict, options: JSONSerialization.WritingOptions.init(rawValue: 0))
            
            if let JSONString = String(data: jsonData, encoding: String.Encoding.utf8) {
                result = JSONString
            }
            
        } catch {
            result = ""
        }
        return result
    }
    
}
