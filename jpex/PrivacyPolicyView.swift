//
//  PrivacyPolicyView.swift
//  jpex
//
//  Created by Terran Kroft on 7/6/2024.
//

import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        List {
            GroupBox(label: Label("Overview", systemImage: "circle.fill")) {
                Text("This Privacy Policy describes how your personal information is used in this Application.")
            }
            GroupBox(label: Label("Data collection", systemImage: "hand.raised")) {
                Text("I do not use, or have access to any of your personal data recorded in the Application. All data is kept on your device and can be deleted when you delete the Application. We do not share your personal information with third parties.")
            }
            GroupBox(label: Label("Terms and Conditions", systemImage: "signature")) {
                Text("By downloading and using this application, these terms and conditions apply to you. I intend to make this application as useful and efficient as possible. I may update the application frequently in order to do so. However, I cannot guarantee that the service may be useful or efficient to you and consequently am not responsible for that. The application relies on third-party data for some of its information. I accept no liability for any loss, direct or indirect, you experience as a result of relying on this application. An internet connection may be necessary to receive updates to the application or to the data it offers. You may be charged by your internet provider for the data used.This Privacy Policy may be updated from time to time. You are advised to review it. If you have further questions about the Privacy Policy, please do not hesitate to contact me.")
            }
            GroupBox(label: Label("Acknowledgements", systemImage: "speaker.fill")) {
                VStack {
                    Text("This Application was inspired by \"JapanEx\" by Zhung.")
                }
                
            }
        }
        .navigationTitle("Privacy Policy")
    }
}

#Preview {
    PrivacyPolicyView()
}
