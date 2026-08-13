#!/bin/bash
set -e
mkdir -p "$(dirname 'HediyeBox/App/HediyeBoxApp.swift')"
cat > 'HediyeBox/App/HediyeBoxApp.swift' <<'__HB_0_restore_core_sh__'
import SwiftUI

@main
struct HediyeBoxApp: App {
    @StateObject private var session = SessionStore()
    var body: some Scene {
        WindowGroup {
            RootView().environmentObject(session)
                .onOpenURL { url in Task { await session.handleDeepLink(url) } }
        }
    }
}

__HB_0_restore_core_sh__
mkdir -p "$(dirname 'HediyeBox/HediyeBox.entitlements')"
cat > 'HediyeBox/HediyeBox.entitlements' <<'__HB_1_restore_core_sh__'
<?xml version="1.0" encoding="UTF-8"?><!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd"><plist version="1.0"><dict/></plist>
__HB_1_restore_core_sh__
mkdir -p "$(dirname 'HediyeBox/Info.plist')"
cat > 'HediyeBox/Info.plist' <<'__HB_2_restore_core_sh__'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleDisplayName</key><string>HediyeBox</string><key>CFBundleIdentifier</key><string>com.kadir.hediyebox.ios</string><key>CFBundleShortVersionString</key><string>13.2</string><key>CFBundleVersion</key><string>1</string>
<key>UILaunchScreen</key><dict/><key>UISupportedInterfaceOrientations</key><array><string>UIInterfaceOrientationPortrait</string><string>UIInterfaceOrientationLandscapeLeft</string><string>UIInterfaceOrientationLandscapeRight</string></array>
<key>UIBackgroundModes</key><array><string>audio</string><string>picture-in-picture</string></array>
<key>CFBundleURLTypes</key><array><dict><key>CFBundleURLName</key><string>com.kadir.hediyebox.auth</string><key>CFBundleURLSchemes</key><array><string>hediyebox</string></array></dict></array>
<key>NSAppTransportSecurity</key><dict><key>NSAllowsArbitraryLoads</key><false/></dict>
</dict></plist>
__HB_2_restore_core_sh__
mkdir -p "$(dirname 'HediyeBox/Models/AppModels.swift')"
cat > 'HediyeBox/Models/AppModels.swift' <<'__HB_3_restore_core_sh__'
import Foundation

struct APIResponse: Decodable {
    var error: String?; var token: String?; var email: String?; var expiresAt: String?
    var trustedUntil: String?; var licenseStatus: String?; var trusted: FlexibleBool?
}
enum FlexibleBool: Decodable { case bool(Bool), string(String)
    init(from decoder: Decoder) throws { let c = try decoder.singleValueContainer(); if let b=try? c.decode(Bool.self){self = .bool(b)} else {self = .string((try? c.decode(String.self)) ?? "false")} }
    var value: Bool { switch self {case .bool(let b): return b; case .string(let s): return s.lowercased()=="true"} }
}
struct GiftCatalogItem: Codable, Identifiable { let icon:String; let name:String; var id:String { icon } }
struct LiveEvent: Identifiable { let id=UUID(); let kind:Kind; let user:String; let text:String; let icon:String?; let amount:Int; enum Kind {case gift,like,follow,chat} }
struct OverlaySettings: Codable {
    var giftEnabled=true, followEnabled=false, likeEnabled=false, leaderboardEnabled=false, videoEnabled=false
    var neon=true, textBackground=true; var iconSize:Double=72; var textSize:Double=20
}

__HB_3_restore_core_sh__
mkdir -p "$(dirname 'HediyeBox/PiP/PiPManager.swift')"
cat > 'HediyeBox/PiP/PiPManager.swift' <<'__HB_4_restore_core_sh__'
import Foundation
import AVKit
import AVFoundation
import UIKit
import CoreMedia
import CoreVideo

@MainActor final class PiPManager:NSObject,ObservableObject,AVPictureInPictureSampleBufferPlaybackDelegate {
    @Published var active=false; @Published var currentText="HediyeBox hazır"; var settings=OverlaySettings()
    let displayLayer=AVSampleBufferDisplayLayer(); private var pip:AVPictureInPictureController?; private var timer:Timer?; private var observer:NSObjectProtocol?
    override init(){super.init();displayLayer.videoGravity = .resizeAspect;let source=AVPictureInPictureController.ContentSource(sampleBufferDisplayLayer:displayLayer,playbackDelegate:self);pip=AVPictureInPictureController(contentSource:source);pip?.delegate=self;observer=NotificationCenter.default.addObserver(forName:.hbLiveEvent,object:nil,queue:.main){[weak self] n in if let e=n.object as? LiveEvent{Task{@MainActor in self?.show(e)}}};timer=Timer.scheduledTimer(withTimeInterval:1.0/12.0,repeats:true){[weak self]_ in Task{@MainActor in self?.renderFrame()}} }
    deinit{timer?.invalidate();if let observer{NotificationCenter.default.removeObserver(observer)}}
    func start(){try? AVAudioSession.sharedInstance().setCategory(.playback,mode:.moviePlayback,options:[]);try? AVAudioSession.sharedInstance().setActive(true);renderFrame();pip?.startPictureInPicture()}
    func stop(){pip?.stopPictureInPicture()}
    func show(_ e:LiveEvent){switch e.kind{case .gift:guard settings.giftEnabled else{return};currentText="🎁 \(e.user)  •  \(e.text) ×\(e.amount)";case .like:guard settings.likeEnabled else{return};currentText="❤️ \(e.user)  •  +\(e.amount)";case .follow:guard settings.followEnabled else{return};currentText="➕ \(e.user) takip etti";case .chat:return};renderFrame()}
    func renderFrame(){let size=CGSize(width:900,height:300);let r=UIGraphicsImageRenderer(size:size);let img=r.image{ctx in UIColor.black.setFill();ctx.fill(CGRect(origin:.zero,size:size));let p=NSMutableParagraphStyle();p.alignment = .center;let attrs:[NSAttributedString.Key:Any]=[.font:UIFont.systemFont(ofSize:48,weight:.bold),.foregroundColor:UIColor.white,.paragraphStyle:p];(currentText as NSString).draw(in:CGRect(x:24,y:105,width:852,height:90),withAttributes:attrs)};guard let cg=img.cgImage else{return};var pb:CVPixelBuffer?;let attrs=[kCVPixelBufferCGImageCompatibilityKey:true,kCVPixelBufferCGBitmapContextCompatibilityKey:true] as CFDictionary;CVPixelBufferCreate(kCFAllocatorDefault,cg.width,cg.height,kCVPixelFormatType_32BGRA,attrs,&pb);guard let px=pb else{return};CVPixelBufferLockBaseAddress(px,[]);if let c=CGContext(data:CVPixelBufferGetBaseAddress(px),width:cg.width,height:cg.height,bitsPerComponent:8,bytesPerRow:CVPixelBufferGetBytesPerRow(px),space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:CGImageAlphaInfo.premultipliedFirst.rawValue|CGBitmapInfo.byteOrder32Little.rawValue){c.draw(cg,in:CGRect(x:0,y:0,width:cg.width,height:cg.height))};CVPixelBufferUnlockBaseAddress(px,[]);var desc:CMVideoFormatDescription?;CMVideoFormatDescriptionCreateForImageBuffer(allocator:kCFAllocatorDefault,imageBuffer:px,formatDescriptionOut:&desc);guard let d=desc else{return};var timing=CMSampleTimingInfo(duration:CMTime(value:1,timescale:12),presentationTimeStamp:CMClockGetTime(CMClockGetHostTimeClock()),decodeTimeStamp:.invalid);var sb:CMSampleBuffer?;CMSampleBufferCreateReadyWithImageBuffer(allocator:kCFAllocatorDefault,imageBuffer:px,formatDescription:d,sampleTiming:&timing,sampleBufferOut:&sb);if let sb{displayLayer.enqueue(sb)}}
    func pictureInPictureController(_ pictureInPictureController:AVPictureInPictureController,setPlaying playing:Bool){}
    func pictureInPictureControllerTimeRangeForPlayback(_ pictureInPictureController:AVPictureInPictureController)->CMTimeRange{CMTimeRange(start:.zero,duration:.positiveInfinity)}
    func pictureInPictureControllerIsPlaybackPaused(_ pictureInPictureController:AVPictureInPictureController)->Bool{false}
    func pictureInPictureController(_ pictureInPictureController:AVPictureInPictureController,didTransitionToRenderSize newRenderSize:CMVideoDimensions){}
    func pictureInPictureController(_ pictureInPictureController:AVPictureInPictureController,skipByInterval skipInterval:CMTime,completion completionHandler:@escaping()->Void){completionHandler()}
}
extension PiPManager:AVPictureInPictureControllerDelegate { func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController:AVPictureInPictureController){active=true};func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController:AVPictureInPictureController){active=false} }

__HB_4_restore_core_sh__
mkdir -p "$(dirname 'HediyeBox/Services/GiftCatalog.swift')"
cat > 'HediyeBox/Services/GiftCatalog.swift' <<'__HB_5_restore_core_sh__'
import Foundation

final class GiftCatalog: ObservableObject {
    @Published var gifts:[GiftCatalogItem]=[]
    init(){ if let u=Bundle.main.url(forResource:"Gifts",withExtension:"json"),let d=try? Data(contentsOf:u),let v=try? JSONDecoder().decode([GiftCatalogItem].self,from:d){gifts=v} }
    func resolve(name:String)->GiftCatalogItem? { gifts.first{ $0.name.localizedCaseInsensitiveContains(name) || name.localizedCaseInsensitiveContains($0.name) } }
}

__HB_5_restore_core_sh__
mkdir -p "$(dirname 'HediyeBox/Services/KeychainStore.swift')"
cat > 'HediyeBox/Services/KeychainStore.swift' <<'__HB_6_restore_core_sh__'
import Foundation
import Security

enum KeychainStore {
    static func set(_ value:String, for key:String) { let data=Data(value.utf8); let q:[String:Any]=[kSecClass as String:kSecClassGenericPassword,kSecAttrAccount as String:key]; SecItemDelete(q as CFDictionary); var a=q; a[kSecValueData as String]=data; SecItemAdd(a as CFDictionary,nil) }
    static func get(_ key:String)->String? { let q:[String:Any]=[kSecClass as String:kSecClassGenericPassword,kSecAttrAccount as String:key,kSecReturnData as String:true,kSecMatchLimit as String:kSecMatchLimitOne]; var r:AnyObject?; guard SecItemCopyMatching(q as CFDictionary,&r)==errSecSuccess, let d=r as? Data else{return nil}; return String(data:d,encoding:.utf8) }
    static func delete(_ key:String){ let q:[String:Any]=[kSecClass as String:kSecClassGenericPassword,kSecAttrAccount as String:key]; SecItemDelete(q as CFDictionary) }
}

__HB_6_restore_core_sh__
mkdir -p "$(dirname 'HediyeBox/Services/LicenseService.swift')"
cat > 'HediyeBox/Services/LicenseService.swift' <<'__HB_7_restore_core_sh__'
import Foundation
import UIKit

@MainActor final class SessionStore: ObservableObject {
    @Published var loggedIn=false; @Published var busy=false; @Published var message=""; @Published var email=""; @Published var expiresAt:Date?
    private let base="https://www.hediyebox.com.tr/api/"
    private let iso=ISO8601DateFormatter()
    private var deviceId:String {
        if let v=KeychainStore.get("hb_device_id"){return v}
        let v=UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString; KeychainStore.set(v,for:"hb_device_id"); return v
    }
    init(){ email=UserDefaults.standard.string(forKey:"hb_email") ?? ""; if let t=KeychainStore.get("hb_token"), !t.isEmpty { loggedIn=true; Task{await revalidate()} } }
    func requestLogin(email:String,password:String,trust:Bool) async {
        busy=true; defer{busy=false}; self.email=email
        do {
            let check:APIResponse = try await post("app-check-trusted-device", body:["email":email,"password":password,"deviceId":deviceId])
            if check.trusted?.value == true, let token=check.token, check.licenseStatus=="active" { save(token:token,email:email,expires:check.expiresAt,trusted:check.trustedUntil); return }
            let _:APIResponse = try await post("app-send-magic-link", body:["email":email,"password":password,"deviceId":deviceId,"trustDevice":trust])
            message="Giriş bağlantısı e-postana gönderildi. Gmail'deki mavi butona bas."
        } catch { message=error.localizedDescription }
    }
    func handleDeepLink(_ url:URL) async { guard url.scheme=="hediyebox", url.host=="auth", let c=URLComponents(url:url,resolvingAgainstBaseURL:false), let token=c.queryItems?.first(where:{$0.name=="token"})?.value else{return}; busy=true; defer{busy=false}; do { let r:APIResponse=try await post("app-verify-magic-link",body:["token":token,"deviceId":deviceId]); guard let st=r.token else{throw NSError(domain:"HediyeBox",code:1,userInfo:[NSLocalizedDescriptionKey:r.error ?? "Bağlantı geçersiz"])}; save(token:st,email:r.email ?? email,expires:r.expiresAt,trusted:r.trustedUntil) } catch { message=error.localizedDescription } }
    func revalidate() async { guard let token=KeychainStore.get("hb_token") else {loggedIn=false;return}; do { var req=URLRequest(url:URL(string:base+"app-session-check")!); req.httpMethod="POST"; req.setValue("Bearer \(token)",forHTTPHeaderField:"Authorization"); let (data,res)=try await URLSession.shared.data(for:req); guard let h=res as? HTTPURLResponse else{return}; let r=try JSONDecoder().decode(APIResponse.self,from:data); if h.statusCode<300 && r.licenseStatus=="active" { expiresAt=parse(r.expiresAt); loggedIn=true } else { logout() } } catch { } }
    func logout(){KeychainStore.delete("hb_token");loggedIn=false;expiresAt=nil}
    private func save(token:String,email:String,expires:String?,trusted:String?){KeychainStore.set(token,for:"hb_token");UserDefaults.standard.set(email,forKey:"hb_email");self.email=email;self.expiresAt=parse(expires);loggedIn=true;message=""}
    private func parse(_ s:String?)->Date? { guard let s else{return nil}; return iso.date(from:s) }
    private func post<T:Decodable>(_ path:String, body:[String:Any]) async throws -> T { var req=URLRequest(url:URL(string:base+path)!);req.httpMethod="POST";req.setValue("application/json",forHTTPHeaderField:"Content-Type");req.httpBody=try JSONSerialization.data(withJSONObject:body);let(data,res)=try await URLSession.shared.data(for:req);guard let h=res as? HTTPURLResponse else{throw URLError(.badServerResponse)};let dec=JSONDecoder(); if h.statusCode>=400 { if let r=try? dec.decode(APIResponse.self,from:data){throw NSError(domain:"HediyeBox",code:h.statusCode,userInfo:[NSLocalizedDescriptionKey:r.error ?? "Sunucu hatası"])} };return try dec.decode(T.self,from:data) }
}

__HB_7_restore_core_sh__
mkdir -p "$(dirname 'HediyeBox/Services/TikTokLiveService.swift')"
cat > 'HediyeBox/Services/TikTokLiveService.swift' <<'__HB_8_restore_core_sh__'
import Foundation

@MainActor final class TikTokLiveService: ObservableObject {
    @Published var connected=false; @Published var status="Bağlı değil"; @Published var events:[LiveEvent]=[]
    private var task:URLSessionWebSocketTask?; private var generation=0
    private let defaultKey="euler_NWI3NjVhODg3ZjRlM2U1ODEwYTM0MGNmYzNlMjAyY2EzODcwOTIyMjA2NTgzNDM4ZTQxZGFi"
    private let keyURL=URL(string:"https://raw.githubusercontent.com/clarksonjeremy909/hediyebox/refs/heads/main/keyjsonvirus.json")!
    func connect(username:String){ disconnect(); let user=username.trimmingCharacters(in:.whitespacesAndNewlines).replacingOccurrences(of:"@",with:"");guard !user.isEmpty else{status="TikTok kullanıcı adı gir";return};generation += 1;let g=generation;status="Bağlanıyor…";Task{ let key=await fetchKey();guard g==generation else{return}; var c=URLComponents(string:"wss://ws.eulerstream.com")!;c.queryItems=[URLQueryItem(name:"uniqueId",value:user),URLQueryItem(name:"apiKey",value:key)];let t=URLSession.shared.webSocketTask(with:c.url!);task=t;t.resume();connected=true;status="Bağlandı: @\(user)";receive(t,g:g) } }
    func disconnect(){generation += 1;task?.cancel(with:.normalClosure,reason:nil);task=nil;connected=false;status="Bağlı değil"}
    private func receive(_ t:URLSessionWebSocketTask,g:Int){t.receive{[weak self] result in Task{@MainActor in guard let self, g==self.generation else{return};switch result{case .failure(let e):self.connected=false;self.status="Bağlantı koptu: \(e.localizedDescription)";case .success(let m):let text:String;switch m{case .string(let s):text=s;case .data(let d):text=String(data:d,encoding:.utf8) ?? "";@unknown default:text=""};self.parse(text);self.receive(t,g:g)}}}}
    private func parse(_ text:String){guard let d=text.data(using:.utf8),let root=try? JSONSerialization.jsonObject(with:d) as? [String:Any] else{return}; if let arr=root["messages"] as? [[String:Any]] { for m in arr{parseObject(m)} } else {parseObject(root)} }
    private func parseObject(_ o:[String:Any]){ let type=((o["event"] ?? o["type"] ?? o["eventType"]) as? String ?? "").lowercased(); let data=(o["data"] as? [String:Any]) ?? o; let user=(data["user"] as? [String:Any]); let name=(user?["nickname"] as? String) ?? (user?["uniqueId"] as? String) ?? (data["nickname"] as? String) ?? "İzleyici"; if type.contains("gift") { let gift=(data["giftName"] as? String) ?? ((data["gift"] as? [String:Any])?["name"] as? String) ?? "Hediye"; let count=(data["repeatCount"] as? Int) ?? (data["count"] as? Int) ?? 1;push(.init(kind:.gift,user:name,text:gift,icon:nil,amount:max(1,count))) } else if type.contains("like") { let n=(data["likeCount"] as? Int) ?? (data["count"] as? Int) ?? 1;push(.init(kind:.like,user:name,text:"Beğeni",icon:nil,amount:max(1,n))) } else if type.contains("follow") {push(.init(kind:.follow,user:name,text:"Takip etti",icon:nil,amount:1))} else if type.contains("chat") || type.contains("comment") { let c=(data["comment"] as? String) ?? (data["text"] as? String) ?? ""; if !c.isEmpty{push(.init(kind:.chat,user:name,text:c,icon:nil,amount:1))} } }
    private func push(_ e:LiveEvent){events.insert(e,at:0);if events.count>200{events.removeLast(events.count-200)};NotificationCenter.default.post(name:.hbLiveEvent,object:e)}
    private func fetchKey() async ->String { do{let(d,_)=try await URLSession.shared.data(from:keyURL);if let j=try JSONSerialization.jsonObject(with:d) as? [String:Any]{return (j["apiKey"] as? String) ?? (j["key"] as? String) ?? (j["euler_api_key"] as? String) ?? defaultKey}}catch{};return defaultKey }
}
extension Notification.Name { static let hbLiveEvent=Notification.Name("HediyeBoxLiveEvent") }

__HB_8_restore_core_sh__
