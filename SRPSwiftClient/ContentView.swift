//
//  ContentView.swift
//  SRPSwiftClient
//
//  Created by Alina Alinovna on 16.09.2021.
//

import SwiftUI
import PromiseKit

struct ContentView: View {
    @State var username: String = "Alina"
    @State var password: String = "qwerty"
    
    let ipServer = "127.0.0.1"//"94.180.60.101"
    let port = 9999
    let srpHelper: SRPHelper?
    let decoder = JSONDecoder()
    
    init() {
        do {
            srpHelper = try SRPHelper()
        }
        catch{
            srpHelper = nil
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Username")
                .font(.callout)
                .bold()
            TextField("Enter username...", text: $username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }.padding()
        
        VStack(alignment: .leading) {
            Text("Password")
                .font(.callout)
                .bold()
            TextField("Enter password...", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }.padding()
        
        Button(action: {
            print("\n \n Start sign up...")
            let client = TCPClient(address: ipServer, port: Int32(port))
            switch client.connect(timeout: 100) {
            case .success:
                print("Connected to server...")
                Promise<Data> { promise in
                    print("Start client registration...")
                    let regData = try srpHelper!.createRegistartionData(userName: username, password: password)
                    let regDataJson = try JSONHelper.createPwRegMsg1JSon(regData)
                    
                    print("===============================")
                    var dataFinal = Data("pwreg\n".bytes)
                    dataFinal.append(contentsOf: regDataJson.bytes)
                    dataFinal.append(contentsOf: "\n".bytes)
                    
                    switch client.send(data: dataFinal) {
                    case .success:
                        print("Registration request was sent succesfully.")
                        promise.fulfill(Data(_ : []))
                    case .failure(let error):
                        print("Registration init request was failed.")
                        print(error)
                        promise.reject(error)
                    }
                }
                .then{(response : Data)  -> Promise<Data> in
                    return Promise { promise in
                        guard let data = client.read(1024*10, timeout: 100) else {
                            promise.reject(NSError(domain:"", code:0, userInfo: [NSLocalizedDescriptionKey: "Can not read data from server."]))
                            return
                        }
                        if let response = String(bytes: data, encoding: .utf8) {
                            print("Got json from server:")
                            print(response)
                            if (response == "ok") {
                                promise.fulfill(Data(_ :data))
                            }
                            else {
                                promise.reject(NSError(domain:"", code:0, userInfo: [NSLocalizedDescriptionKey: "Regitration is not done: " + response] ))
                            }
                        }
                        else{
                            promise.reject(NSError(domain:"", code:0, userInfo: [NSLocalizedDescriptionKey: "Data from server is corrupted."] ))
                        }
                    }
                    
                }
                .done{response in
                    print("Done")
                    let alert = UIAlertController(title: "Notification", message: "User password was registered on server.", preferredStyle: UIAlertController.Style.alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                    //self.present(alert, animated: true, completion: nil)
                }
                .catch{ error in
                    print("Error happened : " + error.localizedDescription)
                    let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: UIAlertController.Style.alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                    //self.present(alert, animated: true, completion: nil)
                }
            case .failure(let error):
                print("Can not establish TCP connection with server having IP address " + ipServer + ".")
            }
        }) {
            Text("SignUp")
                .foregroundColor(.purple)
                .font(.title)
                .padding()
                .border(Color.purple, width: 5)
        }
        
        
        
        Button(action: {
            print("\n \n Start log in...")
            let client = TCPClient(address: ipServer, port: Int32(port))
            switch client.connect(timeout: 100) {
            case .success:
                print("Connected to server...")
                Promise<Data> { promise in
                    print("Start client authentication...")
                    print("===============================")
    
                    var dataFinal = Data("auth\n".bytes)
                    
                    let authData = try srpHelper!.startAuth(userName: username, password: password)
                    let authClientDataJson = try JSONHelper.createAuthMsg1JSon(authData)
                    dataFinal.append(Data(authClientDataJson.bytes))
                    
                    dataFinal.append(contentsOf: "\n".bytes)
                    
                    switch client.send(data: dataFinal) {
                    case .success:
                        print("Authentication init request was sent succesfully.")
                        promise.fulfill(Data(_ : []))
                    case .failure(let error):
                        print("Authentication init request was failed.")
                        print(error)
                        promise.reject(error)
                    }
                    
                    promise.fulfill(Data(_ : []))
                    
                }
                .then{(dummyResponse : Data)  -> Promise<Data> in
                    return Promise { promise in
                        guard let data = client.read(1024*10, timeout: 100) else {
                            promise.reject(NSError(domain:"", code:0, userInfo: [NSLocalizedDescriptionKey: "Can not read data from server."]))
                            return
                        }
                        if let response = String(bytes: data, encoding: .utf8) {
                            if response.contains("No such user") {
                                promise.reject(NSError(domain:"", code:0, userInfo: [NSLocalizedDescriptionKey: "No such user on server."] ))
                            }
                            else {
                                print("Got json from server:")
                                print(response)
                                promise.fulfill(Data(_ :data))
                            }
                        }
                        else{
                            promise.reject(NSError(domain:"", code:0, userInfo: [NSLocalizedDescriptionKey: "Data from server is corrupted."] ))
                        }
                    }
                    
                }
                .then{(response : Data)  -> Promise<Data> in
                    return Promise { promise in
                        if let json = String(bytes: response, encoding: .utf8) {
                            print("HERE:")
                            print(json)
                            let parsed = try JSONDecoder().decode(SRPAuthServerData.self, from: response)
                            print("Parsed json from server:")
                            print(parsed)
                            
                            let M = try srpHelper!.finishAuth(salt: ByteArrayAndHexHelper.hex(from: parsed.Salt), B: ByteArrayAndHexHelper.hex(from: parsed.B))
                        
                            promise.fulfill(Data(_ : []))
                        }
                        else{
                            promise.reject(NSError(domain:"", code:44, userInfo:[NSLocalizedDescriptionKey: "Data from server is corrupted."]))
                        }
                    }
                }
                .done{response in
                    print("Done")
                    let alert = UIAlertController(title: "Notification", message: "User was authenticated on server.", preferredStyle: UIAlertController.Style.alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                   // self.present(alert, animated: true, completion: nil)
                }
                .catch{ error in
                    print("Error happened : " + error.localizedDescription)
                    let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: UIAlertController.Style.alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                    //self.present(alert, animated: true, completion: nil)
                }
            case .failure(let error):
                print("Can not establish TCP connection with server having IP address " + ipServer + ".")
            }
        }) {
            Text("LogIn")
                .foregroundColor(.purple)
                .font(.title)
                .padding()
                .border(Color.purple, width: 5)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
