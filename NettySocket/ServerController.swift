//
//  ServerController.swift
//  NettySocket
//
//  Created by Steven Xie on 2019/1/30.
//  Copyright © 2019 Steven Xie. All rights reserved.
//

import UIKit
import CocoaAsyncSocket

class ServerController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    var serverSocket: GCDAsyncSocket?
    var clientSocket: GCDAsyncSocket?
    
    var fileURL: URL!
    var filePath: Any!
    
    var count = 0
    var currentPacketHead: [String:AnyObject] = [:]
    var packetLength: UInt!
    
    @IBOutlet weak var portTextField: UITextField!
    
    @IBOutlet weak var messageTextField: UITextField!
    
    @IBOutlet weak var logsTextView: UITextView!
    
    @IBOutlet weak var serverImageView: UIImageView!
    
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
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        portTextField.resignFirstResponder()
        messageTextField.resignFirstResponder()
    }
}

extension ServerController: GCDAsyncSocketDelegate {

    /// 接受连接时调用
    func socket(_ sock: GCDAsyncSocket, didAcceptNewSocket newSocket: GCDAsyncSocket) {
        
        addLogText("连接成功")
        addLogText("连接地址：" + newSocket.connectedHost!)
        addLogText("端口号：" + String(newSocket.connectedPort))
        clientSocket = newSocket
        
        clientSocket!.readData(withTimeout: -1, tag: 0)
    }
    
    /// 完成将请求的数据读入内存时调用
    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        
        count = count + 1
        print("data.count: \(data.count)")

        let dataString: String = String(data: data as Data, encoding: String.Encoding.utf8)!
        addLogText("接收：\(dataString)")

        if currentPacketHead.isEmpty {
            
            print(count)
            print("currentPacketHead.isEmpty")
            print(dataString)
            
            do {
                currentPacketHead = try JSONSerialization.jsonObject(with: data , options: JSONSerialization.ReadingOptions.allowFragments) as! [String : AnyObject]
                let type:String = currentPacketHead["type"] as! String
                print("type \(type)")
                
                if currentPacketHead.isEmpty {
                    print("error:currentPacketHead.isEmpty")
                    return
                }
                packetLength = currentPacketHead["size"] as? UInt
                print("packet Length: \(packetLength ?? 0)")
                sock.readData(toLength: UInt(packetLength), withTimeout: -1, tag: 0)
                return
                
            } catch let error as NSError {
                print(error)
            }
            
        } else {
            
            print(count)
            print("currentPacketHead not Empty")
            //print(dataString)
            
            let packetLength2:UInt = currentPacketHead["size"] as! UInt
            
            if UInt(data.count) != packetLength2 {
                return;
            }
            let type2:String = currentPacketHead["type"] as! String
            print("type2 \(type2)")
            
            if type2 == "image" {
                
                let jsondic:[String:AnyObject] = convertStringToDictionary(text: dataString)!
                let strBase64 = jsondic["image"] as! String
                let dataDecoded:NSData = NSData(base64Encoded: strBase64 , options: NSData.Base64DecodingOptions(rawValue: 0))!
                let decodedimage:UIImage = UIImage(data: dataDecoded as Data)!
                serverImageView.image = decodedimage
                
            } else if type2 == "text" {
                addLogText(dataString)
            } else {
                
            }
            
            currentPacketHead = [:]
            
        }
        
        sock.readData(to: GCDAsyncSocket.crlfData(), withTimeout: -1, tag: 0)

    }
    
    func convertStringToDictionary(text: String) -> [String:AnyObject]? {
        if let data = text.data(using: String.Encoding.utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: [JSONSerialization.ReadingOptions.init(rawValue: 0)]) as? [String:AnyObject]
            } catch let error as NSError {
                print(error)
            }
        }
        return nil
    }
}

extension ServerController: UITextFieldDelegate {
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        textField.resignFirstResponder()
        return true
    }
}
