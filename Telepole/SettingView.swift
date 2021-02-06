//
//  HomeView.swift
//  Telepole
//
//  Created by 丁涯 on 2020/12/23.
//

import SwiftUI
import SDWebImageSwiftUI
import AuthenticationServices
import MapKit

struct SettingView: View {
//    @Binding var showStatus: ShowStatus
    @ObservedObject var userSettings = UserSettings()
    @Binding var trackingMode: MapUserTrackingMode
        
    var body: some View {
        VStack(spacing: 0) {
//            CardHeader(flag: $showStatus.isShowSetting, hasEditButton: false, title: "设置")
            
            if userSettings.user == ""{
                SignInButton()
                    .signInWithAppleButtonStyle(.white)
                    .frame(maxWidth: 375)
                    .frame(height: 44)
                    .padding()
            }

            Form{
                Section(header: Text("定位权限")) {
                    Toggle(isOn: $userSettings.isShareMyLocation) {
                        Text("共享我的位置")
                            .font(.body)
                    }
                }
                
                Section(header: Text("地图设置")) {
                    Toggle(isOn: $userSettings.trackingMode) {
                        Text("默认追随模式")
                            .font(.body)
                    }.onChange(of: userSettings.trackingMode) { (value) in
                        if value {
                            trackingMode = MapUserTrackingMode.follow
                        }else {
                            trackingMode = MapUserTrackingMode.none
                        }
                    }
                }
                
                if userSettings.user != "" {
                    Section(header: Text("当前用户: \(userSettings.email)")) {
                        Button(action: {
                            userSettings.user = ""
                            userSettings.email = ""
                            userSettings.fullName = ""
                        }){
                            Text("注销")
                        }
                    }
                }
            }
        }
        .background(VisualEffectBlur(blurStyle: .systemChromeMaterial))
        .cornerRadius(20)
    }
}

//struct HomeView_Previews: PreviewProvider {
//    static var previews: some View {
//        HomeView()
//    }
//}

struct TipsAnonymous: View {
    var body: some View {
        Text("Session:")
            .font(.body)
            .foregroundColor(Color("GrayColor"))
    }
}

struct SignInButton: View {
    @ObservedObject var userSettings = UserSettings()
    
    var body: some View {
        SignInWithAppleButton(
            onRequest: { request in
                request.requestedScopes = [.fullName, .email]
            },
            onCompletion: { result in
                switch result {
                case .success(let authResults):
                    switch authResults.credential {
                    case let appleIDCredential as ASAuthorizationAppleIDCredential:
                        if appleIDCredential.email == nil{
                            // 已经注册过，直接登陆
                            let user = appleIDCredential.user
                            UserApi().login(user) { (user) in
                                userSettings.user = user.user
                                userSettings.email = user.email
                                userSettings.fullName = user.fullName
                            }
                        }else {
                            // 新注册
                            let fullName = String(describing: appleIDCredential.fullName?.familyName)
                                + String(describing: appleIDCredential.fullName?.givenName)
                            let email = String(describing: appleIDCredential.email)
                            let user = appleIDCredential.user
                            let newUser = UserModel(user: user, fullName: fullName, email: email)
                            UserApi().register(newUser) { (user) in
                                userSettings.user = user.user
                                userSettings.email = user.email
                                userSettings.fullName = user.fullName
                            }
                        }
                        
                    case let passwordCredential as ASPasswordCredential:
                        let username = passwordCredential.user
                        let password = passwordCredential.password
                        print(username, password)
                    default:
                        break
                    }
                case .failure(let error):
                    print("failure", error)
                }
            }
        )
    }
}
