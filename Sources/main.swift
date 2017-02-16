//
//  main.swift
//  Newsfeed
//
//  Created by Anton Nebylytsia on 15.02.17.
//
//

import PerfectLib
import PerfectHTTP
import PerfectHTTPServer

import PerfectRequestLogger
import SQLiteStORM

struct Filter404: HTTPResponseFilter {
    func filterBody(response: HTTPResponse, callback: (HTTPResponseFilterResult) -> ()) {
        callback(.continue)
    }
    
    func filterHeaders(response: HTTPResponse, callback: (HTTPResponseFilterResult) -> ()) {
        if case .notFound = response.status {
            
            do {
                try response.setBody(json: failResponse(messages: ["The file \(response.request.path) was not found."], code: 404))
            } catch {
                print(error)
            }
            
            response.setHeader(.accessControlAllowOrigin, value: "*")
            response.setHeader(.contentType, value: "application/json")
            response.setHeader(.contentLength, value: "\(response.bodyBytes.count)")
            callback(.done)
        } else {
            callback(.continue)
        }
    }
}

func successResponse(data:Any, code:Int) -> [String: Any] {
    var response = [String: Any]()
    response["status"] = "success"
    response["data"] = data
    return response
}

func failResponse(messages:[String], code:Int) -> [String: Any] {
    var response = [String: Any]()
    response["status"] = "error"
    response["code"] = "\(code)"
    response["messages"] = messages
    return response
}


let connect = SQLiteConnect("./newsfeeddb")
//let user = User(connect)
//try user.setupTable()

let server = HTTPServer()

let logger = RequestLogger()
server.setRequestFilters([(logger, .high)])
server.setResponseFilters([(logger, .low)])

let JSONRoutes = makeJSONRoutes("/api/v1")
server.addRoutes(JSONRoutes)

server.serverPort = 8079
server.setResponseFilters([(Filter404(), .high)])

do {
    try server.start()
} catch PerfectError.networkError(let err, let msg) {
    print("Network error thrown: \(err) \(msg)")
}
