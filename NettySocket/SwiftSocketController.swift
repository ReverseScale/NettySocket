//
//  SwiftSocketController.swift
//  NettySocket
//
//  Created by Steven Xie on 2019/1/30.
//  Copyright © 2019 Steven Xie. All rights reserved.
//

import UIKit
import SwiftSocket

class SwiftSocketController: UIViewController {

    @IBOutlet weak var logsTextView: UITextView!
    
    let host = "apple.com"
    let port = 80
    
    var client: TCPClient?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        client = TCPClient(address: host, port: Int32(port))
    }
    
    @IBAction func sendButtonAction() {
        guard let client = client else { return }
        
        switch client.connect(timeout: 10) {
        case .success:
            addLogText("连接到主机 \(client.address)")
            if let response = sendRequest(string: "GET / HTTP/1.0\n\n", using: client) {
                addLogText("响应: \(response)")
            }
        case .failure(let error):
            addLogText(String(describing: error))
        }
    }
    
    private func sendRequest(string: String, using client: TCPClient) -> String? {
        addLogText("发送数据 ... ")
        
        switch client.send(string: string) {
        case .success:
            return readResponse(from: client)
        case .failure(let error):
            addLogText(String(describing: error))
            return nil
        }
    }
    
    private func readResponse(from client: TCPClient) -> String? {
        guard let response = client.read(1024*10) else { return nil }
        
        return String(bytes: response, encoding: .utf8)
    }
    
    func addLogText(_ text: String) {
        logsTextView.text = logsTextView.text.appending("\n\(text)")
    }

}
