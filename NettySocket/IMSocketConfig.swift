//
//  IMSocketConfig.swift
//  NettySocket
//
//  Created by Steven Xie on 2019/2/1.
//  Copyright © 2019 Steven Xie. All rights reserved.
//

import Foundation

// 发送心跳时间间隔
let heartBeatTimeinterval = 40
// 重链接次数
let kMaxReconnection_time = 6
// 心跳回调最大限度
let beatLimit = 5
// 超时
let timeOut = 10


//MARK: - Properties
fileprivate let kSocketHost: String = "192.168.20.95"
fileprivate let kSocketPort: UInt16 = 9999

enum SocketRequestType: Int {
    case CmdTypeNone = 0 // 未登录
    case CmdTypeConnectRequest = 1 // 连接请求
    case CmdTypeConnectSuccessBack = 2 // 连接请求 正确 回调
    case CmdTypeHeartBeatRequest   = 3 // 心跳请求][i6
    case CmdTypeHeartBeatSuccessBack     = 4 // 心跳请求 正确 回调
    case CmdTypeLocFuncRequest   = 5  //功能本地调用(相对于 7)
    case CmdTypeLocFuncSuccessBack      = 6 // 功能本地调用 正确 回调
    case CmdTypeLongDistanceFuncRequest  = 7 // 功能远程调用
    case CmdTypeLongDistanceFuncBack = 8 // 功能远程调用 正确 回调
    case CmdTypeEnterBackgroundRequest   = 9 // APP切到后台
    case CmdTypeNotify       = 10 // 消息更新提示
    case CmdTypeMessage      = 11 // 推送更新内容
    case CmdTypeSystemActionRequest = 12 // 系统操作消息
    case CmdTypeActionBack   = 13 // 系统操作确认
}
