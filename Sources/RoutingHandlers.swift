
import Foundation
import PerfectLib
import PerfectHTTP
import PerfectCURL
import cURL
import MySQL

func makeURLRoutes() -> Routes {
	var routes = Routes()
	routes.add(method: .get, uris: ["/", "heartbeat.html"], handler: heartbeatHandler)

    var apiv1 = Routes()
    
    apiv1.add(method: .post, uri: "/tortoiseuser", handler: createTortoiseUserHandlerV1)
    apiv1.add(method: .post, uri: "/user", handler: createUserHandlerV1)
    apiv1.add(method: .post, uri: "/addkycinfo", handler: addKYCInfoHandlerV1)

    apiv1.add(method: .post, uri: "/addachuslogins", handler: addACHUSLoginsHandlerV1)
    apiv1.add(method: .post, uri: "/achusmfa", handler: addACHUSMFAHandlerV1)
    apiv1.add(method: .post, uri: "/selectbankaccount", handler: selectBankAccounHandlerV1)
    apiv1.add(method: .post, uri: "/addtriumphsubaccountus", handler: addTriumphSubaccountUSHandlerV1)
    apiv1.add(method: .post, uri: "/sendmoney", handler: sendMoneyHandlerV1)
    apiv1.add(method: .post, uri: "/receivemoney", handler: receiveMoneyHandlerV1)
    apiv1.add(method: .post, uri: "/triumphinformation", handler: triumphInformationHandlerV1)

    apiv1.add(method: .post, uri: "/logintortoiseuser", handler: loginTortoiseUser)
    apiv1.add(method: .post, uri: "/updatefriendsteps", handler: updatefriendstepsHandlerV1)
    apiv1.add(method: .post, uri: "/friendsteps", handler: friendstepsHandlerV1)
    
    apiv1.add(method: .post, uri: "/updatedailybalance", handler: updateDailyBalanceHandlerV1)
    apiv1.add(method: .post, uri: "/updatedailybalances", handler: updateDailyBalancesHandlerV1)
    apiv1.add(method: .post, uri: "/lastdailybalance", handler: getLastDailyBalanceHanderV1)
    apiv1.add(method: .post, uri: "/lastdailybalances", handler: getLast100DailyBalancesHanderV1)

	var apiv1Routes = Routes(baseUri: "/api/v1")
	apiv1Routes.add(_: apiv1)
	routes.add(_: apiv1Routes)
	return routes
}

func heartbeatHandler(request: HTTPRequest, _ response: HTTPResponse) {
    printlog(functionName: #function, logString: "heartbeat")
    response.appendBody(string: "heartbeatHandler: You accessed path \(request.path)")
    response.completed()
}
