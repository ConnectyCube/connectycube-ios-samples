//
//  AppDelegate.swift
//  SampleChat
//
//  Created by David on 27.04.2024.
//

import UIKit
import ConnectyCube
import IQKeyboardManagerSwift

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    let APP_ID = "REPLACE_APP_ID"
    let AUTH_KEY = "REPLACE_APP_AUTH_KEY"


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        ConnectyCube().doInit(applicationId: APP_ID, authorizationKey: AUTH_KEY, connectycubeConfig: nil)
        ConnectycubeSettings().isDebugEnabled = true
        ConnectyCube().chat.enableLogging()
        
        IQKeyboardManager.shared.enable = true
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

