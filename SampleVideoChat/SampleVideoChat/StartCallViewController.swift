//
//  StartCallViewController.swift
//  SampleVideoChat
//
//  Created by David on 12.10.2023.
//

import UIKit
import ConnectyCube

class StartCallViewController: UIViewController {
    var users: [ConnectycubeUser]?
    var currentUser: ConnectycubeUser?
    var usersToCall: [ConnectycubeUser] = []
    
    var currentSession: P2PSession?
    
    var spinner = UIActivityIndicatorView()
 
    @IBOutlet weak var userCallBtn1: UIButton!{
        didSet{
            buttonRoundInit(userCallBtn1, users![0].fullName!)
        }
    }
    @IBOutlet weak var userCallBtn2: UIButton!{
        didSet{
            buttonRoundInit(userCallBtn2, users![1].fullName!)
        }
    }
    @IBOutlet weak var userCallBtn3: UIButton!{
        didSet{
            buttonRoundInit(userCallBtn3, users![2].fullName!)
        }
    }
    
    @IBOutlet weak var audioCallBtn: UIButton!
    
    @IBOutlet weak var videoCallBtn: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(spinner)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        updateCallBtn()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: " Logout", style: .plain, target: self, action: #selector(actionLogout))
    }
    
    @objc func actionLogout (sender:UIButton) {
        ConnectyCube().chat.logout(successCallback: nil)
        RTCSessionManager.shared.destroy()
        navigationController?.popViewController(animated: true)
    }
    
    func logout() {
        spinner.startAnimating()
        Task.init {
        try await ConnectyCube().signOut()
            ConnectyCube().chat.logout(successCallback: nil)
            spinner.stopAnimating()
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    func buttonRoundInit(_ button: UIButton, _ title: String) {
        button.layer.cornerRadius = button.frame.height / 2
        button.clipsToBounds = true
        button.setTitle(title, for: .normal)
        let unselected = UIImage(named: "circle_radio_unselected")
        let tintedUnselected = unselected?.withRenderingMode(.alwaysTemplate)
        let selected = UIImage(named: "circle_radio_selected")
        let tintedSelected = selected?.withRenderingMode(.alwaysTemplate)
        button.setImage(tintedUnselected, for: .normal)
        button.setImage(tintedSelected, for: .selected)
        
        button.tintColor = .green
    }
    
    @IBAction func multiCallUserBtnTapped(_ sender: UIButton) {
        updateCallUsers(sender)
        updateCallBtn()
        sender.checkboxAnimation {
            print(sender.titleLabel?.text ?? "")
            print(sender.isSelected)
        }
    }
    
    func updateCallUsers(_ sender: UIButton) {
        if(sender.isSelected) {
            if let index = usersToCall.firstIndex(of: users![sender.tag - 1]) {
                usersToCall.remove(at: index)
            }
        } else {
            usersToCall.append(users![sender.tag - 1])
        }
    }
    
    func updateCallBtn() {
        audioCallBtn.isEnabled = !usersToCall.isEmpty
        videoCallBtn.isEnabled = !usersToCall.isEmpty
    }
    
    @IBAction func audioCallAction(_ sender: UIButton) {
        print("audioCallAction \(usersToCall)")
        startCall(callType: CallType.audio)
    }
    
    @IBAction func videoCallAction(_ sender: UIButton) {
        startCall(callType: CallType.video)
    }
    
    func startCall(callType: CallType) {
        let rtcSession = ConnectyCube().p2pCalls.createSession(userIds: usersToCall.map{KotlinInt(value: $0.id)}, callType: callType)
        RTCSessionManager.shared.startCall(rtcSession: rtcSession)
    }
}

extension UIButton {
    //MARK:- Animate check mark
    func checkboxAnimation(closure: @escaping () -> Void){
        guard let image = self.imageView else {return}
        self.adjustsImageWhenHighlighted = false
        self.isHighlighted = false
        
        UIView.animate(withDuration: 0.1, delay: 0.1, options: .curveLinear, animations: {
            image.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            
        }) { (success) in
            UIView.animate(withDuration: 0.1, delay: 0, options: .curveLinear, animations: {
                self.isSelected = !self.isSelected
                closure()
                image.transform = .identity
            }, completion: nil)
        }
        
    }
}
