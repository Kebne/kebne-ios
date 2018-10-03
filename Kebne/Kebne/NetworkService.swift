//
//  NetworkService.swift
//  Kebne
//
//  Created by Emil Lundgren on 2018-10-03.
//  Copyright © 2018 Emil Lundgren. All rights reserved.
//

import Foundation
import GoogleSignIn

protocol NetworkServiceProtocol {
    func sendGoogleCloudMessage(data: Data)
}

class NetworkService : NetworkServiceProtocol {
    func sendGoogleCloudMessage(data: Data) {
        guard let url = URL(string: "https://fcm.googleapis.com/v1/projects/kebne-office-app/messages:send") else {return}
        if let string = String(data: data, encoding: .utf8) {
            print("Notification: \(string)")
        }
        var request = URLRequest(url: url)
        
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer " + GIDSignIn.sharedInstance()!.currentUser.authentication.accessToken, forHTTPHeaderField: "Authorization")
        let task = URLSession.shared.uploadTask(with: request, from: data) { data, response, error in
            if let error = error {
                print ("error: \(error)")
                return
            }
            guard let response = response as? HTTPURLResponse else {
                print ("server error")
                return
            }
            print("response status code: \(response.statusCode)")
            if let mimeType = response.mimeType,
                mimeType == "application/json",
                let data = data,
                let dataString = String(data: data, encoding: .utf8) {
                print ("got data: \(dataString)")
            }
        }
        task.resume()
    }
}
