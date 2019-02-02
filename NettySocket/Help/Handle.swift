//
//  Handle.swift
//  NettySocket
//
//  Created by Steven Xie on 2019/2/2.
//  Copyright © 2019 Steven Xie. All rights reserved.
//

import UIKit

extension UIViewController {
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
