//
//  Socket.swift
//  SRPSwiftClient
//
//  Created by Alina Alinovna on 18.09.2021.
//

import Foundation

public typealias Byte = UInt8

open class Socket {
  
    public let address: String
    internal(set) public var port: Int32
    internal(set) public var fd: Int32?
  
    public init(address: String, port: Int32) {
        self.address = address
        self.port = port
    }
  
}

public enum SocketError: Error {
    case queryFailed
    case connectionClosed
    case connectionTimeout
    case unknownError
}
