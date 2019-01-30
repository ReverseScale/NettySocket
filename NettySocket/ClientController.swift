//
//  ClientViewController.swift
//  testSocket
//
//  Created by BobChang on 18/05/2017.
//  Copyright © 2017 iirlab. All rights reserved.
//

import UIKit
import CocoaAsyncSocket

class ClientController: UIViewController {
    
    var socket: GCDAsyncSocket?
    
    @IBOutlet weak var ipTextField: UITextField!
    
    @IBOutlet weak var portTexField: UITextField!
    
    @IBOutlet weak var messageTextField: UITextField!
    
    @IBOutlet weak var logsTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.logsTextView.text = ""
        
        self.ipTextField.delegate   = self
        self.portTexField.delegate = self
        self.messageTextField.delegate  = self
        
        serializationData()
    }
    
    func serializationData() {
        
        let person = Person.Builder()
        person.name = "南小鸟"
        person.age = 18
        person.friends = [10]
        
        let data = person.getMessage().data()

        let result = try! Person.parseFrom(data: data)

        print(result)
    }
    
//    func deserialization() {
//    }
    
    @IBAction func connectionAction(_ sender: Any) {
        
        socket = GCDAsyncSocket(delegate: self, delegateQueue: DispatchQueue.main)
        
        do {
            try socket?.connect(toHost: ipTextField.text!, onPort: UInt16(portTexField.text!)!)
            addLogText("连接成功")
        }catch _ {
            addLogText("连接失败")
        }

    }
    
    @IBAction func disconnectAction(_ sender: Any) {
        
        socket?.disconnect()
        addLogText("断开连接")
        
    }
    
    @IBAction func sendMessageAction(_ sender: Any) {
        
        socket?.write((messageTextField.text?.data(using: String.Encoding.utf8))!, withTimeout: -1, tag: 0)
        addLogText("我发送了：\(messageTextField.text!)")
        messageTextField.text = ""

    }

    func addLogText(_ text: String) {
        logsTextView.text = logsTextView.text.appendingFormat("%@\n", text)
    }
}

extension ClientController: GCDAsyncSocketDelegate {
    
    func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        addLogText("连接服务器" + host)
        self.socket?.readData(withTimeout: -1, tag: 0)
    }
    
    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        let message = String(data: data,encoding: String.Encoding.utf8)
        addLogText("接收：\(message!)")

        sock.readData(withTimeout: -1, tag: 0)
    }
    
}

extension ClientController: UITextFieldDelegate {
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        textField.resignFirstResponder()
        return true
    }
}
