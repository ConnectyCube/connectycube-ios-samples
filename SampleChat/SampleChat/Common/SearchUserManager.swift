//
//  SearchUserManager.swift
//  SampleChat
//
//  Created by David on 10.06.2024.
//

import UIKit
import ConnectyCube

func loadUsers(login: String, idsToExclude: [Int32] = [], function: @escaping ([ConnectycubeUser]) -> Void) {
    // search users with login excluding current user and idsToExclude
    var ids = Set(idsToExclude)
    ids.insert(UserDefaultsManager.shared.getCurrentUser().id)

    let params:[String : Any] = ["login[start_with]" : login, "id[nin]" : ids]
    ConnectyCube().getUsers(params: params, pagination: nil, sorter: nil, successCallback: { result in
        function(result.items as! [ConnectycubeUser])
    }, errorCallback: { error in
        NSLog("loadUsers error " + error.description())
    })
}
