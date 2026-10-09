import SwiftUI

/// How the app treats the person's information, and the terms they use it under.
struct PrivacyPolicyView: View {
  var body: some View {
    List {
      Section {
        PolicyItem(
          title: "Your data stays on your device", systemImage: "lock.iphone",
          text: "The places you’ve been, your levels and your settings are stored only on this device. I don’t collect, see or share any of it. There are no accounts, ads or analytics.")
        PolicyItem(
          title: "You’re in control", systemImage: "trash",
          text: "Reset clears every place in Settings at any time, and deleting the app deletes everything it stored.")
        PolicyItem(
          title: "JapanEx", systemImage: "globe.asia.australia",
          text: "Opening your prefectures in JapanEx puts their levels in the web address, so JapanEx by Zhung can draw them on its map. Nothing else goes with them. JapanEx is run by its own author, under its own policies.")
      } header: {
        Text("Privacy")
      }

      Section {
        PolicyItem(
          title: "Terms and conditions", systemImage: "signature",
          text: "By downloading and using this app, these terms apply to you. I intend to make it as useful as possible and may update it often to do so, but I can’t guarantee it will be useful to you. Some of its information, such as maps and flags, comes from third parties, and I accept no liability for any loss, direct or indirect, from relying on it. This policy may be updated from time to time, so please review it now and then. If you have any questions, please don’t hesitate to get in touch.")
        Link(destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!) {
          Label("Licensed Application End User License Agreement", systemImage: "doc.text")
        }
      } header: {
        Text("Terms")
      }
    }
    .navigationTitle("Privacy Policy")
    .navigationBarTitleDisplayMode(.inline)
  }
}

/// One point of the policy: a heading beside its symbol, and the detail beneath.
private struct PolicyItem: View {
  var title: LocalizedStringKey
  var systemImage: String
  var text: LocalizedStringKey

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Label(title, systemImage: systemImage)
        .font(.headline)
      Text(text)
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)
    }
    .padding(.vertical, 6)
    .accessibilityElement(children: .combine)
  }
}
