#!/bin/bash
set -e
mkdir -p "$(dirname 'HediyeBox/Views/AdvancedView.swift')"
cat > 'HediyeBox/Views/AdvancedView.swift' <<'__HB_0_restore_views_sh__'
import SwiftUI

struct AdvancedView: View {
    @ObservedObject var pip: PiPManager
    @State private var settings = OverlaySettings()

    var body: some View {
        Form {
            Section("Overlay'ler (PiP içinde)") {
                Toggle("Hediye Bildirimi", isOn: $settings.giftEnabled)
                Toggle("Takip Bildirimi", isOn: $settings.followEnabled)
                Toggle("Beğeni Bildirimi", isOn: $settings.likeEnabled)
                Toggle("Hediye Liderlik Tablosu", isOn: $settings.leaderboardEnabled)
                Toggle("Video Bildirimi", isOn: $settings.videoEnabled)
            }

            Section("Görünüm") {
                Toggle("Neon Işığı", isOn: $settings.neon)
                Toggle("Yazı Arka Planı", isOn: $settings.textBackground)
                Slider(value: $settings.iconSize, in: 40...140) {
                    Text("Hediye Boyutu")
                }
                Slider(value: $settings.textSize, in: 14...42) {
                    Text("Yazı Boyutu")
                }
            }

            Section {
                Button("PiP Test Hediyesi") {
                    pip.settings = settings
                    pip.show(.init(kind: .gift, user: "Test Kullanıcı", text: "Gül", icon: nil, amount: 1))
                    if !pip.active { pip.start() }
                }
            }
        }
        .navigationTitle("Gelişmiş Özellikler")
        .onDisappear { pip.settings = settings }
    }
}

__HB_0_restore_views_sh__
mkdir -p "$(dirname 'HediyeBox/Views/EventLogView.swift')"
cat > 'HediyeBox/Views/EventLogView.swift' <<'__HB_1_restore_views_sh__'
import SwiftUI
struct EventLogView:View{@ObservedObject var live:TikTokLiveService;var body:some View{List(live.events){e in VStack(alignment:.leading){Text(e.user).bold();Text("\(e.text)  ×\(e.amount)").foregroundStyle(.secondary)}}.navigationTitle("Hediye Logu")}}

__HB_1_restore_views_sh__
mkdir -p "$(dirname 'HediyeBox/Views/GiftsView.swift')"
cat > 'HediyeBox/Views/GiftsView.swift' <<'__HB_2_restore_views_sh__'
import SwiftUI

struct GiftsView: View {
    @StateObject var catalog = GiftCatalog()
    @State private var query = ""

    var filtered: [GiftCatalogItem] {
        query.isEmpty ? catalog.gifts : catalog.gifts.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        List(filtered) { gift in
            HStack(spacing: 12) {
                Image(systemName: "gift.fill")
                    .font(.title2)
                    .frame(width: 44, height: 44)
                Text(gift.name)
            }
        }
        .searchable(text: $query)
        .navigationTitle("Hediyeler")
    }
}

__HB_2_restore_views_sh__
mkdir -p "$(dirname 'HediyeBox/Views/LoginView.swift')"
cat > 'HediyeBox/Views/LoginView.swift' <<'__HB_3_restore_views_sh__'
import SwiftUI
struct LoginView:View{@EnvironmentObject var session:SessionStore;@State private var email="",password="";@State private var trust=true;var body:some View{NavigationStack{ZStack{Color.black.ignoresSafeArea();VStack(spacing:18){Text("HediyeBox").font(.system(size:42,weight:.black)).foregroundStyle(.white);Text("iPhone").foregroundStyle(.secondary);TextField("E-posta",text:$email).textInputAutocapitalization(.never).keyboardType(.emailAddress).padding().background(.white.opacity(0.1)).clipShape(RoundedRectangle(cornerRadius:14));SecureField("Şifre",text:$password).padding().background(.white.opacity(0.1)).clipShape(RoundedRectangle(cornerRadius:14));Toggle("Bu cihaza 30 gün güven",isOn:$trust).foregroundStyle(.white);Button{Task{await session.requestLogin(email:email,password:password,trust:trust)}}label:{Text(session.busy ? "Bekle…":"Giriş Yap").frame(maxWidth:.infinity).padding().background(.blue).foregroundStyle(.white).clipShape(RoundedRectangle(cornerRadius:14))}.disabled(session.busy);if !session.message.isEmpty{Text(session.message).foregroundStyle(.white).multilineTextAlignment(.center)}}.padding(24)}}.onAppear{email=session.email}}}

__HB_3_restore_views_sh__
mkdir -p "$(dirname 'HediyeBox/Views/MainView.swift')"
cat > 'HediyeBox/Views/MainView.swift' <<'__HB_4_restore_views_sh__'
import SwiftUI

struct MainView: View {
    @EnvironmentObject var session: SessionStore
    @StateObject var live = TikTokLiveService()
    @StateObject var pip = PiPManager()
    @State private var username = UserDefaults.standard.string(forKey: "tiktok_user") ?? ""

    var body: some View {
        TabView {
            NavigationStack {
                ScrollView {
                    VStack(spacing: 16) {
                        header

                        TextField("TikTok kullanıcı adı", text: $username)
                            .textInputAutocapitalization(.never)
                            .padding()
                            .background(.secondary.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 14))

                        Button(live.connected ? "Yayından Ayrıl" : "Yayına Bağlan") {
                            UserDefaults.standard.set(username, forKey: "tiktok_user")
                            if live.connected {
                                live.disconnect()
                            } else {
                                live.connect(username: username)
                            }
                        }
                        .buttonStyle(.borderedProminent)

                        Text(live.status).font(.footnote)

                        Button(pip.active ? "PiP Overlay'i Kapat" : "PiP Overlay'i Başlat") {
                            if pip.active { pip.stop() } else { pip.start() }
                        }
                        .buttonStyle(.borderedProminent)

                        NavigationLink("Gelişmiş Özellikler") { AdvancedView(pip: pip) }
                            .buttonStyle(.bordered)
                        NavigationLink("Hediye Listesi") { GiftsView() }
                            .buttonStyle(.bordered)
                        NavigationLink("Hediye Logu") { EventLogView(live: live) }
                            .buttonStyle(.bordered)
                    }
                    .padding()
                }
                .navigationTitle("HediyeBox")
            }
            .tabItem { Label("Ana Menü", systemImage: "house.fill") }

            NavigationStack { SettingsView(pip: pip) }
                .tabItem { Label("Ayarlar", systemImage: "gearshape.fill") }
        }
    }

    var header: some View {
        VStack(spacing: 5) {
            Text("Merhaba Hediyeboxlu!").font(.title2.bold())
            if let d = session.expiresAt {
                Text("Lisans: \(d.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

__HB_4_restore_views_sh__
mkdir -p "$(dirname 'HediyeBox/Views/RootView.swift')"
cat > 'HediyeBox/Views/RootView.swift' <<'__HB_5_restore_views_sh__'
import SwiftUI
struct RootView:View{@EnvironmentObject var session:SessionStore;var body:some View{Group{if session.loggedIn{MainView()}else{LoginView()}}}}

__HB_5_restore_views_sh__
mkdir -p "$(dirname 'HediyeBox/Views/SettingsView.swift')"
cat > 'HediyeBox/Views/SettingsView.swift' <<'__HB_6_restore_views_sh__'
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var session: SessionStore
    @ObservedObject var pip: PiPManager

    var body: some View {
        Form {
            Section("Overlay") {
                Stepper("Hediye Boyutu: \(Int(pip.settings.iconSize))", value: $pip.settings.iconSize, in: 40...140)
                Toggle("Neon Işığı", isOn: $pip.settings.neon)
                Toggle("Yazı Arka Planı", isOn: $pip.settings.textBackground)
            }

            Section("Hesap") {
                Text(session.email)
                Button("Lisansı Yeniden Kontrol Et") {
                    Task { await session.revalidate() }
                }
                Button("Çıkış Yap", role: .destructive) {
                    session.logout()
                }
            }

            Section("iOS") {
                Text("Android serbest overlay yerine Apple Picture in Picture kullanılır. PiP penceresinin boyutu ve konumu iOS tarafından yönetilir.")
            }
        }
        .navigationTitle("Ayarlar")
    }
}

__HB_6_restore_views_sh__
