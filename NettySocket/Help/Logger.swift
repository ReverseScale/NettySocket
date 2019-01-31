//
//  Logger.swift
//  NettySocket
//
//  Created by Steven Xie on 2019/1/31.
//  Copyright © 2019 Steven Xie. All rights reserved.
//

import Foundation
import os.log

struct Logger {
    
    static func log(_ string: String) {
        NSLog("SHARE_EXTENSION_LOGGER: \(string)")
    }
    
    @discardableResult
    init(identifier: String, message: String) {
        #if DEBUG || DEVDEBUG || QADEBUG || PRODDEBUG
        NSLog("[\(identifier)] \(message)")
        #endif
    }
    
    static func log(subsystem: String, category: String, message: String) {
        let log = OSLog(subsystem: subsystem, category: category)
        
        #if DEBUG || DEVDEBUG || QADEBUG || PRODDEBUG
        os_log("%@", log: log, type: .debug, message)
        #else
        os_log("%@", log: log, type: .default, message)
        #endif
    }
    
}

