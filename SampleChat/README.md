# Chat code sample for iOS for ConnectyCube platform

This README introduces [ConnectyCube](https://connectycube.com) iOS chat sample.

Project contains the following features implemented:
- User Login / SignUp / Logout
- Chat dialogs creation
- 1-1 messaging
- Group messaging
- Users search
- Typing statuses
- Delivered / Read statuses
- Last seen
- User / Group profile

## Documentation

All the samples use iOS ConnectyCube SDK. The following tech integration documentation is available:

- [ConnectyCube iOS SDK getting started](https://developers.connectycube.com/ios/)
- [ConnectyCube Chat API documentation](https://developers.connectycube.com/ios/messaging/)


## Getting Started

1. Clone the project
2. Inside project’s folder, run the following command:

	```
	cd SampleChat
	pod install
	```

3. To open the project choose ```SampleChat.xcworkspace```
4. Register new account and application at `https://admin.connectycube.com` and then put Application credentials from 'Overview' page into **AppDelegate** file:

	```
	let APP_ID = ""  
	let AUTH_KEY = ""
	let AUTH_SECRET = ""
	```

5. Run the sample

## Can't build yourself?

Got troubles with building iOS code sample? Just create an issue at [Issues page](https://github.com/ConnectyCube/connectycube-ios-samples/issues)
