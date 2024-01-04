# Video Chat code sample for iOS for ConnectyCube platform 

This README introduces [ConnectyCube](https://connectycube.com) iOS video sample. 

Project contains the following features implemented:
- User authorization
- Group video calls (up to 4 users)
- Mute/unmute microphone
- Switch cameras

## Documentation

All the samples use iOS ConnectyCube SDK. The following tech integration documentation is available:

- [ConnectyCube iOS SDK getting started](https://developers.connectycube.com/ios/)
- [ConnectyCube Video Chat API documentation](https://developers.connectycube.com/ios/videocalling)

## Getting Started

1. Clone the project
2. Inside project’s folder, run the following command:

	```
	cd SampleVideoChat
	pod install
	```

3. To open the project choose ```SampleVideoChat.xcworkspace```
4. Register new account and application at `https://admin.connectycube.com` and then put Application credentials from 'Overview' page into **LoginViewController** file:

	```
	let APP_ID = ""  
	let AUTH_KEY = ""
	let AUTH_SECRET = ""
	```

5. At `https://admin.connectycube.com`, create from 2 to 4 users in 'Users' module and put them into	**LoginViewController** file as well:

	```
	let user: ConnectycubeUser = ConnectycubeUser().apply{
	    $0.login = ""
	    $0.password = ""
	    $0.id = 
	}
```
 
6. Run the sample

## Can't build yourself?

Got troubles with building iOS code sample? Just create an issue at [Issues page](https://github.com/ConnectyCube/connectycube-ios-samples/issues)
