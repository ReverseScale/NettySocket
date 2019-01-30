//
//  ServerViewController.swift
//  testSocket
//
//  Created by BobChang on 18/05/2017.
//  Copyright © 2017 iirlab. All rights reserved.
//

import UIKit
import CocoaAsyncSocket

class ServerController: UIViewController {

    var serverSocket: GCDAsyncSocket?
    var clientSocket: GCDAsyncSocket?
    
    @IBOutlet weak var portTextField: UITextField!
    
    @IBOutlet weak var messageTextField: UITextField!
    
    @IBOutlet weak var logsTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.logsTextView.text = ""
        
        self.portTextField.delegate   = self
        self.messageTextField.delegate = self
    }
    
    @IBAction func listeningAction(_ sender: Any) {
        
        serverSocket = GCDAsyncSocket(delegate: self, delegateQueue: DispatchQueue.main)
        
        do {
            try serverSocket?.accept(onPort: UInt16(portTextField.text!)!)
            addLogText("监听成功")
        }catch _ {
            addLogText("监听失败")
        }

    }
    
    @IBAction func sendAction(_ sender: Any) {
        
        let data = messageTextField.text?.data(using: String.Encoding.utf8)
        clientSocket?.write(data!, withTimeout: -1, tag: 0)
        
        addLogText("发送：\(messageTextField.text!)")
        messageTextField.text = ""

    }

    func addLogText(_ text: String) {
        logsTextView.text = logsTextView.text.appendingFormat("%@\n", text)
    }
}

extension ServerController: GCDAsyncSocketDelegate {

    /// Socket 接受连接时调用
    func socket(_ sock: GCDAsyncSocket, didAcceptNewSocket newSocket: GCDAsyncSocket) {
        
        addLogText("连接成功")
        addLogText("连接地址" + newSocket.connectedHost!)
        addLogText("端口号" + String(newSocket.connectedPort))
        clientSocket = newSocket
        
        clientSocket!.readData(withTimeout: -1, tag: 0)
    }
    
    /// Socket 完成将请求的数据读入内存时调用
    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        let message = String(data: data,encoding: String.Encoding.utf8)
        addLogText("接收：\(message!)")

        sock.readData(withTimeout: -1, tag: 0)
    }
    
}

extension ServerController: UITextFieldDelegate {
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        textField.resignFirstResponder()
        return true
    }
}
