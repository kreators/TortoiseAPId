
import Foundation
import PerfectLib
import PerfectHTTP
import MySQL

// MARK: - DB Helpers

func updateFriendSteps(facebookId: String, currentSteps: String, targetSteps: String) -> Bool {
    let mysql = MySQL()
    let connected = mysql.connect(host: "tortoisedb.cgk0b55tapo1.us-east-1.rds.amazonaws.com", user: "root", password: "Saturn!07", db: "TORTOISE")
    guard connected else {
        printlog(functionName: #function, logString: mysql.errorMessage())
        return false
    }
    defer { mysql.close() }
    
    let querySuccess = mysql.query(statement: "SELECT id FROM FriendStep WHERE facebookId = '\(facebookId)'")
    guard querySuccess else { return false }
    let results = mysql.storeResults()!
    let numRows = results.numRows()
    results.close()

    if numRows == 0 {
        let insertQuery = "INSERT INTO FriendStep (facebookId, currentSteps, targetSteps, dateCreated, dateUpdated) VALUES ('\(facebookId)', '\(currentSteps)', '\(targetSteps)', NOW(), NOW())"
        let querySuccess = mysql.query(statement: insertQuery)
        guard querySuccess else {
            printlog(functionName: #function, logString: mysql.errorMessage())
            return false
        }
    } else {
        let updateQuery = "UPDATE FriendStep SET currentSteps = '\(currentSteps)', targetSteps = '\(targetSteps)', dateUpdated = NOW() WHERE facebookId = '\(facebookId)'"
        let updateQuerySuccess = mysql.query(statement: updateQuery)
        guard updateQuerySuccess else {
            printlog(functionName: #function, logString: mysql.errorMessage())
            return false
        }
    }
    return true
}

func getFriendSteps(startDate: String, friendIds: [String]) -> [[String:String]]? {
    let mysql = MySQL()
    let connected = mysql.connect(host: "tortoisedb.cgk0b55tapo1.us-east-1.rds.amazonaws.com", user: "root", password: "Saturn!07", db: "TORTOISE")
    guard connected else {
        printlog(functionName: #function, logString: mysql.errorMessage())
        return nil
    }
    defer { mysql.close() }
    
    var converted = [String]()
    for id in friendIds {
        converted.append("'" + id + "'")
    }
    let searchFriendIds = converted.joined(separator: ",")
    let querySuccess = mysql.query(statement: "SELECT facebookId, currentSteps, targetSteps FROM FriendStep WHERE facebookId in (\(searchFriendIds)) AND dateUpdated BETWEEN '\(startDate)' AND NOW() ORDER BY currentSteps DESC")
    guard querySuccess else { return nil }
    let results = mysql.storeResults()!
    var returnData = [[String:String]]()
    while let row = results.next() {
        if let facebookId = row[0], let currentSteps = row[1], let targetSteps = row[2] {
            returnData.append(["facebookId":facebookId, "currentSteps":currentSteps, "targetSteps":targetSteps])
        }
    }
    results.close()
    return returnData
}

// MARK: - Handlers

func updatefriendstepsHandlerV1(request: HTTPRequest, _ response: HTTPResponse) {
    guard let decodedJSON = validateParams(request: request, response: response) else { return }
    guard let facebookId = decodedJSON["facebookId"] as? String, let currentSteps = decodedJSON["currentSteps"] as? String, let targetSteps = decodedJSON["targetSteps"] as? String else {
        let returnData = ["result":"fail", "data":"invalid data"]
        makeResponse(returnData: returnData, response: response)
        return
    }
    
    let success = updateFriendSteps(facebookId: facebookId, currentSteps: currentSteps, targetSteps: targetSteps)
    var returnData: [String:Any] = [:]
    if success == true {
        returnData = ["result":"success", "data":"good"]
    } else {
        returnData = ["result":"fail", "data":"operation failed"]
    }
    makeResponse(returnData: returnData, response: response)
}

func friendstepsHandlerV1(request: HTTPRequest, _ response: HTTPResponse) {
    guard let decodedJSON = validateParams(request: request, response: response) else { return }
    guard let startDate = decodedJSON["startDate"] as? String, let friendIds = decodedJSON["friendIds"] as? [String] else {
        let returnData = ["result":"fail", "data":"invalid data"]
        makeResponse(returnData: returnData, response: response)
        return
    }

    var returnData: [String:Any] = [:]
    if let results = getFriendSteps(startDate: startDate, friendIds: friendIds) {
        returnData = ["result":"success", "data":results]
    } else {
        returnData = ["result":"fail", "data":"operation failed"]
    }
    makeResponse(returnData: returnData, response: response)
}

