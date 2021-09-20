//
//  JSONHelper.swift
//  SRPSwiftClient
//
//  Created by Alina Alinovna on 18.09.2021.
//

import Foundation

class JSONHelper {
    static func createPwRegMsg1JSon(_ regData: SRPRegistartionData) throws -> String {
            var data: [String : String] = [:]
            data["userName"] = regData.userName
            data["salt"] = regData.salt.hexEncodedString()
            data["verifier"] = regData.verifier.hexEncodedString()
            let jsonData = try JSONSerialization.data(withJSONObject: data)
            let jsonString = String(data: jsonData, encoding: .utf8)!
            print("Prepared registration data for Server:")
            print(jsonString)
            return jsonString
        }
    static func createAuthMsg1JSon(_ authData: SRPAuthClientData) throws -> String {
            var data: [String : String] = [:]
            data["A"] = authData.A
            data["userName"] = authData.userName
            let jsonData = try JSONSerialization.data(withJSONObject: data)
            let jsonString = String(data: jsonData, encoding: .utf8)!
            print("Prepared auth data for Server:")
            print(jsonString)
            return jsonString
        }
}


