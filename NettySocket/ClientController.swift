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
    
    var tcpSocket: GCDAsyncSocket?
    
    var fileURL: URL!
    var filePath: Any!
    
    var test7str: String!
    var test7data: Data!
    
    var mData: NSMutableData!
    var jsonData: Data!
    var imageData: Data!
    var imageDict: [String:Any] = [:]
    
    //MARK: - Properties
//    fileprivate let kSocketHost: String = "192.168.20.95"
//    fileprivate let kSocketPort: UInt16 = 9999
    
    //MARK: - IBOutlet's
    @IBOutlet weak var ipTextField: UITextField!
    
    @IBOutlet weak var portTexField: UITextField!
    
    @IBOutlet weak var messageTextField: UITextField!
    
    @IBOutlet weak var logsTextView: UITextView!
    
    @IBOutlet weak var serverImageView: UIImageView!
    
    @IBOutlet weak var stateView: UIView!
    
    @IBOutlet weak var stateLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.logsTextView.text = ""
        
        self.ipTextField.delegate = self
        self.portTexField.delegate = self
        self.messageTextField.delegate = self
        
        start()
        
        builderHandleData()
    }
    
    private func start() {
        setupDelegates()
    }
    
    private func setupDelegates() {
        IMSocketManager.shared.delegate = self
    }
    
    /// builder 处理
    func builderHandleData() {
        
        let person = Person.Builder()
        person.name = "南小鸟"
        person.age = 18
        person.friends = [10]
        
        let data = person.getMessage().data()
        let result = try! Person.parseFrom(data: data)

        print(result)
    }
    
    /// 获取相册资源
    @IBAction func openPickerAction(_ sender: Any) {
        
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary){
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = .photoLibrary
            imagePicker.allowsEditing = true
            self.present(imagePicker, animated:true, completion: nil)
        }
        
    }
    
    /// 处理要发送图片
    @IBAction func sendImageAction(_ sender: Any) {
        
//        let uploadimg = serverImageView.image
//        imageData = uploadimg!.jpegData(compressionQuality: 1) //UIImage to NSData
//        let imageData_Base64str = imageData.base64EncodedString()  //NSData to string
//        imageDict["image"] = imageData_Base64str    // dictionary
//
//        test7str = convertDictionaryToString(dict: imageDict as [String : AnyObject])
//
//        test7data = test7str.data(using: String.Encoding.utf8)
//
//        sendPhotoData(data: test7data as NSData, type: "image")
//
//        serverImageView.image = nil
        
        IMSocketManager.shared.sendImageMessage(messageImage: serverImageView.image!)

        serverImageView.image = nil

    }
    
    /// 发送图片数据
    func sendPhotoData(data: NSData,type: String){
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
        tcpSocket?.write(mData as Data, withTimeout: -1, tag: 0)
    }
    
    /// 连接
    @IBAction func connectionAction(_ sender: Any) {
        
//        tcpSocket = GCDAsyncSocket(delegate: self, delegateQueue: DispatchQueue.main)
//
//        do {
//            try tcpSocket?.connect(toHost: "192.168.125.4", onPort: UInt16(portTexField.text!)!)
//            addLogText("连接成功")
//        }catch _ {
//            addLogText("连接失败")
//        }
        
        updateViews(byConnectionState: .connecting)
//        IMSocketManager.shared.connect(host: kSocketHost, port: kSocketPort)
        
        IMSocketManager.shared.connect(host: ipTextField.text!, port: UInt16(portTexField.text!)!)

    }
    
    /// 断开
    @IBAction func disconnectAction(_ sender: Any) {
        
//        tcpSocket?.disconnect()
//        addLogText("断开连接")
        
        updateViews(byConnectionState: .disconnected)
        IMSocketManager.shared.disconnect()
        addLogText("断开连接")

    }
    
    /// 发消息
    @IBAction func sendMessageAction(_ sender: Any) {
        
//        let txtData:Data = (messageTextField.text?.data(using: String.Encoding.utf8))!
//        sendPhotoData(data: txtData as NSData, type: "text")
//        addLogText("我发送了：\(messageTextField.text!)")
//        messageTextField.text = ""

        if let messageString = messageTextField.text, !messageString.isEmpty {
            IMSocketManager.shared.sendMessage(messageString: messageString)
            addLogText("我发送了：\(messageTextField.text!)")
            messageTextField.text = ""
        }
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

    /// 打印日志
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
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        ipTextField.resignFirstResponder()
        portTexField.resignFirstResponder()
        messageTextField.resignFirstResponder()
    }
    
    fileprivate func updateViews(byConnectionState connectionState: ConnectionState) {
        switch connectionState {
        case .connecting:
            stateView.backgroundColor = .orange
            stateLabel.text = "连接"
            break
        case .connected:
            stateView.backgroundColor = .green
            stateLabel.text = "在线"
            break
        case .disconnected:
            stateView.backgroundColor = .gray
            stateLabel.text = "断开"
            break
        case .failedToConnect:
            stateView.backgroundColor = .red
            stateLabel.text = "错误"
            break
        }
    }
}

//extension ClientController: GCDAsyncSocketDelegate {
//
//    func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
//        addLogText("连接服务器" + host)
//        self.tcpSocket?.readData(withTimeout: -1, tag: 0)
//    }
//
//    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
//        let message = String(data: data,encoding: String.Encoding.utf8)
//        addLogText("接收：\(message!)")
//
//        sock.readData(withTimeout: -1, tag: 0)
//    }
//
//}

extension ClientController: UITextFieldDelegate {
    
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        textField.resignFirstResponder()
        return true
    }
    
}

extension ClientController: IMSocketManagerDelegate {
    func socketManager(didConnectToHost host: String, port: UInt16) {
        addLogText("连接成功")
        Logger(identifier: #file, message: "Connected to host: \(host), port: \(port)")
        updateViews(byConnectionState: .connected)
    }
    
    func socketManager(didDisconnectWithError err: Error?) {
        Logger(identifier: #file, message: "Socket disconnected with error: \(err?.localizedDescription ?? "")")
        updateViews(byConnectionState: .disconnected)
    }
    
    func socketManager(didReadString data: String, withTag tag: Int) {
        addLogText("接收：\(data)")
    }
    
    func socketManager(didFailToConnect failureMsg: String) {
        addLogText("连接失败")
        Logger(identifier: #file, message: "Failed to connect with failure message: \(failureMsg)")
        updateViews(byConnectionState: .failedToConnect)
    }
}
