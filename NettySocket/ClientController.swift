//
//  ClientController.swift
//  NettySocket
//
//  Created by Steven Xie on 2019/1/30.
//  Copyright © 2019 Steven Xie. All rights reserved.
//

import UIKit
import CocoaAsyncSocket

class ClientController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var socket: GCDAsyncSocket?
    
    var fileURL: URL!
    var filePath: Any!
    
    var test7str: String!
    var test7data: Data!
    
    var mData: NSMutableData!
    var jsonData: Data!
    var imageData: Data!
    var imageDict: [String:Any] = [:]
    
    @IBOutlet weak var ipTextField: UITextField!
    
    @IBOutlet weak var portTexField: UITextField!
    
    @IBOutlet weak var messageTextField: UITextField!
    
    @IBOutlet weak var logsTextView: UITextView!
    
    @IBOutlet weak var serverImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.logsTextView.text = ""
        
        self.ipTextField.delegate = self
        self.portTexField.delegate = self
        self.messageTextField.delegate = self
        
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
    
    @IBAction func openPickerAction(_ sender: Any) {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary){
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = .photoLibrary
            imagePicker.allowsEditing = true
            self.present(imagePicker, animated:true, completion: nil)
        }
    }
    
    @IBAction func sendImageAction(_ sender: Any) {
        let uploadimg = serverImageView.image
        imageData = uploadimg!.jpegData(compressionQuality: 1) //UIImage to NSData
        let imageData_Base64str = imageData.base64EncodedString()  //NSData to string
        imageDict["image"] = imageData_Base64str    // dictionary
        
        test7str = convertDictionaryToString(dict: imageDict as [String : AnyObject])
        //print(test7str)
        //7-2
        test7data = test7str.data(using: String.Encoding.utf8)
        //print(test7data)
        //7-3
        //socket?.write(test7data, withTimeout: -1, tag: 0)
        //7-4
        sendPhotoData(data: test7data as NSData, type: "image")
        
        serverImageView.image = nil          //送出後移除image
    }
    
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
    
    /// 选择图片成功后代理
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        // 获取选择的原图
        let image = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
        
        
        filePath = NSTemporaryDirectory() + "savedImage.jpg"
        
        print("filepath: \(filePath ?? "")")
        
        if let dataToSave = image.jpegData(compressionQuality: 0.5) {
            fileURL = URL(fileURLWithPath: filePath as! String)
            do{
                try dataToSave.write(to: fileURL)
                print("save Image")
                serverImageView.image = UIImage(contentsOfFile:filePath as! String)!
                
            }catch{
                print("Can not save Image")
            }
        }
        
        // 图片控制器退出
        picker.dismiss(animated: true, completion: {
            () -> Void in
        })
    }

    func addLogText(_ text: String) {
        logsTextView.text = logsTextView.text.appendingFormat("%@\n", text)
    }
    
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
    
    func sendPhotoData(data:NSData,type:String){
        let size = data.length
        addLogText("size:\(size)")
        var headDic: [String:Any] = [:]
        headDic["type"] = type
        headDic["size"] = size
        let jsonStr = convertDictionaryToString(dict: headDic as [String : AnyObject])
        let lengthData = jsonStr.data(using: String.Encoding.utf8)
        mData = NSMutableData.init(data: lengthData!)
        mData.append(GCDAsyncSocket.crlfData())
        mData.append(data as Data)
        
        print("mData.length \(mData.length)")
        socket?.write(mData as Data, withTimeout: -1, tag: 0)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        ipTextField.resignFirstResponder()
        portTexField.resignFirstResponder()
        messageTextField.resignFirstResponder()
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
