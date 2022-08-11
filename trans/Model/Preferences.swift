import Foundation

struct Preferences {

  var APPID_baidu: String {
    get {
      let appid = UserDefaults.standard.string(forKey: "APPID_baidu")
        if appid != nil {
            return appid!
      }
      return "20220811001303139"
    }
    set {
      UserDefaults.standard.set(newValue, forKey: "APPID_baidu")
    }
  }
    
    var APPID_youdao: String {
        get {
          let appid = UserDefaults.standard.string(forKey: "APPID_youdao")
            if appid != nil {
                return appid!
          }
          return "275b2317d6f19f5b"
        }
        set {
          UserDefaults.standard.set(newValue, forKey: "APPID_youdao")
        }
    }
    
    var key_baidu: String {
        get {
          let key = UserDefaults.standard.string(forKey: "key_baidu")
            if key != nil {
                return key!
          }
          return "iejU7dq0JPquxHqeJ9GP"
        }
        set {
          UserDefaults.standard.set(newValue, forKey: "key_baidu")
        }
    }
    
    var key_youdao: String {
        get {
          let key = UserDefaults.standard.string(forKey: "key_youdao")
            if key != nil {
                return key!
          }
          return "wTjtJd5LUv0IqTezJf6VhDRwKCU5EJk2"
        }
        set {
          UserDefaults.standard.set(newValue, forKey: "key_youdao")
        }
    }
    
    var key_bce: String { //百度智能云文字识别
        get {
          let key = UserDefaults.standard.string(forKey: "key_bce")
            if key != nil {
                return key!
          }
          return "Rrs6MMgyPSdSyV2mOSBXQnNO"
        }
        set {
          UserDefaults.standard.set(newValue, forKey: "key_bce")
        }
    }
    
    var token_bce: String {
        get {
            let key = UserDefaults.standard.string(forKey: "token_bce")
            if key != nil {
                return key!
            }
            return "0WGh710Wq6YprjYhgr1ZSrxr6bdNTS4p"
        }
        
        set {
            UserDefaults.standard.set(newValue, forKey: "token_bce")
        }
    }
    
    var defaultEngine: Int{
        get {
          let engine = UserDefaults.standard.integer(forKey: "defaultEngine")
          return engine
        }
        set {
          UserDefaults.standard.set(newValue, forKey: "defaultEngine")
        }
    }
    
    var enablePasteTrans: Int{
        get {
          let enable = UserDefaults.standard.integer(forKey: "enablePasteTrans")
          return enable
        }
        set {
          UserDefaults.standard.set(newValue, forKey: "enablePasteTrans")
        }
    }

}

