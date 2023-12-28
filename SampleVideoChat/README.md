# SampleVideoChat 

This project contains [ConnectyCube](https://developers.connectycube.com/ios/?id=create-connectycube-app) iOS video sample. 

- Inside project’s folder, run the following command:```pod install```

- To open the project choose ```SampleVideoChat.xcworkspace```

- In the *LoginViewController* fill in the next lines with your credentials:

```let APP_ID = ""```  
```let AUTH_KEY = ""```  
```let AUTH_SECRET = ""```

    let user: ConnectycubeUser = ConnectycubeUser().apply{
        $0.login = ""
        $0.password = ""
        $0.id = 
    }
    
- Run the sample

## Documentation

All the samples use iOS ConnectyCube SDK. The following tech integration documentation is available:

- [iOS SDK documentation](https://developers.connectycube.com/ios/)

## License

See [LICENSE](LICENSE).
