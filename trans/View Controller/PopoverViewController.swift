//
//  PopoverViewController.swift
//  trans
//
//  Created by Seon Wong on 2020/1/24.
//  Copyright © 2020 rhinoc. All rights reserved.
//
import AppKit
import Cocoa
import CommonCrypto
import UserNotifications
import Foundation

var temp = ""
var tempTrans = ""
var to = "auto"
var prefs = Preferences()

class PopoverViewController: NSViewController {
    let appDelegate = NSApplication.shared.delegate as! AppDelegate
    
    
    @IBOutlet weak var translateMode: NSPopUpButton! //选择翻译模式
    @IBOutlet weak var inputText: NSSearchField! //输入框
    @IBOutlet weak var resultText: NSTextField! //翻译结果
    @IBOutlet weak var clearButton: NSButton! //清空结果按钮
    @IBOutlet weak var copyButton: NSButton! //复制结果按钮
    @IBOutlet weak var gearButton: NSButton! //设置按钮
    
    @IBAction func onModeChange(_ sender: NSPopUpButton) {
        switch translateMode.indexOfSelectedItem{
        case 0:
            to = "auto"
        case 1:
            to = "zh"
            break
        case 2:
            to = "en"
            break
        default:
            to = "auto"
        }
    }
    
    @IBAction func onSearch(_ sender: NSSearchField) {
        let cur = sender.stringValue;
        if (cur != temp){
            getTranslationResult(str: cur, type:"search")
            temp = cur
            copyButton.title = "Copy"
        }
    }
    
    @IBAction func onClear(_ sender: NSButton) {
        inputText.stringValue = "";
        resultText.stringValue = "";
    }
    
    @IBAction func onCopy(_ sender: NSButton) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(tempTrans, forType: .string)
        copyButton.title = "Copied"
    }
    
    @IBAction func onGear(_ sender: NSButton) {
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(onPasteboardChanged), name: .NSPasteboardDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onOCR), name: .NSOCR, object: nil)
    }
    
    //通知相关
    
    @objc func onPasteboardChanged(_ notification: Notification) {
        guard let pb = notification.object as? NSPasteboard else { return }
        guard let items = pb.pasteboardItems else { return }
        
        guard let cur = items.first?.string(forType: .string) else { return }
        if (cur != temp && cur != tempTrans){
            getTranslationResult(str: cur, type:"copy")
            temp = cur
        }
    }
    
    @objc func onOCR(_ notification: Notification) {
        let text = notification.object as? String
        getTranslationResult(str: text!, type:"ocr")
    }
    
    //调用翻译API相关
    
    func determineLang(str: String) -> String {
        for (_, value) in str.enumerated() {
            if ("\u{4E00}" <= value  && value <= "\u{9FA5}") {
                return "zh"
            }
        }
        return "en"
    }
    
    func getTranslationResult(str:String, type:String) -> Void {
        
        print("zzp01 copy_str == ", str);
        
        var to_temp = to
        
        if (str.isEmpty) {
            resultText.stringValue = ""
            return
        }
        
        let srclang = determineLang(str: str) //确定待识别语言语种
        if (srclang == to) { //若目标语种和原文语种相同，不识别
            return
        }
        else if (to == "auto" && srclang == "zh") {
            to_temp = "en"
        }
        else if (to == "auto" && srclang == "en") {
            to_temp = "zh"
        }
        
        //读取配置
        let APPID_baidu = prefs.APPID_baidu
        let APPID_youdao = prefs.APPID_youdao
        let key_baidu = prefs.key_baidu
        let key_youdao = prefs.key_youdao
        let defaultEngine = prefs.defaultEngine
        
        var appid = ""
        var salt = "1435660288"
        var key = ""
        var sign = ""
        var base = ""
        var curtime = ""
        var url = ""
        
        
        if (defaultEngine==0){ //百度翻译
            appid = APPID_baidu
            key = key_baidu
            sign = md5Hash(str: appid+str+salt+key)
            base = "https://fanyi-api.baidu.com/api/trans/vip/translate"
            
            url = base+"?q="+str.urlEncoded()+"&appid="+appid+"&salt="+salt+"&sign="+sign+"&from=auto"+"&to="+to_temp
        }
        else { //有道翻译
            appid = APPID_youdao
            key = key_youdao
            curtime = Date().timeStamp
            base = "https://openapi.youdao.com/api"
            sign = sha256(str: appid+str+salt+String(curtime)+key)
            if (to_temp=="zh") {
                to_temp="zh-CHS"
            }
            url = base+"?q="+str.urlEncoded()+"&from=auto&to="+to_temp+"&appKey="+appid+"&salt="+salt+"&sign="+sign+"&signType=v3"+"&curtime="+curtime;
        }
        
        func getTranslationSuccess(data: Data?, response: URLResponse?, error: Error?) -> Void {
            DispatchQueue.main.async {
                do {
                    let decoder = JSONDecoder()

                    struct Res_bd: Codable {
                        var from: String // 返回用户指定的语言，或自动检测的语言（源语言设为auto时）
                        var to: String // 返回用户指定的目标语言(这里就是 en 或者 zh)
                        var trans_result: [TransResult] // 返回翻译结果，包含src 和 dst 字段。
                        
                        struct TransResult: Codable {
                            let src: String // query原文
                            let dst: String // 译文
                        }
                    }

                    struct Res_yd: Codable {
                        let tSpeakURL: String?
                        let returnPhrase: [String]?
                        let web: [Web]?
                        let query: String
                        let translation: [String]
                        let errorCode: String?
                        let dict, webdict: Dict?
                        let basic: Basic?
                        let l: String?
                        let speakURL: String?
                        
                        enum CodingKeys: String, CodingKey {
                            case tSpeakURL = "tSpeakUrl"
                            case returnPhrase, web, query, translation, errorCode, dict, webdict, basic, l
                            case speakURL = "speakUrl"
                        }
                    }
                    
                    struct Basic: Codable {
                        let examType: [String]?
                        let usPhonetic, phonetic, ukPhonetic: String?
                        let ukSpeech: String?
                        let explains: [String]?
                        let usSpeech: String?
                        
                        enum CodingKeys: String, CodingKey {
                            case examType = "exam_type"
                            case usPhonetic = "us-phonetic"
                            case phonetic
                            case ukPhonetic = "uk-phonetic"
                            case ukSpeech = "uk-speech"
                            case explains
                            case usSpeech = "us-speech"
                        }
                    }
                    
                    struct Dict: Codable {
                        let url: String
                    }
                    
                    struct Web: Codable {
                        let value: [String]
                        let key: String
                    }
                    
                    if (data != nil) {
                        if (defaultEngine==0){
                            let r = try decoder.decode(Res_bd.self, from: data!)
                            
                            // modify：2022年08月11日21:09:54 by zhangzhengping
                            // 对于copy的内容是多行情况，把response拼接成后打印出来
                            var src_str = "";
                            var result_str = "";
                            
                            for index in r.trans_result {
                                src_str += index.src + "\n";
                                result_str += index.dst + "\n";
                            }
                            
                            // 去除最后一个\n
                            src_str = String(src_str.dropLast())
                            result_str = String(result_str.dropLast())
                            
                            tempTrans = result_str;
                            temp = src_str;
                            
//                            print("zzp03 result_str == ", result_str);
                        }
                        else{
//                            print("youdao")
                            let r = try decoder.decode(Res_yd.self, from: data!)
                            print("r")
                            tempTrans = r.translation[0];
                            temp = r.query;
                        }
                        
                        // 调用自封装notify函数，把内容通过mac系统调用打到“通知中心”
                        if (type == "copy" || type == "ocr" ) {
                            self.notify(title: temp, body: tempTrans, type:type)
                        }
                        else {
                            self.resultText.stringValue = tempTrans;
                        }
                    }
                    
                } catch{
                    let str = String(decoding: data!, as: UTF8.self)
//                    print("erro response :", str)
                    
                    // modify：2022年08月11日20:54:18 by zhangzhengping
                    // 请求server出错，把出错body打印出来；
                    self.resultText.stringValue = "Error";
                    if (type == "copy" ) {
                        self.notify(title: "Error", body: str, type:type)
                    }
                    return
                }
            }
        }
        
        func sendGetRequest(url: String, completionHandler: @escaping ((Data?,URLResponse?,Error?)->Void)) {
            let session = URLSession(configuration: .default)
            let task = session.dataTask(with: URL(string: url)!, completionHandler: completionHandler)
            task.resume()
        }
        
        sendGetRequest(url: url, completionHandler: getTranslationSuccess(data:response:error:))
    }
    
    func md5Hash (str: String) -> String {
        if let strData = str.data(using: String.Encoding.utf8) {
            var digest = [UInt8](repeating: 0, count:Int(CC_MD5_DIGEST_LENGTH))
            strData.withUnsafeBytes {
                CC_MD5($0.baseAddress, UInt32(strData.count), &digest)
            }
            var md5String = ""
            for byte in digest {
                md5String += String(format:"%02x", UInt8(byte))
            }
            return md5String
        }
        return ""
    }
    
    func sha256(str : String) -> String {
        if let strData = str.data(using: String.Encoding.utf8) {
            var digest = [UInt8](repeating: 0, count:Int(CC_SHA256_DIGEST_LENGTH))
            strData.withUnsafeBytes {
                CC_SHA256($0.baseAddress, CC_LONG(strData.count), &digest)
            }
            var sha256String = ""
            for byte in digest {
                sha256String += String(format:"%02x", UInt8(byte))
            }
            return sha256String
        }
        return ""
    }
    
    func notify(title: String,body: String,type: String){
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { success, error in
            if error == nil {
                if success == true {
//                    print("Permission granted")
                    let content = UNMutableNotificationContent()
                    content.title = title;
                    content.body = body;
                    content.userInfo = ["method": "new"]
                    content.categoryIdentifier = "TRANSLATION_RESULT"
                    var acceptAction = UNNotificationAction(identifier: "COPY_RESULT_ACTION", title: "Copy", options: .init(rawValue: 0))
                    var declineAction = UNNotificationAction(identifier: "CLOSE_ACTION", title: "Close", options: .init(rawValue: 0))
                    if (type == "ocr"){
                        acceptAction = UNNotificationAction(identifier: "COPY_RESULT_ACTION", title: "译文", options: .init(rawValue: 0))
                        declineAction = UNNotificationAction(identifier: "COPY_SOURCE_ACTION", title: "原文", options: .init(rawValue: 0))
                    }
                    
                    
                    let testCategory = UNNotificationCategory(identifier: "TRANSLATION_RESULT",
                                                              actions: [acceptAction,declineAction],
                                                              intentIdentifiers: [],
                                                              hiddenPreviewsBodyPlaceholder: "",
                                                              options: .customDismissAction)
                    
                    let request = UNNotificationRequest(identifier: "NOTIFICATION_REQUEST",
                                                        content: content,
                                                        trigger: nil)
                    
                    // Schedule the request with the system.
                    let notificationCenter = UNUserNotificationCenter.current()
                    notificationCenter.delegate = self
                    notificationCenter.setNotificationCategories([testCategory])
                    notificationCenter.add(request) { (error) in
                        if error != nil {
                            // Handle any errors.
                        }
                    }
                }
                else {
                    print("Permission denied")
                }
            }
            else {
                print("error")
            }
        }
    }
    
}

extension PopoverViewController {
    static func freshController() -> PopoverViewController {
        let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
        let identifier = NSStoryboard.SceneIdentifier("PopoverViewController")
        guard let viewcontroller = storyboard.instantiateController(withIdentifier: identifier) as? PopoverViewController else {
            fatalError("Please check Main.storyboard")
        }
        return viewcontroller
    }
}

extension String {
    //将原始的url编码为合法的url
    func urlEncoded() -> String {
        let encodeUrlString = self.addingPercentEncoding(withAllowedCharacters:
            .urlQueryAllowed)
        return encodeUrlString ?? ""
    }
    
    //将编码后的url转换回原始的url
    func urlDecoded() -> String {
        return self.removingPercentEncoding ?? ""
    }
}

extension PopoverViewController: UNUserNotificationCenterDelegate {
    // 用户点击弹窗后的回调
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        switch response.actionIdentifier {
        case "COPY_RESULT_ACTION":
            let pb = NSPasteboard.general
            pb.clearContents()
            pb.setString(tempTrans, forType: .string)
            break
        case "COPY_SOURCE_ACTION":
            let pb = NSPasteboard.general
            pb.clearContents()
            pb.setString(temp, forType: .string)
            break
        case "CLOSE_ACTION":
            print("Nothing to do")
            break
        default:
            break
        }
        completionHandler()
    }
    
    // 配置通知发起时的行为 alert -> 显示弹窗, sound -> 播放提示音
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .sound])
    }
}

extension Date {
    var timeStamp : String {
        let timeInterval: TimeInterval = self.timeIntervalSince1970
        let timeStamp = Int(timeInterval)
        return "\(timeStamp)"
    }
}

class VerticallyCenteredTextFieldCell: NSTextFieldCell {
    override func drawingRect(forBounds theRect: NSRect) -> NSRect {
        var newRect:NSRect = super.drawingRect(forBounds: theRect)
        let textSize:NSSize = self.cellSize(forBounds: theRect)
        let heightDelta:CGFloat = newRect.size.height - textSize.height
        if heightDelta > 0 {
            newRect.size.height = textSize.height
            newRect.origin.y += heightDelta / 2
        }
        return newRect
    }
}
