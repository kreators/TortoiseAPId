
import Foundation
import PerfectLib
import PerfectHTTP
import PerfectCURL
import cURL
import MySQL

// MARK: - Synapsepay API

func getUser(id: String) -> [String:Any]? {
    guard let developerId = developerId, let developerSecret = developerSecret, let deviceFingerprint = deviceFingerprint else { return nil }
    let url = "https://sandbox.synapsepay.com/api/3/users/\(id)"
    let curl = CURL(url: url)
    curl.setOption(CURLOPT_HTTPHEADER, s: "Content-Type: application/json")
    curl.setOption(CURLOPT_HTTPHEADER, s: "X-SP-GATEWAY: \(developerId)|\(developerSecret)")
    curl.setOption(CURLOPT_HTTPHEADER, s: "X-SP-USER-IP: \(deviceIP)")
    curl.setOption(CURLOPT_HTTPHEADER, s: "X-SP-USER: |\(deviceFingerprint)")
    
    let response = curl.performFully()
    let responseCode = curl.responseCode
    curl.close()
    
    if responseCode == 200 {
        do {
            let str = UTF8Encoding.encode(bytes: response.2)
            let decoded = try str.jsonDecode() as? [String:Any]
            if let decodedJSON = decoded {
                return decodedJSON
            }
        } catch {
            print("Decode error: \(error)")
        }
    }
    return nil
}

func createSPUser(email: String, phoneNumber: String, legalName: String, tortoiseUserId: String) -> String? {
    guard let developerId = developerId, let developerSecret = developerSecret, let deviceFingerprint = deviceFingerprint else { return nil }
    var SPUserId: String? = nil
    let url = "https://sandbox.synapsepay.com/api/3/users"
    let curl = CURL(url: url)
    curl.setOption(CURLOPT_POST, int: 1)
    curl.setOption(CURLOPT_HTTPHEADER, s: "Content-Type: application/json")
    curl.setOption(CURLOPT_HTTPHEADER, s: "X-SP-GATEWAY: \(developerId)|\(developerSecret)")
    curl.setOption(CURLOPT_HTTPHEADER, s: "X-SP-USER-IP: \(deviceIP)")
    curl.setOption(CURLOPT_HTTPHEADER, s: "X-SP-USER: |\(deviceFingerprint)")
    
    let variables = ["logins":[["email":email]], "phone_numbers":[phoneNumber], "legal_names":[legalName], "extra":["cip_tag":1]] as [String : Any]
    var postParamString = try! variables.jsonEncodedString()
    let byteArray = [UInt8](postParamString.utf8)
    let _ = curl.setOption(CURLOPT_POSTFIELDS, v: UnsafeMutableRawPointer(mutating: byteArray))
    let _ = curl.setOption(CURLOPT_POSTFIELDSIZE, int: byteArray.count)
    
    let response = curl.performFully()
    let responseCode = curl.responseCode
    if responseCode == 200 {
        do {
            let str = UTF8Encoding.encode(bytes: response.2)
            let decoded = try str.jsonDecode() as? [String:Any]
            if let decodedJSON = decoded {
                if let refreshToken = decodedJSON["refresh_token"] as? String, let id = decodedJSON["_id"] as? String {
                    print(refreshToken, id)
                    SPUserId = id
                    let success = createSPUserRecord(id: id, email: email, tortoiseUserId: tortoiseUserId)
                    if success == false { SPUserId = nil }
                }
            }
        } catch {
            print("Decode error: \(error)")
        }
    }
    curl.close()
    return SPUserId
}


func oAuthSPUser(id: String) -> [String:Any]? {
    guard let developerId = developerId, let developerSecret = developerSecret, let deviceFingerprint = deviceFingerprint else { return nil }
    let url = "https://sandbox.synapsepay.com/api/3/oauth/\(id)"
    let curl = CURL(url: url)
    curl.setOption(CURLOPT_POST, int: 1)
    curl.setOption(CURLOPT_HTTPHEADER, s: "Content-Type: application/json")
    curl.setOption(CURLOPT_HTTPHEADER, s: "X-SP-GATEWAY: \(developerId)|\(developerSecret)")
    curl.setOption(CURLOPT_HTTPHEADER, s: "X-SP-USER-IP: \(deviceIP)")
    curl.setOption(CURLOPT_HTTPHEADER, s: "X-SP-USER: |\(deviceFingerprint)")
    
    guard let token = refreshToken(id: id) else {
        printlog(functionName: #function, logString: "nil refreshToken")
        return nil
    }
    
    let variables = ["refresh_token":token]
    var postParamString = try! variables.jsonEncodedString()
    let byteArray = [UInt8](postParamString.utf8)
    let _ = curl.setOption(CURLOPT_POSTFIELDS, v: UnsafeMutableRawPointer(mutating: byteArray))
    let _ = curl.setOption(CURLOPT_POSTFIELDSIZE, int: byteArray.count)
    
    let response = curl.performFully()
    let responseCode = curl.responseCode
    curl.close()
    
    if responseCode == 200 {
        do {
            let str = UTF8Encoding.encode(bytes: response.2)
            let decoded = try str.jsonDecode() as? [String:Any]
            if let decodedJSON = decoded {
                return decodedJSON
            }
        } catch {
            print("Decode error: \(error)")
        }
    }
    return nil
}


fileprivate func addKYCInfoToSPUser(id: String, params: [String:String]) -> Bool {
    guard let developerId = developerId, let developerSecret = developerSecret, let deviceFingerprint = deviceFingerprint else { return false }
    let url = "https://sandbox.synapsepay.com/api/3/users/\(id)"
    
    guard let SPUserAuthKey = oAuthKey(id: id) else { return false }
    guard let email = params["email"], let phoneNumber = params["phoneNumber"], let name = params["name"], let alias = params["alias"], let entityType = params["entityType"], let entityScope = params["entityScope"], let day = params["day"], let month = params["month"], let year = params["year"], let addressStreet = params["addressStreet"], let addressCity = params["addressCity"], let addressSubdivision = params["addressSubdivision"], let addressPostalCode = params["addressPostalCode"], let addressCountryCode = params["addressCountryCode"] else { return false }
    guard let intDay = Int(day), let intMonth = Int(month), let intYear = Int(year) else { return false }
    
    var authNeeded = false
    var success = false
    
    for _ in 0..<2 {
        authNeeded = false
        success = false
        let curl = CURL(url: url)
        curl.setOption(CURLOPT_POST, int: 1)
        curl.setOption(CURLOPT_CUSTOMREQUEST, s: "PATCH")
        curl.setOption(CURLOPT_HTTPHEADER, s: "Content-Type: application/json")
        curl.setOption(CURLOPT_HTTPHEADER, s: "X-SP-GATEWAY: \(developerId)|\(developerSecret)")
        curl.setOption(CURLOPT_HTTPHEADER, s: "X-SP-USER-IP: \(deviceIP)")
        curl.setOption(CURLOPT_HTTPHEADER, s: "X-SP-USER: \(SPUserAuthKey)|\(deviceFingerprint)")
        
        let variables = ["documents":[["email":email, "phone_number":phoneNumber, "ip":deviceIP, "name":name, "alias":alias, "entity_type":entityType, "entity_scope":entityScope, "day":intDay, "month":intMonth, "year":intYear, "address_street":addressStreet, "address_city":addressCity, "address_subdivision":addressSubdivision, "address_postal_code":addressPostalCode, "address_country_code":addressCountryCode]]]
        
        var postParamString = try! variables.jsonEncodedString()
        let byteArray = [UInt8](postParamString.utf8)
        let _ = curl.setOption(CURLOPT_POSTFIELDS, v: UnsafeMutableRawPointer(mutating: byteArray))
        let _ = curl.setOption(CURLOPT_POSTFIELDSIZE, int: byteArray.count)
        
        let response = curl.performFully()
        let responseCode = curl.responseCode
        curl.close()

        if responseCode == 200 {
            do {
                let str = UTF8Encoding.encode(bytes: response.2)
                let decoded = try str.jsonDecode() as? [String:Any]
                if let decodedJSON = decoded {
                    if let errorCode = decodedJSON["error_code"] as? String {
                        print(errorCode)
                        if errorCode == "110" {
                            _ = oAuthSPUser(id: id)
                            authNeeded = true
                        } else if errorCode == "0" {
                            return true
                        }
                    }
                }
            } catch {
                print("Decode error: \(error)")
            }
        } else {
            return false
        }
        if authNeeded == false { return true }
        if authNeeded == true && success == false { return false }
    }
    return true
}

func addACHUSLoginsToSPUser(id: String, params: [String:Any]) -> [[String:Any]]? {
    guard let developerId = developerId, let developerSecret = developerSecret, let deviceFingerprint = deviceFingerprint else { return nil }
    let url = "https://sandbox.synapsepay.com/api/3/users/\(id)/nodes"
    
    guard let type = params["type"] as? String, let bankId = params["bankId"] as? String, let bankPassword = params["bankPassword"] as? String, let bankName = params["bankName"] as? String else { return nil }
    
    var authNeeded = false
    var success = false
    
    for _ in 0..<2 {
        authNeeded = false
        success = false
        guard let SPUserAuthKey = oAuthKey(id: id) else { return nil }
        let curl = CURL(url: url)
        curl.setOption(CURLOPT_POST, int: 1)
        curl.setOption(CURLOPT_HTTPHEADER, s: "Content-Type: application/json")
        curl.setOption(CURLOPT_HTTPHEADER, s: "X-SP-GATEWAY: \(developerId)|\(developerSecret)")
        curl.setOption(CURLOPT_HTTPHEADER, s: "X-SP-USER-IP: \(deviceIP)")
        curl.setOption(CURLOPT_HTTPHEADER, s: "X-SP-USER: \(SPUserAuthKey)|\(deviceFingerprint)")
        
        let variables: [String:Any] = ["type":type, "info":["bank_id":bankId, "bank_pw":bankPassword, "bank_name":bankName]]
        var postParamString = try! variables.jsonEncodedString()
        let byteArray = [UInt8](postParamString.utf8)
        let _ = curl.setOption(CURLOPT_POSTFIELDS, v: UnsafeMutableRawPointer(mutating: byteArray))
        let _ = curl.setOption(CURLOPT_POSTFIELDSIZE, int: byteArray.count)
        
        let response = curl.performFully()
        let responseCode = curl.responseCode
        curl.close()

        if responseCode == 200 {
            do {
                let str = UTF8Encoding.encode(bytes: response.2)
                let decoded = try str.jsonDecode() as? [String:Any]
                if let decodedJSON = decoded {
                    if let errorCode = decodedJSON["error_code"] as? String {
                        print(errorCode)
                        if errorCode == "110" {
                            authNeeded = true
                        } else if errorCode == "0" {
                            if let nodes = decodedJSON["nodes"] as? [[String:Any]] {
                                print(nodes)
                                for node in nodes {
                                    if let nodeId = node["_id"] as? String {
                                        if let info = node["info"] as? [String:Any] {
                                            if let bankClass = info["class"] as? String {
                                                if bankClass == "CHECKING" {
                                                    success = updateNodeId(id: id, nodeId: nodeId)
                                                }
                                            }
                                        }
                                    }
                                }
                                return nodes
                            }
                        }
                    }
                }
            } catch {
                print("Decode error: \(error)")
            }
        } else if responseCode == 202 {
            do {
                let str = UTF8Encoding.encode(bytes: response.2)
                let decoded = try str.jsonDecode() as? [String:Any]
                if let decodedJSON = decoded {
                    if let errorCode = decodedJSON["error_code"] as? String {
                        if errorCode == "10" {
                            if let mfa = decodedJSON["mfa"] as? [String:String] {
                                return [["mfa":mfa]]
                            }
                        }
                    }
                }
            } catch {
                print("Decode error: \(error)")
            }
        }else {
            return nil
        }
        if authNeeded == true && success == false { return nil }
    }
    return nil
}

func addACHUSMFAToSPUser(id: String, params: [String:Any]) -> [[String:Any]]? {
    guard let developerId = developerId, let developerSecret = developerSecret, let deviceFingerprint = deviceFingerprint else { return nil }
    let url = "https://sandbox.synapsepay.com/api/3/users/\(id)/nodes"
    
    guard let accessToken = params["accessToken"] as? String, let mfaAnswer = params["mfaAnswer"] as? String else { return nil }
    
    var authNeeded = false
    var success = false
    
    for _ in 0..<2 {
        authNeeded = false
        success = false
        guard let SPUserAuthKey = oAuthKey(id: id) else { return nil }
        let curl = CURL(url: url)
        curl.setOption(CURLOPT_POST, int: 1)
        curl.setOption(CURLOPT_HTTPHEADER, s: "Content-Type: application/json")
        curl.setOption(CURLOPT_HTTPHEADER, s: "X-SP-GATEWAY: \(developerId)|\(developerSecret)")
        curl.setOption(CURLOPT_HTTPHEADER, s: "X-SP-USER-IP: \(deviceIP)")
        curl.setOption(CURLOPT_HTTPHEADER, s: "X-SP-USER: \(SPUserAuthKey)|\(deviceFingerprint)")
        
        let variables: [String:Any] = ["access_token":accessToken, "mfa_answer": mfaAnswer]
        var postParamString = try! variables.jsonEncodedString()
        let byteArray = [UInt8](postParamString.utf8)
        let _ = curl.setOption(CURLOPT_POSTFIELDS, v: UnsafeMutableRawPointer(mutating: byteArray))
        let _ = curl.setOption(CURLOPT_POSTFIELDSIZE, int: byteArray.count)
        
        let response = curl.performFully()
        let responseCode = curl.responseCode
        curl.close()
        
        if responseCode == 200 {
            do {
                let str = UTF8Encoding.encode(bytes: response.2)
                let decoded = try str.jsonDecode() as? [String:Any]
                if let decodedJSON = decoded {
                    if let errorCode = decodedJSON["error_code"] as? String {
                        print(errorCode)
                        if errorCode == "110" {
                            authNeeded = true
                        } else if errorCode == "0" {
                            if let nodes = decodedJSON["nodes"] as? [[String:Any]] {
                                print(nodes)
                                for node in nodes {
                                    if let nodeId = node["_id"] as? String {
                                        if let info = node["info"] as? [String:Any] {
                                            if let bankClass = info["class"] as? String {
                                                if bankClass == "CHECKING" {
                                                    success = updateNodeId(id: id, nodeId: nodeId)
                                                }
                                            }
                                        }
                                    }
                                }
                                return nodes
                            }
                        }
                    }
                }
            } catch {
                print("Decode error: \(error)")
            }
        } else if responseCode == 202 {
            do {
                let str = UTF8Encoding.encode(bytes: response.2)
                let decoded = try str.jsonDecode() as? [String:Any]
                if let decodedJSON = decoded {
                    if let errorCode = decodedJSON["error_code"] as? String {
                        if errorCode == "10" {
                            if let mfa = decodedJSON["mfa"] as? [String:String] {
                                return [["mfa":mfa]]
                            }
                        }
                    }
                }
            } catch {
                print("Decode error: \(error)")
            }
        }else {
            return nil
        }
        if authNeeded == true && success == false { return nil }
    }
    return nil
}

fileprivate func addTriumphSubaccountUSToSPUser(id: String, params: [String:Any]) -> Bool {
    guard let developerId = developerId, let developerSecret = developerSecret, let deviceFingerprint = deviceFingerprint else { return false }
    let url = "https://sandbox.synapsepay.com/api/3/users/\(id)/nodes"
    guard let type = params["type"] as? String, let nickname = params["nickname"] as? String else { return false }

    var authNeeded = false
    var success = false
    
    for _ in 0..<2 {
        authNeeded = false
        success = false
        guard let SPUserAuthKey = oAuthKey(id: id) else { return false }
        let curl = CURL(url: url)
        curl.setOption(CURLOPT_POST, int: 1)
        curl.setOption(CURLOPT_HTTPHEADER, s: "Content-Type: application/json")
        curl.setOption(CURLOPT_HTTPHEADER, s: "X-SP-GATEWAY: \(developerId)|\(developerSecret)")
        curl.setOption(CURLOPT_HTTPHEADER, s: "X-SP-USER-IP: \(deviceIP)")
        curl.setOption(CURLOPT_HTTPHEADER, s: "X-SP-USER: \(SPUserAuthKey)|\(deviceFingerprint)")
        
        let variables: [String:Any] = ["type":type, "info":["nickname":nickname]]
        var postParamString = try! variables.jsonEncodedString()
        let byteArray = [UInt8](postParamString.utf8)
        let _ = curl.setOption(CURLOPT_POSTFIELDS, v: UnsafeMutableRawPointer(mutating: byteArray))
        let _ = curl.setOption(CURLOPT_POSTFIELDSIZE, int: byteArray.count)
        
        let response = curl.performFully()
        let responseCode = curl.responseCode
        curl.close()
        
        if responseCode == 200 {
            do {
                let str = UTF8Encoding.encode(bytes: response.2)
                let decoded = try str.jsonDecode() as? [String:Any]
                if let decodedJSON = decoded {
                    if let errorCode = decodedJSON["error_code"] as? String {
                        print(errorCode)
                        if errorCode == "110" {
                            authNeeded = true
                        } else if errorCode == "0" {
                            if let nodes = decodedJSON["nodes"] as? [[String:Any]] {
                                if let firstNode = nodes.first {
                                    if let accountId = firstNode["_id"] as? String {
                                        success = updateTriumphSubaccountUS(id: id, accountType: "TRIUMPH-SUBACCOUNT-US", accountId: accountId)
                                    }
                                }
                            }
                        }
                    }
                }
            } catch {
                print("Decode error: \(error)")
            }
        } else {
            return false
        }
        if authNeeded == false { return true }
        if authNeeded == true && success == false { return false }
    }
    return success
}

fileprivate func sendMoneyToBank(id: String, params: [String:Any]) -> Bool {
    guard let developerId = developerId, let developerSecret = developerSecret, let deviceFingerprint = deviceFingerprint else { return false }
    guard let bankidForSPUser = bankid(id: id), let triumphidForSPUser = triumphid(id: id) else { return false }
    let url = "https://sandbox.synapsepay.com/api/3/users/\(id)/nodes/\(triumphidForSPUser)/trans"
    guard let amountParam = params["amount"] as? String, let currency = params["currency"] as? String, let timezone = params["timezone"] as? String else { return false }
    guard let amount = Double(amountParam) else { return false }

    var authNeeded = false
    var success = false
    
    for _ in 0..<2 {
        authNeeded = false
        success = false
        guard let SPUserAuthKey = oAuthKey(id: id) else { return false }
        let curl = CURL(url: url)
        curl.setOption(CURLOPT_POST, int: 1)
        curl.setOption(CURLOPT_HTTPHEADER, s: "Content-Type: application/json")
        curl.setOption(CURLOPT_HTTPHEADER, s: "X-SP-GATEWAY: \(developerId)|\(developerSecret)")
        curl.setOption(CURLOPT_HTTPHEADER, s: "X-SP-USER-IP: \(deviceIP)")
        curl.setOption(CURLOPT_HTTPHEADER, s: "X-SP-USER: \(SPUserAuthKey)|\(deviceFingerprint)")
        
        let variables: [String:Any] = ["to":["type":"ACH-US", "id":bankidForSPUser], "amount":["amount":amount, "currency":currency], "extra":["ip":deviceIP], "fees":[["fee":-0.20, "note":"Facilitator Fee", "to":["id":corpAccountId]]]]
        var postParamString = try! variables.jsonEncodedString()
        let byteArray = [UInt8](postParamString.utf8)
        let _ = curl.setOption(CURLOPT_POSTFIELDS, v: UnsafeMutableRawPointer(mutating: byteArray))
        let _ = curl.setOption(CURLOPT_POSTFIELDSIZE, int: byteArray.count)
        
        let response = curl.performFully()
        let responseCode = curl.responseCode
        curl.close()
        
        if responseCode == 200 {
            do {
                let str = UTF8Encoding.encode(bytes: response.2)
                let decoded = try str.jsonDecode() as? [String:Any]
                if let decodedJSON = decoded {
                    if let errorCode = decodedJSON["error_code"] as? String {
                        print(errorCode)
                        if errorCode == "110" {
                            authNeeded = true
                        }
                    } else {
                        guard let transactionId = decodedJSON["_id"] as? String else { return false }
                        success = createTransactionRecord(SPUserId: id, transactionId: transactionId, nodeFrom: triumphidForSPUser, nodeTo: bankidForSPUser, amount: String(amount), currency: currency)
                        if success {
                            createEMailRequest(mailType: "TransferToBankNotificationEMail", recipient: id, params: ["currency":currency, "amount":String(amount), "transactionId":transactionId, "timezone":timezone])
                        }
                    }
                }
            } catch {
                print("Decode error: \(error)")
            }
        } else {
            return false
        }
        if authNeeded == false { return true }
        if authNeeded == true && success == false { return false }
    }
    return success
}


fileprivate func receiveMoneyFromBank(id: String, params: [String:Any]) -> Bool {
    guard let developerId = developerId, let developerSecret = developerSecret, let deviceFingerprint = deviceFingerprint else { return false }
    guard let bankidForSPUser = bankid(id: id), let triumphidForSPUser = triumphid(id: id) else { return false }
    let url = "https://sandbox.synapsepay.com/api/3/users/\(id)/nodes/\(bankidForSPUser)/trans"
    guard let amountParam = params["amount"] as? String, let currency = params["currency"] as? String, let timezone = params["timezone"] as? String else { return false }
    guard let amount = Double(amountParam) else { return false }
    
    var authNeeded = false
    var success = false
    
    for _ in 0..<2 {
        authNeeded = false
        success = false
        guard let SPUserAuthKey = oAuthKey(id: id) else { return false }
        let curl = CURL(url: url)
        curl.setOption(CURLOPT_POST, int: 1)
        curl.setOption(CURLOPT_HTTPHEADER, s: "Content-Type: application/json")
        curl.setOption(CURLOPT_HTTPHEADER, s: "X-SP-GATEWAY: \(developerId)|\(developerSecret)")
        curl.setOption(CURLOPT_HTTPHEADER, s: "X-SP-USER-IP: \(deviceIP)")
        curl.setOption(CURLOPT_HTTPHEADER, s: "X-SP-USER: \(SPUserAuthKey)|\(deviceFingerprint)")

        let variables: [String:Any] = ["to":["type":"TRIUMPH-SUBACCOUNT-US", "id":triumphidForSPUser], "amount":["amount":amount, "currency":currency], "extra":["ip":deviceIP], "fees":[["fee":-0.20, "note":"Facilitator Fee", "to":["id":corpAccountId]]]]
        var postParamString = try! variables.jsonEncodedString()
        let byteArray = [UInt8](postParamString.utf8)
        let _ = curl.setOption(CURLOPT_POSTFIELDS, v: UnsafeMutableRawPointer(mutating: byteArray))
        let _ = curl.setOption(CURLOPT_POSTFIELDSIZE, int: byteArray.count)
        
        let response = curl.performFully()
        let responseCode = curl.responseCode
        curl.close()

        if responseCode == 200 {
            do {
                let str = UTF8Encoding.encode(bytes: response.2)
                let decoded = try str.jsonDecode() as? [String:Any]
                if let decodedJSON = decoded {
                    if let errorCode = decodedJSON["error_code"] as? String {
                        print(errorCode)
                        if errorCode == "110" {
                            authNeeded = true
                        }
                    } else {
                        guard let transactionId = decodedJSON["_id"] as? String else { return false }
                        success = createTransactionRecord(SPUserId: id, transactionId: transactionId, nodeFrom: bankidForSPUser, nodeTo: triumphidForSPUser, amount: String(amount), currency: currency)
                        if success {
                            createEMailRequest(mailType: "ManualDepositNotificationEMail", recipient: id, params: ["currency":currency, "amount":String(amount), "transactionId":transactionId, "timezone":timezone])
                        }
                    }
                }
            } catch {
                print("Decode error: \(error)")
            }
        } else {
            return false
        }
        if authNeeded == false { return true }
        if authNeeded == true && success == false { return false }
    }
    return success
}

fileprivate func getTriumphInformation(id: String) -> [String:Any]? {
    guard let developerId = developerId, let developerSecret = developerSecret, let deviceFingerprint = deviceFingerprint else { return nil }
    guard let triumphidForSPUser = triumphid(id: id) else { return nil }
    let url = "https://sandbox.synapsepay.com/api/3/users/\(id)/nodes/\(triumphidForSPUser)"
    
    var authNeeded = false
    var success = false
    
    for _ in 0..<2 {
        authNeeded = false
        success = false
        guard let SPUserAuthKey = oAuthKey(id: id) else { return nil }
        let curl = CURL(url: url)
        curl.setOption(CURLOPT_HTTPHEADER, s: "Content-Type: application/json")
        curl.setOption(CURLOPT_HTTPHEADER, s: "X-SP-GATEWAY: \(developerId)|\(developerSecret)")
        curl.setOption(CURLOPT_HTTPHEADER, s: "X-SP-USER-IP: \(deviceIP)")
        curl.setOption(CURLOPT_HTTPHEADER, s: "X-SP-USER: \(SPUserAuthKey)|\(deviceFingerprint)")

        let response = curl.performFully()
        let responseCode = curl.responseCode
        curl.close()
        
        if responseCode == 200 {
            do {
                let str = UTF8Encoding.encode(bytes: response.2)
                let decoded = try str.jsonDecode() as? [String:Any]
                if let decodedJSON = decoded {
                    if let errorCode = decodedJSON["error_code"] as? String {
                        if errorCode == "110" {
                            authNeeded = true
                        }
                    } else {
                        guard let _ = decodedJSON["_id"] else { return nil }
                        return decodedJSON
                    }
                }
            } catch {
                print("Decode error: \(error)")
            }
        } else {
            return nil
        }
        if authNeeded == true && success == false { return nil }
    }
    return nil
}

func deleteNode(id: String, nodeId: String) -> Bool {
    guard let developerId = developerId, let developerSecret = developerSecret, let deviceFingerprint = deviceFingerprint else { return false }
    let url = "https://sandbox.synapsepay.com/api/3/users/\(id)/nodes/\(nodeId)"
    
    guard let SPUserAuthKey = oAuthKey(id: id) else { return false }
    var authNeeded = false
    var success = false
    
    for _ in 0..<2 {
        authNeeded = false
        success = false
        let curl = CURL(url: url)
        curl.setOption(CURLOPT_POST, int: 1)
        curl.setOption(CURLOPT_CUSTOMREQUEST, s: "DELETE")
        curl.setOption(CURLOPT_HTTPHEADER, s: "Content-Type: application/json")
        curl.setOption(CURLOPT_HTTPHEADER, s: "X-SP-GATEWAY: \(developerId)|\(developerSecret)")
        curl.setOption(CURLOPT_HTTPHEADER, s: "X-SP-USER-IP: \(deviceIP)")
        curl.setOption(CURLOPT_HTTPHEADER, s: "X-SP-USER: \(SPUserAuthKey)|\(deviceFingerprint)")
        
        let response = curl.performFully()
        let responseCode = curl.responseCode
        curl.close()
        
        if responseCode == 200 {
            do {
                let str = UTF8Encoding.encode(bytes: response.2)
                let decoded = try str.jsonDecode() as? [String:Any]
                if let decodedJSON = decoded {
                    if let errorCode = decodedJSON["error_code"] as? String {
                        print(errorCode)
                        if errorCode == "110" {
                            _ = oAuthSPUser(id: id)
                            authNeeded = true
                        } else if errorCode == "0" {
                            return true
                        }
                    }
                }
            } catch {
                print("Decode error: \(error)")
            }
        } else {
            return false
        }
        if authNeeded == false { return true }
        if authNeeded == true && success == false { return false }
    }
    return true
}

fileprivate func selectBankAccount(id: String, params: [String:Any]) -> Bool {
    guard let nodeIdSelected = params["nodeIdSelected"] as? String, let nodeIdDiscard = params["nodeIdDiscard"] as? [String] else { return false }
    
    guard updateNodeId(id: id, nodeId: nodeIdSelected) == true else { return false }
    for nodeId in nodeIdDiscard {
        guard deleteNode(id: id, nodeId: nodeId) == true else { return false }
    }
    return true
}

// MARK: - DB Helpers

func createTortoiseUser(emailId: String, emailPassword: String, facebookId: String, facebookUsername: String?) -> String? {
    let mysql = MySQL()
    _ = mysql.setOption(MySQLOpt.MYSQL_SET_CHARSET_NAME, "utf8")
    let connected = mysql.connect(host: "tortoisedb.cgk0b55tapo1.us-east-1.rds.amazonaws.com", user: "root", password: "Saturn!07", db: "TORTOISE")
    
    guard connected else {
        printlog(functionName: #function, logString: mysql.errorMessage())
        return nil
    }
    
    defer { mysql.close() }
    
    if let facebookUsername = facebookUsername {
        let checkQuerySuccess = mysql.query(statement: "SELECT id FROM User WHERE facebookId = '\(facebookId)'")
        guard checkQuerySuccess else {
            return nil
        }
        
        let checkResults = mysql.storeResults()!
        if checkResults.numRows() > 0 {
            return "duplicated facebookId"
        }
        checkResults.close()
        
        let insertQuery = "INSERT INTO User (emailId, facebookId, facebookUsername, dateCreated) VALUES ('\(emailId)', '\(facebookId)', '\(facebookUsername)', NOW())"
        let querySuccess = mysql.query(statement: insertQuery)
        guard querySuccess else {
            printlog(functionName: #function, logString: mysql.errorMessage())
            return nil
        }
        var userId: String?
        let selectQuerySuccess = mysql.query(statement: "SELECT id FROM User WHERE facebookId = '\(facebookId)'")
        guard selectQuerySuccess else {
            return nil
        }
        let results = mysql.storeResults()!
        while let row = results.next() {
            userId = row[0]
        }
        return userId
    } else {
        let checkQuerySuccess = mysql.query(statement: "SELECT id FROM User WHERE emailId = '\(emailId)'")
        guard checkQuerySuccess else { return nil }
        let checkResults = mysql.storeResults()!
        if checkResults.numRows() > 0 {
            return "duplicated"
        }
        checkResults.close()
        let insertQuery = "INSERT INTO User (emailId, emailPassword, dateCreated) VALUES ('\(emailId)', '\(emailPassword)', NOW())"
        let querySuccess = mysql.query(statement: insertQuery)
        guard querySuccess else {
            printlog(functionName: #function, logString: mysql.errorMessage())
            return nil
        }
        var userId: String?
        let selectQuerySuccess = mysql.query(statement: "SELECT id FROM User WHERE emailId = '\(emailId)'")
        guard selectQuerySuccess else { return nil }
        let results = mysql.storeResults()!
        while let row = results.next() {
            userId = row[0]
        }
        results.close()
        return userId
    }
}

func loginTortoiseUserRecord(emailId: String?, emailPassword: String, facebookId: String) -> String? {
    let mysql = MySQL()
    let connected = mysql.connect(host: "tortoisedb.cgk0b55tapo1.us-east-1.rds.amazonaws.com", user: "root", password: "Saturn!07", db: "TORTOISE")
    
    guard connected else {
        printlog(functionName: #function, logString: mysql.errorMessage())
        return nil
    }
    
    defer { mysql.close() }
    
    if let emailId = emailId {
        var userId: String?
        let selectQuerySuccess = mysql.query(statement: "SELECT id FROM User WHERE emailId = '\(emailId)' AND emailPassword = '\(emailPassword)'")
        guard selectQuerySuccess else { return nil }
        let results = mysql.storeResults()!
        while let row = results.next() {
            userId = row[0]
        }
        results.close()
        return userId
    } else {
        var userId: String?
        let selectQuerySuccess = mysql.query(statement: "SELECT id FROM User WHERE facebookId = '\(facebookId)'")
        guard selectQuerySuccess else { return nil }
        let results = mysql.storeResults()!
        while let row = results.next() {
            userId = row[0]
        }
        results.close()
        return userId
    }
}

func createSPUserRecord(id: String, email: String, tortoiseUserId: String) -> Bool {
    let mysql = MySQL()
    let connected = mysql.connect(host: "tortoisedb.cgk0b55tapo1.us-east-1.rds.amazonaws.com", user: "root", password: "Saturn!07", db: "TORTOISE")
    guard connected else {
        printlog(functionName: #function, logString: mysql.errorMessage())
        return false
    }
    defer { mysql.close() }
    
    let insertQuery = "INSERT INTO SPUser (SPid, SPemail, dateCreated) VALUES ('\(id)', '\(email)', NOW())"
    let querySuccess = mysql.query(statement: insertQuery)
    guard querySuccess else {
        printlog(functionName: #function, logString: mysql.errorMessage())
        return false
    }
    
    let updateQuery = "UPDATE User SET SPId = '\(id)', dateUpdated = NOW() WHERE id = '\(tortoiseUserId)'"
    let updateQuerySuccess = mysql.query(statement: updateQuery)
    guard updateQuerySuccess else {
        printlog(functionName: #function, logString: mysql.errorMessage())
        return false
    }
    return true
}

fileprivate func updateNodeId(id: String, nodeId: String) -> Bool {
    let mysql = MySQL()
    let connected = mysql.connect(host: "tortoisedb.cgk0b55tapo1.us-east-1.rds.amazonaws.com", user: "root", password: "Saturn!07", db: "TORTOISE")
    guard connected else {
        printlog(functionName: #function, logString: mysql.errorMessage())
        return false
    }
    defer { mysql.close() }
    
    let querySuccess = mysql.query(statement: "UPDATE SPUser SET bankid = '\(nodeId)', dateUpdated = NOW() WHERE SPid = '\(id)'")
    guard querySuccess else {
        printlog(functionName: #function, logString: mysql.errorMessage())
        return false
    }
    return true
}

fileprivate func updateTriumphSubaccountUS(id: String, accountType: String, accountId: String) -> Bool {
    let mysql = MySQL()
    let connected = mysql.connect(host: "tortoisedb.cgk0b55tapo1.us-east-1.rds.amazonaws.com", user: "root", password: "Saturn!07", db: "TORTOISE")
    guard connected else {
        printlog(functionName: #function, logString: mysql.errorMessage())
        return false
    }
    defer { mysql.close() }
    
    let querySuccess = mysql.query(statement: "UPDATE SPUser SET TRIUMPHSUBACCOUNTUSType = '\(accountType)', TRIUMPHSUBACCOUNTUSid = '\(accountId)', dateUpdated = NOW() WHERE SPid = '\(id)'")
    guard querySuccess else {
        printlog(functionName: #function, logString: mysql.errorMessage())
        return false
    }
    return true
}

fileprivate func bankid(id: String) -> String? {
    var bankid: String? = nil
    let mysql = MySQL()
    let connected = mysql.connect(host: "tortoisedb.cgk0b55tapo1.us-east-1.rds.amazonaws.com", user: "root", password: "Saturn!07", db: "TORTOISE")
    
    guard connected else {
        printlog(functionName: #function, logString: mysql.errorMessage())
        return bankid
    }
    
    defer { mysql.close() }
    
    let querySuccess = mysql.query(statement: "SELECT bankid FROM SPUser WHERE SPid = '\(id)'")
    guard querySuccess else { return nil }
    
    let results = mysql.storeResults()!
    while let row = results.next() {
        bankid = row[0]
    }
    results.close()
    return bankid
}

fileprivate func triumphid(id: String) -> String? {
    var triumphid: String? = nil
    let mysql = MySQL()
    let connected = mysql.connect(host: "tortoisedb.cgk0b55tapo1.us-east-1.rds.amazonaws.com", user: "root", password: "Saturn!07", db: "TORTOISE")
    
    guard connected else {
        printlog(functionName: #function, logString: mysql.errorMessage())
        return nil
    }
    
    defer { mysql.close() }
    
    let querySuccess = mysql.query(statement: "SELECT TRIUMPHSUBACCOUNTUSid FROM SPUser WHERE SPid = '\(id)'")
    guard querySuccess else { return nil }
    
    let results = mysql.storeResults()!
    while let row = results.next() {
        triumphid = row[0]
    }
    results.close()
    return triumphid
}

fileprivate func createTransactionRecord(SPUserId: String, transactionId: String, nodeFrom: String, nodeTo: String, amount: String, currency: String) -> Bool {
    let mysql = MySQL()
    let connected = mysql.connect(host: "tortoisedb.cgk0b55tapo1.us-east-1.rds.amazonaws.com", user: "root", password: "Saturn!07", db: "TORTOISE")
    guard connected else {
        printlog(functionName: #function, logString: mysql.errorMessage())
        return false
    }
    defer { mysql.close() }
    
    let insertQuery = "INSERT INTO SPTransaction (SPUserId, TransactionId, nodeFrom, nodeTo, amount, currency, dateCreated) VALUES ('\(SPUserId)', '\(transactionId)', '\(nodeFrom)', '\(nodeTo)', '\(amount)', '\(currency)', NOW())"
    let querySuccess = mysql.query(statement: insertQuery)
    guard querySuccess else {
        printlog(functionName: #function, logString: mysql.errorMessage())
        return false
    }
    return true
}

fileprivate func createEMailRequest(mailType: String, recipient: String, params: [String:String]) {
    let mysql = MySQL()
    let connected = mysql.connect(host: "tortoisedb.cgk0b55tapo1.us-east-1.rds.amazonaws.com", user: "root", password: "Saturn!07", db: "TORTOISE")
    guard connected else {
        printlog(functionName: #function, logString: mysql.errorMessage())
        return
    }
    defer { mysql.close() }
    
    do {
        let data = try JSONSerialization.data(withJSONObject: params, options: [])
        guard let payload = String(data: data, encoding:.utf8) else { return }
        let insertQuery = "INSERT INTO SendMailQueue (recipient, mailType, payload, dateCreated) VALUES ('\(recipient)', '\(mailType)', '\(payload)', NOW())"
        let querySuccess = mysql.query(statement: insertQuery)
        guard querySuccess else {
            print("\(#function) : \(mysql.errorMessage())")
            return
        }
    } catch {
        print("\(#function) : JSONSerialization")
    }
}

// MARK: - Handlers

func createTortoiseUserHandlerV1(request: HTTPRequest, _ response: HTTPResponse) {
    guard let decodedJSON = validateParams(request: request, response: response) else { return }
    guard let type = decodedJSON["type"] as? String else {
        let returnData = ["result":"fail", "data":"type error"]
        makeResponse(returnData: returnData, response: response)
        return
    }

    guard let emailId = decodedJSON["emailId"] as? String, let emailPassword = decodedJSON["emailPassword"] as? String, let facebookId = decodedJSON["facebookId"] as? String else {
        let returnData = ["result":"fail", "data":"invalid data"]
        makeResponse(returnData: returnData, response: response)
        return
    }
    let facebookUsername = decodedJSON["facebookUsername"] as? String
    let TortoiseUserId = type == "email" ? createTortoiseUser(emailId: emailId, emailPassword: emailPassword, facebookId: facebookId, facebookUsername: nil) : createTortoiseUser(emailId: emailId, emailPassword: emailPassword, facebookId: facebookId, facebookUsername: facebookUsername)
    
    var returnData: [String:Any] = [:]
    if let TortoiseUserId = TortoiseUserId {
        if TortoiseUserId == "duplicated" {
            returnData = ["result":"fail", "data":"duplicated"]
        } else if TortoiseUserId == "duplicated facebookId" {
            returnData = ["result":"fail", "data":"duplicated facebookId"]
        } else {
            returnData = ["result":"success", "data":["TortoiseUserId":TortoiseUserId]]
        }
    } else {
        returnData = ["result":"fail", "data":"operation failed"]
    }
    makeResponse(returnData: returnData, response: response)
}

func loginTortoiseUser(request: HTTPRequest, _ response: HTTPResponse) {
    guard let decodedJSON = validateParams(request: request, response: response) else { return }
    guard let type = decodedJSON["type"] as? String else {
        let returnData = ["result":"fail", "data":"type error"]
        makeResponse(returnData: returnData, response: response)
        return
    }
    
    guard let emailId = decodedJSON["emailId"] as? String, let emailPassword = decodedJSON["emailPassword"] as? String, let facebookId = decodedJSON["facebookId"] as? String else {
        let returnData = ["result":"fail", "data":"invalid data"]
        makeResponse(returnData: returnData, response: response)
        return
    }
    let TortoiseUserId = type == "email" ? loginTortoiseUserRecord(emailId: emailId, emailPassword: emailPassword, facebookId: facebookId) : loginTortoiseUserRecord(emailId: nil, emailPassword: emailPassword, facebookId: facebookId)

    var returnData: [String:Any] = [:]
    if let TortoiseUserId = TortoiseUserId {
        returnData = ["result":"success", "data":["TortoiseUserId":TortoiseUserId]]
    } else {
        returnData = ["result":"fail", "data":"Login Failed"]
    }
    makeResponse(returnData: returnData, response: response)
}


func createUserHandlerV1(request: HTTPRequest, _ response: HTTPResponse) {
    guard let decodedJSON = validateParams(request: request, response: response) else { return }
    guard let email = decodedJSON["email"] as? String, let phoneNumber = decodedJSON["phoneNumber"] as? String, let legalName = decodedJSON["legalName"] as? String, let tortoiseUserId = decodedJSON["tortoiseUserId"] as? String else {
        let returnData = ["result":"fail", "data":"good"]
        makeResponse(returnData: returnData, response: response)
        return
    }
    let SPUserId = createSPUser(email: email, phoneNumber: phoneNumber, legalName: legalName, tortoiseUserId: tortoiseUserId)
    
    var returnData: [String:Any] = [:]
    if let SPUserId = SPUserId {
        if let _ = oAuthSPUser(id: SPUserId) {
            returnData = ["result":"success", "data":["SPUserId":SPUserId]]
        } else {
            returnData = ["result":"fail", "data":"operation failed"]
        }
    } else {
        returnData = ["result":"fail", "data":"operation failed"]
    }
    makeResponse(returnData: returnData, response: response)
}

func addKYCInfoHandlerV1(request: HTTPRequest, _ response: HTTPResponse) {
    guard let decodedJSON = validateParams(request: request, response: response) else { return }
    guard let id = decodedJSON["id"] as? String, let email = decodedJSON["email"] as? String, let phoneNumber = decodedJSON["phoneNumber"] as? String, let name = decodedJSON["name"] as? String, let alias = decodedJSON["alias"] as? String, let entityType = decodedJSON["entityType"] as? String, let entityScope = decodedJSON["entityScope"] as? String, let day = decodedJSON["day"] as? String, let month = decodedJSON["month"] as? String, let year = decodedJSON["year"] as? String, let addressStreet = decodedJSON["addressStreet"] as? String, let addressCity = decodedJSON["addressCity"] as? String, let addressSubdivision = decodedJSON["addressSubdivision"] as? String, let addressPostalCode = decodedJSON["addressPostalCode"] as? String, let addressCountryCode = decodedJSON["addressCountryCode"] as? String else {
        let returnData = ["result":"fail", "data":"invalid data format"]
        makeResponse(returnData: returnData, response: response)
        return
    }
    let infoParams = ["email":email, "phoneNumber":phoneNumber, "name":name, "alias":alias, "entityType":entityType, "entityScope":entityScope, "day":day, "month":month, "year":year, "addressStreet":addressStreet, "addressCity":addressCity, "addressSubdivision":addressSubdivision, "addressPostalCode":addressPostalCode, "addressCountryCode":addressCountryCode]
    let success = addKYCInfoToSPUser(id: id, params: infoParams)
    
    var returnData: [String:Any] = [:]
    if success == true {
        returnData = ["result":"success", "data":"good"]
    } else {
        returnData = ["result":"fail", "data":"operation failed"]
    }
    makeResponse(returnData: returnData, response: response)
}

func addACHUSLoginsHandlerV1(request: HTTPRequest, _ response: HTTPResponse) {
    guard let decodedJSON = validateParams(request: request, response: response) else { return }
    guard let id = decodedJSON["id"] as? String, let bankId = decodedJSON["bankId"] as? String, let bankPassword = decodedJSON["bankPassword"] as? String, let bankName = decodedJSON["bankName"] as? String else {
        let returnData = ["result":"fail", "data":"invalid data"]
        makeResponse(returnData: returnData, response: response)
        return
    }
    
    let infoParams = ["type":"ACH-US", "bankId":bankId, "bankPassword":bankPassword, "bankName":bankName]
    var returnData: [String:Any] = [:]
    if let nodes = addACHUSLoginsToSPUser(id: id, params: infoParams) {
        returnData = ["result":"success", "data":nodes]
    } else {
        returnData = ["result":"fail", "data":"operation failed"]
    }
    makeResponse(returnData: returnData, response: response)
}

func addACHUSMFAHandlerV1(request: HTTPRequest, _ response: HTTPResponse) {
    guard let decodedJSON = validateParams(request: request, response: response) else { return }
    guard let id = decodedJSON["id"] as? String, let accessToken = decodedJSON["access_token"] as? String, let mfaAnswer = decodedJSON["mfa_answer"] as? String else {
        let returnData = ["result":"fail", "data":"invalid data"]
        makeResponse(returnData: returnData, response: response)
        return
    }
    
    let infoParams = ["accessToken":accessToken, "mfaAnswer":mfaAnswer]
    var returnData: [String:Any] = [:]
    if let nodes = addACHUSMFAToSPUser(id: id, params: infoParams) {
        returnData = ["result":"success", "data":nodes]
    } else {
        returnData = ["result":"fail", "data":"operation failed"]
    }
    makeResponse(returnData: returnData, response: response)
}

func selectBankAccounHandlerV1(request: HTTPRequest, _ response: HTTPResponse) {
    guard let decodedJSON = validateParams(request: request, response: response) else { return }
    guard let id = decodedJSON["id"] as? String, let nodeIdSelected = decodedJSON["nodeIdSelected"] as? String, let nodeIdDiscard = decodedJSON["nodeIdDiscard"] as? [String] else {
        let returnData = ["result":"fail", "data":"invalid data"]
        makeResponse(returnData: returnData, response: response)
        return
    }
    
    let infoParams: [String : Any] = ["nodeIdSelected":nodeIdSelected, "nodeIdDiscard":nodeIdDiscard]
    let success = selectBankAccount(id: id, params: infoParams)
    
    var returnData: [String:Any] = [:]
    if success == true {
        returnData = ["result":"success", "data":"good"]
    } else {
        returnData = ["result":"fail", "data":"operation failed"]
    }
    makeResponse(returnData: returnData, response: response)
}

func addTriumphSubaccountUSHandlerV1(request: HTTPRequest, _ response: HTTPResponse) {
    guard let decodedJSON = validateParams(request: request, response: response) else { return }
    guard let id = decodedJSON["id"] as? String else {
        let returnData = ["result":"fail", "data":"invalid data"]
        makeResponse(returnData: returnData, response: response)
        return
    }
    let infoParams = ["type":"TRIUMPH-SUBACCOUNT-US", "nickname":"Triumph SubAccount"]
    let success = addTriumphSubaccountUSToSPUser(id: id, params: infoParams)
    
    var returnData: [String:Any] = [:]
    if success == true {
        returnData = ["result":"success", "data":"good"]
    } else {
        returnData = ["result":"fail", "data":"operation failed"]
    }
    makeResponse(returnData: returnData, response: response)
}

func sendMoneyHandlerV1(request: HTTPRequest, _ response: HTTPResponse) {
    guard let decodedJSON = validateParams(request: request, response: response) else { return }
    guard let id = decodedJSON["id"] as? String, let amount = decodedJSON["amount"] as? String, let currency = decodedJSON["currency"] as? String, let timezone = decodedJSON["timezone"] as? String else {
        let returnData = ["result":"fail", "data":"invalid data"]
        makeResponse(returnData: returnData, response: response)
        return
    }
    let infoParams = ["amount":amount, "currency":currency, "timezone":timezone]
    let success = sendMoneyToBank(id: id, params: infoParams)
    
    var returnData: [String:Any] = [:]
    if success == true {
        returnData = ["result":"success", "data":"good"]
    } else {
        returnData = ["result":"fail", "data":"operation failed"]
    }
    makeResponse(returnData: returnData, response: response)
}

func receiveMoneyHandlerV1(request: HTTPRequest, _ response: HTTPResponse) {
    guard let decodedJSON = validateParams(request: request, response: response) else { return }
    guard let id = decodedJSON["id"] as? String, let amount = decodedJSON["amount"] as? String, let currency = decodedJSON["currency"] as? String, let timezone = decodedJSON["timezone"] as? String else {
        let returnData = ["result":"fail", "data":"invalid data"]
        makeResponse(returnData: returnData, response: response)
        return
    }
    let infoParams = ["amount":amount, "currency":currency, "timezone":timezone]
    let success = receiveMoneyFromBank(id: id, params: infoParams)
    
    var returnData: [String:Any] = [:]
    if success == true {
        returnData = ["result":"success", "data":"good"]
    } else {
        returnData = ["result":"fail", "data":"operation failed"]
    }
    makeResponse(returnData: returnData, response: response)
}

func triumphInformationHandlerV1(request: HTTPRequest, _ response: HTTPResponse) {
    guard let decodedJSON = validateParams(request: request, response: response) else { return }
    guard let id = decodedJSON["id"] as? String else {
        let returnData = ["result":"fail", "data":"invalid data"]
        makeResponse(returnData: returnData, response: response)
        return
    }
    
    var returnData: [String:Any] = [:]
    if let information = getTriumphInformation(id: id) {
        returnData = ["result":"success", "data":information]
    } else {
        returnData = ["result":"fail", "data":"operation failed"]
    }
    makeResponse(returnData: returnData, response: response)
}



