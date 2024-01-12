//
//  CallViewController.swift
//  SampleVideoChat
//
//  Created by David on 18.10.2023.
//

import UIKit
import WebRTC
import ConnectyCube

class CallViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    var currentUser: ConnectycubeUser?
    var usersToCall: [ConnectycubeUser] = []
    var isIncoming: Bool?
    
#if arch(x86_64)
    private var localVideo = RTCEAGLVideoView()
    private var remoteVideos: [Int32: RTCEAGLVideoView] = []
#else
    private var localVideo = RTCMTLVideoView()
    private var remoteVideos: [Int32: RTCMTLVideoView] = [:]
#endif
    
    private var chronometerInCall: Timer = Timer()
    private var count: Int = 0
    private var chronometerStarted: Bool = false
    
    let p2pCalls = ConnectyCube().p2pCalls
    var currentSession: P2PSession?
    let stateListener = RTCSessionStateCallbackImpl()
    let sessionListener = RTCCallSessionCallbackImpl()
    
    let videoTrackListener = VideoTracksCallbackImpl()
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBOutlet weak var callingLabel: UILabel!
    
    @IBOutlet weak var acceptBtn: UIButton!
    
    @IBOutlet weak var declineBtn: UIButton!
    
    @IBOutlet weak var micBtn: UIButton!
    
    @IBOutlet weak var hangUpBtn: UIButton!
    
    @IBOutlet weak var switchCameraBtn: UIButton!
    
    @IBOutlet weak var chronometerLabel: UILabel!
    
    @IBOutlet weak var switchSpeakerBtn: UIButton!
    
    @IBAction func acceptAction(_ sender: UIButton) {
        currentSession?.acceptCall(userInfo: nil)
        showCallScreen()
    }
    
    @IBAction func declineAction(_ sender: UIButton) {
        currentSession?.rejectCall(userInfo: nil)
    }
    
    @IBAction func hangUpAction(_ sender: Any) {
        hangUpCurrentSession()
    }
    
    @IBAction func micAction(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        let micImage = sender.isSelected ? UIImage(systemName: "mic.slash")!: UIImage(systemName: "mic")!
        micBtn.setImage(micImage, for: .normal)
        currentSession?.mediaStreamManager?.localAudioTrack?.enabled = !sender.isSelected
    }
    
    @IBAction func switchCamera(_ sender: UIButton) {
        currentSession?.mediaStreamManager?.videoCapturer?.switchCamera()
    }
    
    @IBAction func switchSpeaker(_ sender: UIButton) {
        let isCurrentSpeaker: Bool = !AVAudioSession.sharedInstance().currentRoute.outputs.filter{$0.portType == AVAudioSession.Port.builtInSpeaker }.isEmpty
        let port = isCurrentSpeaker ? AVAudioSession.PortOverride.none: AVAudioSession.PortOverride.speaker
        do {
            try AVAudioSession.sharedInstance().overrideOutputAudioPort(port)
        } catch let error as NSError {
            print("audioSession error: \(error.localizedDescription)")
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.setHidesBackButton(true, animated: true)
        setupSession()
        setupListeners()
        startCall()
    }
    
    deinit {
        print("CallViewController deinit")
        currentSession?.removeSessionStateCallbacksListener(callback: stateListener)
        currentSession?.removeVideoTrackCallbacksListener(callback: videoTrackListener)
        p2pCalls.removeSessionCallbacksListener(callback: sessionListener)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return getUsersCount()
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let videoCell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as? CollectionViewCell
        videoCell!.subviews.forEach({ $0.removeFromSuperview() })
        if(indexPath.item == 0) {
            videoCell!.configureVideo(with: localVideo)
        } else {
            videoCell!.configureVideo(with: Array(remoteVideos)[indexPath.item - 1].value)
        }
      
        return videoCell!
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

        let cvRect = collectionView.frame
        var size: CGSize = CGSize(width: cvRect.width, height: cvRect.height)
        
        let usersCount = getUsersCount()
        
        if(usersCount == 2) {
            size = CGSize(width: cvRect.width, height: cvRect.height/2)
        } else if(usersCount == 3) {
            if(indexPath.item == 0) {
                size = CGSize(width: cvRect.width, height: cvRect.height/2)
            } else {
                size = CGSize(width: cvRect.width/2, height: cvRect.height/2)
            }
        } else if(usersCount == 4) {
            size = CGSize(width: cvRect.width/2, height: cvRect.height/2)
        }
        
        return size
    }
    
    private func getUsersCount() -> Int {
        return remoteVideos.count + 1
    }
    
    private func startCall() {
        if(isIncoming!) {
            showIncomingScreen()
        } else {
            showCallScreen()
            currentSession?.startCall(userInfo: nil)
        }
    }
    
    private func hangUpCurrentSession() {
        currentSession?.hangUp(userInfo: nil)
    }
    
    private func showIncomingScreen() {
        callBtnsVisibility(isHidden: true)
        incomingBtnsVisibility(isHidden: false)
        
        callingLabel.isHidden = false
        callingLabel.text = filterUsers().joined(separator:", ") + " is calling"
    }
    
    private func showCallScreen() {
        callBtnsVisibility(isHidden: false)
        incomingBtnsVisibility(isHidden: true)
        let isVideoCall = CallType.video == currentSession?.getCallType()
        if(isVideoCall) {
            switchSpeakerBtn.isHidden = true
            callingLabel.isHidden = true
        } else {
            switchCameraBtn.isHidden = true
            callingLabel.text = filterUsers().joined(separator:", ") + " on call"
        }
    }
    
    private func filterUsers() -> [String] {
        var idsOnCall: [Int32] = currentSession!.getOpponents().map{$0.int32Value}
        idsOnCall.append(currentSession!.getCallerId())
        return usersToCall.filter{idsOnCall.contains($0.id)}.map{$0.fullName ?? ""}
    }
    
    private func callBtnsVisibility(isHidden: Bool){
        micBtn.isHidden = isHidden
        hangUpBtn.isHidden = isHidden
        switchCameraBtn.isHidden = isHidden
        switchSpeakerBtn.isHidden = isHidden
    }
    
    private func incomingBtnsVisibility(isHidden: Bool) {
        acceptBtn.isHidden = isHidden
        declineBtn.isHidden = isHidden
    }
    
    private func setupSession() {
        currentSession = RTCSessionManager.shared.currentCall
    }
    
    private func setupListeners() {
        stateListener.callViewController = self
        sessionListener.callViewController = self
        videoTrackListener.callViewController = self
        currentSession!.addSessionStateCallbacksListener(callback: stateListener)
        currentSession!.doInitSignallingWithOpponents()
        p2pCalls.addSessionCallbacksListener(callback: sessionListener)
        
        currentSession!.addVideoTrackCallbacksListener(callback: videoTrackListener)
    }
    
    // MARK: - UI
    private func initRemoteVideo(_ userId: Int32) {
#if arch(x86_64)
        let remoteVideo = RTCEAGLVideoView()
#else
        let remoteVideo = RTCMTLVideoView()
#endif
        remoteVideos[userId] = remoteVideo
    }
    
    private func setupRemoteVideo() {
        collectionView.reloadData()
    }
    
    private func removeRemote(_ userId: Int32) {
        remoteVideos.removeValue(forKey: userId)
        setupRemoteVideo()
    }
    
    // MARK: - ACTION
    private func releaseCurrentCall() {
        currentSession?.removeSessionStateCallbacksListener(callback: stateListener)
        p2pCalls.removeSessionCallbacksListener(callback: sessionListener)
        currentSession = nil
        RTCSessionManager.shared.endCall()
    }
    
    private func startInCallChronometer() {
        if (!chronometerStarted) {
            chronometerStarted = true
            chronometerInCall = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(chronometerCounter), userInfo: nil, repeats: true)
        }
    }
    
    private func stopInCallChronometer() {
        chronometerStarted = false
        count = 0
        chronometerInCall.invalidate()
        chronometerLabel.text = makeChronometerString(hours: 0, minutes: 0, seconds: 0)
    }
    
    @objc func chronometerCounter() -> Void {
        count = count + 1
        let time = secondsToHoursMinutesSeconds(seconds: count)
        let chronometerString = makeChronometerString(hours: time.0, minutes: time.1, seconds: time.2)
        chronometerLabel.text = chronometerString
    }

    func secondsToHoursMinutesSeconds(seconds: Int) -> (Int, Int, Int) {
        return ((seconds / 3600), ((seconds % 3600) / 60), ((seconds % 3600) % 60))
    }
    
    func makeChronometerString(hours: Int, minutes: Int, seconds: Int) -> String {
        var timeString = ""
        timeString += String(format: "%02d", hours)
        timeString += ":"
        timeString += String(format: "%02d", minutes)
        timeString += ":"
        timeString += String(format: "%02d", seconds)
        return timeString
    }
    
    
    class RTCSessionStateCallbackImpl: RTCSessionStateCallback {
        weak var callViewController: CallViewController!
        
        func onConnectedToUser(session: BaseSession<AnyObject>, userId: Int32) {
            callViewController.startInCallChronometer()
        }
        
        func onConnectionClosedForUser(session: BaseSession<AnyObject>, userId: Int32) {
            callViewController.removeRemote(userId)
        }
        
        func onDisconnectedFromUser(session: BaseSession<AnyObject>, userId: Int32) {}
        
        func onStateChanged(session: BaseSession<AnyObject>, state: BaseSessionRTCSessionState) {}
    }
    
    class RTCCallSessionCallbackImpl: RTCCallSessionCallback {
        weak var callViewController: CallViewController!
        
        func onReceiveNewSession(session: P2PSession) {
            if (callViewController.currentSession != nil) {
                session.rejectCall(userInfo: nil)
            }
        }
        
        func onSessionStartClose(session: P2PSession) {
            callViewController.stopInCallChronometer()
        }
        
        func onUserNoActions(session: P2PSession, userId: KotlinInt?) {}
        
        func onCallAcceptByUser(session: P2PSession, opponentId: Int32, userInfo: [String : Any]? = nil) {
            if (session != callViewController.currentSession) {
                return
            }
        }
        
        func onCallRejectByUser(session: P2PSession, opponentId: Int32, userInfo: [String : Any]? = nil) {}
        
        func onReceiveHangUpFromUser(session: P2PSession, opponentId: Int32, userInfo: [String : Any]? = nil) {}
        
        func onSessionClosed(session_ session: P2PSession) {
            if (session == callViewController.currentSession) {
                print("release currentSession")
                callViewController.releaseCurrentCall()
               
                callViewController.navigationController?.popViewController(animated: true)
            }
        }
        
        func onUserNotAnswer(session: P2PSession, opponentId: Int32) {
            if (session != callViewController.currentSession) {
                return
            }
        }
    }
    
    class VideoTracksCallbackImpl: VideoTracksCallback {
        weak var callViewController: CallViewController!
        
        func onLocalVideoTrackReceive(session: BaseSession<AnyObject>, videoTrack: ConnectycubeVideoTrack) {
            videoTrack.addSink(videoSink: VideoSink(renderer: callViewController.localVideo))
        }
        
        func onRemoteVideoTrackReceive(session: BaseSession<AnyObject>, videoTrack: ConnectycubeVideoTrack, userId: Int32) {
            callViewController.initRemoteVideo(userId)
            callViewController.setupRemoteVideo()
            videoTrack.addSink(videoSink: VideoSink(renderer: callViewController.remoteVideos[userId]!))
        }
    }
    
}
