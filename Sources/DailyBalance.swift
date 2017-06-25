
import Foundation
import PerfectLib
import PerfectHTTP
import PerfectCURL
import cURL
import MySQL

// MARK: - Helpers

fileprivate func lastDailyBalance(userId: String) -> [String:String]? {
    var refreshToken: String? = nil
    let mysql = MySQL()
    let connected = mysql.connect(host: "tortoisedb.cgk0b55tapo1.us-east-1.rds.amazonaws.com", user: "root", password: "Saturn!07", db: "TORTOISE")
    
    guard connected else {
        print("\(#function) : \(mysql.errorMessage())")
        return nil
    }
    
    defer { mysql.close() }
    
    let querySuccess = mysql.query(statement: "SELECT targetDeposit, interest, principal, balance, targetsteps, steps, dateApplied FROM DailyBalance WHERE userId = '\(userId)' ORDER BY dateApplied DESC LIMIT 1")
    guard querySuccess else {
        return nil
    }
    
    var targetDeposit: String?
    var interest: String?
    var principal: String?
    var balance: String?
    var targetSteps: String?
    var steps: String?
    var dateApplied: String?
    var returnBalance = [String:String]()
    
    let results = mysql.storeResults()!
    while let row = results.next() {
        targetDeposit = row[0]
        interest = row[1]
        principal = row[2]
        balance = row[3]
        targetSteps = row[4]
        steps = row[5]
        dateApplied = row[6]
    }

    if let targetDeposit = targetDeposit {
        returnBalance["targetDeposit"] = targetDeposit
    }
    if let interest = interest {
        returnBalance["interest"] = interest
    }
    if let principal = principal {
        returnBalance["principal"] = principal
    }
    if let balance = balance {
        returnBalance["balance"] = balance
    }
    if let targetSteps = targetSteps {
        returnBalance["targetSteps"] = targetSteps
    }
    if let steps = steps {
        returnBalance["steps"] = steps
    }
    if let dateApplied = dateApplied {
        returnBalance["dateApplied"] = dateApplied
    }
    return returnBalance
}

fileprivate func last100DailyBalances(userId: String, dateApplied: String) -> [[String:String]]? {
    var refreshToken: String? = nil
    let mysql = MySQL()
    let connected = mysql.connect(host: "tortoisedb.cgk0b55tapo1.us-east-1.rds.amazonaws.com", user: "root", password: "Saturn!07", db: "TORTOISE")
    
    guard connected else {
        print("\(#function) : \(mysql.errorMessage())")
        return nil
    }
    
    defer { mysql.close() }
    
    let querySuccess = mysql.query(statement: "SELECT targetDeposit, interest, principal, balance, targetSteps, steps, dateApplied FROM DailyBalance WHERE userId = '\(userId)' AND dateApplied < '\(dateApplied)' ORDER BY dateApplied DESC LIMIT 100")
    guard querySuccess else {
        return nil
    }
    
    var targetDeposit: String?
    var interest: String?
    var principal: String?
    var balance: String?
    var targetSteps: String?
    var steps: String?
    var dateApplied: String?
    var returnBalances = [[String:String]]()
    
    let results = mysql.storeResults()!
    while let row = results.next() {
        targetDeposit = row[0]
        interest = row[1]
        principal = row[2]
        balance = row[3]
        targetSteps = row[4]
        steps = row[5]
        dateApplied = row[6]

        var returnBalance = [String:String]()
        if let targetDeposit = targetDeposit {
            returnBalance["targetDeposit"] = targetDeposit
        }
        if let interest = interest {
            returnBalance["interest"] = interest
        }
        if let principal = principal {
            returnBalance["principal"] = principal
        }
        if let balance = balance {
            returnBalance["balance"] = balance
        }
        if let targetSteps = targetSteps {
            returnBalance["targetSteps"] = targetSteps
        }
        if let steps = steps {
            returnBalance["steps"] = steps
        }
        if let dateApplied = dateApplied {
            returnBalance["dateApplied"] = dateApplied
        }
        returnBalances.append(returnBalance)
    }
    return returnBalances
}


func createDailyBalance(userId: String, dailyDeposit: String, dailyInterest: String, dailyPrincipal: String, dailyBalance: String, dateApplied: String) -> Bool {
    let mysql = MySQL()
    let connected = mysql.connect(host: "tortoisedb.cgk0b55tapo1.us-east-1.rds.amazonaws.com", user: "root", password: "Saturn!07", db: "TORTOISE")
    
    guard connected else {
        print("\(#function) : \(mysql.errorMessage())")
        return false
    }
    
    defer { mysql.close() }
    
    let insertQuery = "INSERT INTO DailyBalance (userId, targetDeposit, interest, principal, balance, dateApplied, dateCreated) VALUES ('\(userId)', '\(dailyDeposit)', '\(dailyInterest)', '\(dailyPrincipal)', '\(dailyBalance)', '\(dateApplied)', NOW())"
    
    let querySuccess = mysql.query(statement: insertQuery)
    guard querySuccess else { return false }
    return true
}

func createDailyBalances(userId: String, dailyBalances: [Any]) -> Bool {
    let mysql = MySQL()
    let connected = mysql.connect(host: "tortoisedb.cgk0b55tapo1.us-east-1.rds.amazonaws.com", user: "root", password: "Saturn!07", db: "TORTOISE")
    
    guard connected else {
        print("\(#function) : \(mysql.errorMessage())")
        return false
    }
    
    defer { mysql.close() }
    
    for dailyBalance in dailyBalances as! [[String:String]] {
        if let targetDeposit = dailyBalance["targetDeposit"], let interest = dailyBalance["interest"], let principal = dailyBalance["principal"], let balance = dailyBalance["balance"], let targetSteps = dailyBalance["targetSteps"], let steps = dailyBalance["steps"], let dateApplied = dailyBalance["dateApplied"] {
            if isDailyBalance(userId: userId, dateApplied: dateApplied) == false {
                let insertQuery = "INSERT INTO DailyBalance (userId, targetDeposit, interest, principal, balance, targetSteps, steps, dateApplied, dateCreated) VALUES ('\(userId)', '\(targetDeposit)', '\(interest)', '\(principal)', '\(balance)', '\(targetSteps)', '\(steps)', '\(dateApplied)', NOW())"
                
                let querySuccess = mysql.query(statement: insertQuery)
                guard querySuccess else { return false }
            }
        }
    }
    return true
}

func isDailyBalance(userId: String, dateApplied: String) -> Bool {
    let mysql = MySQL()
    let connected = mysql.connect(host: "tortoisedb.cgk0b55tapo1.us-east-1.rds.amazonaws.com", user: "root", password: "Saturn!07", db: "TORTOISE")
    
    guard connected else {
        print("\(#function) : \(mysql.errorMessage())")
        return false
    }
    
    defer { mysql.close() }
    
    let index = dateApplied.index(dateApplied.startIndex, offsetBy: 10)
    let date = dateApplied.substring(to: index)
    
    let querySuccess = mysql.query(statement: "SELECT targetDeposit FROM DailyBalance WHERE userId = '\(userId)' AND DATE(dateApplied) = '\(date)' LIMIT 1")
    guard querySuccess else { return false }
    
    let results = mysql.storeResults()!
    if results.numRows() == 0 { return false }
    return true
}

// MARK: - Handlers

func getLastDailyBalanceHanderV1(request: HTTPRequest, _ response: HTTPResponse) {
    guard let decodedJSON = validateParams(request: request, response: response) else { return }
    guard let id = decodedJSON["id"] as? String else {
        let returnData = ["result":"fail", "data":"invalid parameters"]
        makeResponse(returnData: returnData, response: response)
        return
    }
    
    let returnBalance = lastDailyBalance(userId: id)
    var returnData = [String:Any]()
    if let returnBalance = returnBalance {
        returnData = ["result":"success", "data":returnBalance]
    } else {
        returnData = ["result":"fail", "data":"fail"]
    }
    makeResponse(returnData: returnData, response: response)
}

func getLast100DailyBalancesHanderV1(request: HTTPRequest, _ response: HTTPResponse) {
    guard let decodedJSON = validateParams(request: request, response: response) else { return }
    guard let id = decodedJSON["id"] as? String, let dateApplied = decodedJSON["dateApplied"] as? String else {
        let returnData = ["result":"fail", "data":"invalid parameters"]
        makeResponse(returnData: returnData, response: response)
        return
    }
    
    let returnBalances = last100DailyBalances(userId: id, dateApplied: dateApplied)
    var returnData = [String:Any]()
    if let returnBalances = returnBalances {
        returnData = ["result":"success", "data":returnBalances]
    } else {
        returnData = ["result":"fail", "data":"fail"]
    }
    makeResponse(returnData: returnData, response: response)
}

func updateDailyBalanceHandlerV1(request: HTTPRequest, _ response: HTTPResponse) {
    guard let decodedJSON = validateParams(request: request, response: response) else { return }
    guard let id = decodedJSON["id"] as? String, let dailyDeposit = decodedJSON["dailyDeposit"] as? String, let dailyInterest = decodedJSON["dailyInterest"] as? String, let dailyPrincipal = decodedJSON["dailyPrincipal"] as? String, let dailyBalance = decodedJSON["dailyBalance"] as? String, let dateApplied = decodedJSON["dateApplied"] as? String else {
        let returnData = ["result":"fail", "data":"invalid parameters"]
        makeResponse(returnData: returnData, response: response)
        return
    }
    
    let success = createDailyBalance(userId: id, dailyDeposit: dailyDeposit, dailyInterest: dailyInterest, dailyPrincipal: dailyPrincipal, dailyBalance: dailyBalance, dateApplied: dateApplied)
    var returnData: [String:Any] = [:]
    if success == true {
        returnData = ["result":"success", "data":"good"]
    } else {
        returnData = ["result":"fail", "data":"fail"]
    }
    makeResponse(returnData: returnData, response: response)
}

func updateDailyBalancesHandlerV1(request: HTTPRequest, _ response: HTTPResponse) {
    guard let decodedJSON = validateParams(request: request, response: response) else { return }
    guard let id = decodedJSON["id"] as? String, let dailyBalances = decodedJSON["dailyBalances"] as? [Any] else {
        let returnData = ["result":"fail", "data":"invalid parameters"]
        makeResponse(returnData: returnData, response: response)
        return
    }
    
    let success = createDailyBalances(userId: id, dailyBalances: dailyBalances)
    var returnData: [String:Any] = [:]
    if success == true {
        returnData = ["result":"success", "data":"good"]
    } else {
        returnData = ["result":"fail", "data":"fail"]
    }
    makeResponse(returnData: returnData, response: response)
}

