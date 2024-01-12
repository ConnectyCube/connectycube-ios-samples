//
//  RTCSessionManager.swift
//  SampleVideoChat
//
//  Created by David on 20.10.2023.
//
import UIKit
import ConnectyCube

class RTCSessionManager{
    
    static let shared = RTCSessionManager()
    var usersToCall: [ConnectycubeUser] = []
    
    var currentCall: P2PSession?
    var sessionCallbackListener: RTCCallSessionCallback?
    
    private init() {}
    
    func register(_ usersToCall: [ConnectycubeUser] = []) {
        sessionCallbackListener = RTCCallSessionCallbackImpl(self)
        ConnectyCube().p2pCalls.addSessionCallbacksListener(callback: sessionCallbackListener!)
        self.usersToCall = usersToCall
    }
    
    func destroy() {
        ConnectyCube().p2pCalls.removeSessionCallbacksListener(callback: sessionCallbackListener!)
        sessionCallbackListener = nil
    }
    
    func startCall(rtcSession: P2PSession) {
        currentCall = rtcSession
        setupRTCMediaConfig()
        navigateToCall(isIncoming: false)
    }
    
    func receiveCall(session: P2PSession) {
        if (currentCall != nil) {
            if (currentCall!.getSessionId() != session.getSessionId()) {
                session.rejectCall(userInfo: nil)
            }
            return
        }

        currentCall = session

        setupRTCMediaConfig()
        navigateToCall(isIncoming: true)
    }
    
    func endCall() {
        currentCall = nil
    }
    
    private func setupRTCMediaConfig() {
        if (currentCall != nil) {
            if (currentCall!.getOpponents().count < 2) {
                WebRTCMediaConfig().videoWidth = WebRTCMediaConfig.VideoQuality.hdVideo.width
                WebRTCMediaConfig().videoHeight = WebRTCMediaConfig.VideoQuality.hdVideo.height
            } else {
                WebRTCMediaConfig().videoWidth = WebRTCMediaConfig.VideoQuality.vgaVideo.width
                WebRTCMediaConfig().videoHeight = WebRTCMediaConfig.VideoQuality.vgaVideo.height
            }
        }
    }
    
    func navigateToCall(isIncoming: Bool) {
        let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "CallViewController") as! CallViewController
        vc.isIncoming = isIncoming
        vc.usersToCall = usersToCall
        let navController = UIApplication.shared.firstKeyWindow?.rootViewController as? UINavigationController
        navController!.pushViewController(vc, animated: true)
    }
    
    class RTCCallSessionCallbackImpl: RTCCallSessionCallback {
        weak var manager: RTCSessionManager!
        init(_ manager: RTCSessionManager!) {
            self.manager = manager
        }
        
        
        func onReceiveNewSession(session: P2PSession) {
            manager.receiveCall(session: session)
        }
        
        func onSessionStartClose(session: P2PSession) {}
        
        func onUserNoActions(session: P2PSession, userId: KotlinInt?) {}
        
        func onCallAcceptByUser(session: P2PSession, opponentId: Int32, userInfo: [String : Any]? = nil) {}
        
        func onCallRejectByUser(session: P2PSession, opponentId: Int32, userInfo: [String : Any]? = nil) {}
        
        func onReceiveHangUpFromUser(session: P2PSession, opponentId: Int32, userInfo: [String : Any]? = nil) {}
        
        func onSessionClosed(session_ session: P2PSession) {
            if (manager.currentCall == nil) {
                return
            }

            if (manager.currentCall!.getSessionId() == session.getSessionId()) {
                manager.endCall()
            }
        }
        
        func onUserNotAnswer(session: P2PSession, opponentId: Int32) {}
        
    }
}
