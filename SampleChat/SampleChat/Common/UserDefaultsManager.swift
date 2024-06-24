//
//  UserDefaultsManager.swift
//  SampleChat
//
//  Created by David on 10.05.2024.
//

import ConnectyCube

class UserDefaultsManager{
    let userLogin = "user_login"
    let userPsw = "user_password"
    let userId = "user_id"
    let userName = "user_name"
    let userAvatar = "user_avatar"
    
    static let shared = UserDefaultsManager()
    
    private init() {}
    
    func saveCurrentUser(_ user: ConnectycubeUser) {
        UserDefaults.standard.set(user.login, forKey: userLogin)
        UserDefaults.standard.set(user.password, forKey: userPsw)
        UserDefaults.standard.set(user.id, forKey: userId)
    }
    
    func getCurrentUser() -> ConnectycubeUser! {
        if(!currentUserExists()) {
            return nil
        }
        let user = ConnectycubeUser()
        user.login = UserDefaults.standard.string(forKey: userLogin)
        user.password = UserDefaults.standard.string(forKey: userPsw)
        user.id = Int32(UserDefaults.standard.integer(forKey: userId))
        return user
    }
    
    func currentUserExists() -> Bool {
        return UserDefaults.standard.string(forKey: userLogin) != nil
    }
    
    func removeCurrentUser() {
        UserDefaults.standard.removeObject(forKey:userLogin)
        UserDefaults.standard.removeObject(forKey:userPsw)
        UserDefaults.standard.removeObject(forKey:userId)
    }
}
