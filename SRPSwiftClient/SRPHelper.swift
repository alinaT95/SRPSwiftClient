//
//  SRPHelper.swift
//  SRPSwiftClient
//
//  Created by Alina Alinovna on 16.09.2021.
//

import Foundation
import CryptoKit
import BigInt
struct SRPRegistartionData {
    let userName: String
    let salt: Data
    let verifier: Data
    init(s: Data, uName: String, v: Data){
        self.salt = s
        self.userName = uName
        self.verifier = v
    }
}

struct SRPAuthServerData : Codable{
    var Salt: String
    var B: String
}

struct SRPAuthServerData2 : Codable{
    
}

struct SRPAuthClientData : Codable{
    let userName: String
    var A: String
}


class SRPHelper {

    var client: Client<SHA256>?
    
    init() throws {
    }
    
    func createRegistartionData(userName: String, password: String) throws -> SRPRegistartionData {
        let res: (salt: Data, verificationKey: Data) = createSaltedVerificationKey(using: SHA256.self, username: userName, password: password)
        return SRPRegistartionData(s: res.salt, uName: userName, v: res.verificationKey)
    }
    
    func startAuth(userName: String, password: String) throws  -> SRPAuthClientData {
        client = Client<SHA256>(username: userName, password: password)
        let res: (username: String, publicKey: Data) = client!.startAuthentication()
        let srpAurhData = SRPAuthClientData(userName: userName, A: res.publicKey.hexEncodedString())
        return srpAurhData
    }
    
    func finishAuth(salt: Data, B: Data ) throws -> Data  {
        let M = try client!.processChallenge(salt: salt, publicKey: B)
        print("CS = " + client!.S!.hexEncodedString())
        return M
    }
    
    func generateRandomBytes(count: Int) -> Data? {
        var bytes = [UInt8](repeating: 0, count: count)
        let result = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)

        guard result == errSecSuccess else {
            print("Problem generating random bytes")
            return nil
        }

        return Data(bytes)
    }

    
    
}
