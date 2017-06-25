
import Foundation
import PerfectLib
import PerfectHTTP
import PerfectCrypto

var developerId: String?
var developerSecret: String?
var deviceFingerprint: String?
let deviceIP = "54.89.241.132"
let corpAccountId = "587d6a7886c2735e7d3e9de4"

let developerIdEncrypted: [UInt8] = [178, 176, 18, 83, 131, 0, 25, 247, 62, 202, 115, 56, 250, 159, 70, 90, 113, 21, 198, 253, 140, 44, 111, 182, 139, 38, 71, 228, 98, 222, 95, 235, 26, 161, 214, 184, 252, 32, 187, 3, 234, 57, 0, 190, 184, 229, 40, 154]
let developerSecretEncrypted: [UInt8] = [254, 192, 163, 196, 133, 135, 226, 221, 229, 26, 47, 25, 157, 3, 47, 190, 201, 210, 72, 17, 238, 128, 43, 148, 56, 83, 170, 254, 86, 248, 30, 16, 189, 192, 145, 20, 247, 105, 149, 128, 121, 228, 30, 64, 150, 80, 26, 217]
let deviceFingerprintEncrypted: [UInt8] = [249, 72, 194, 230, 194, 27, 104, 45, 136, 228, 244, 88, 139, 192, 71, 137, 90, 174, 106, 77, 154, 42, 117, 238, 182, 206, 112, 33, 27, 13, 0, 153, 32, 16, 130, 71, 224, 40, 5, 175, 38, 252, 17, 156, 219, 223, 228, 141]

// MARK: - Helpers

func initConfiguration() {
    let keyString = "KreatorsKreators"
    let ivString = "TortoiseTortoise"
    
    if let bytes = developerIdEncrypted.decrypt(.aes_128_cbc, key: Array(keyString.utf8), iv: Array(ivString.utf8)) {
        developerId = String(bytes: bytes, encoding: .utf8)
    } else {
        printlog(functionName: #function, logString: "developerId decrypt fail")
        return
    }
    if let bytes = developerSecretEncrypted.decrypt(.aes_128_cbc, key: Array(keyString.utf8), iv: Array(ivString.utf8)) {
        developerSecret = String(bytes: bytes, encoding: .utf8)
    } else {
        printlog(functionName: #function, logString: "developerSecret decrypt fail")
        return
    }
    if let bytes = deviceFingerprintEncrypted.decrypt(.aes_128_cbc, key: Array(keyString.utf8), iv: Array(ivString.utf8)) {
        deviceFingerprint = String(bytes: bytes, encoding: .utf8)
    } else {
        printlog(functionName: #function, logString: "developerId decrypt fail")
        return
    }
}

func printlog(functionName: String, logString: String) {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    print("\(formatter.string(from: Date())) \(functionName) : \(logString)")
}

func validateParams(request: HTTPRequest, response: HTTPResponse) -> [String:Any]? {
    let params1 = request.postParams.first
    guard let params = params1 else {
        let returnData = ["result":"fail", "data":"empty params"]
        let encodedJSON = try! returnData.jsonEncodedString()
        response.setHeader(.contentType, value: "application/json")
        response.appendBody(string: encodedJSON)
        response.completed()
        return nil
    }
    let encoded = params.0
    let decoded = try! encoded.jsonDecode() as? [String:Any]
    
    guard let decodedJSON = decoded else {
        let returnData = ["result":"fail", "data":"params error"]
        let encodedJSON = try! returnData.jsonEncodedString()
        response.setHeader(.contentType, value: "application/json")
        response.appendBody(string: encodedJSON)
        response.completed()
        return nil
    }
    return decodedJSON
}

func makeResponse(returnData: [String:Any], response: HTTPResponse) {
    let encodedJSON = try! returnData.jsonEncodedString()
    response.setHeader(.contentType, value: "application/json")
    response.appendBody(string: encodedJSON)
    response.completed()
}
