//
//  SearchUserManager.swift
//  SampleChat
//
//  Created by David on 10.06.2024.
//

import UIKit
import ConnectyCube

func loadUsers(username: String, function: @escaping ([ConnectycubeUser]) -> Void) {
    ConnectyCube().getUsersByFullName(fullName: username, pagination: nil, sorter: nil, successCallback: { result in
        let users = (result.items as! [ConnectycubeUser]).filter{$0.id != UserDefaultsManager.shared.getCurrentUser().id}
        function(users)
    }, errorCallback: { error in
        NSLog("loadUsers error " + error.description())
    })
}
