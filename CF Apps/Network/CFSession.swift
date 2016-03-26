//
//  CFSession.swift
//  CF Apps
//
//  Created by Dwayne Forde on 2015-12-21.
//  Copyright © 2015 Dwayne Forde. All rights reserved.
//

import Foundation

class CFSession {
    static let loginAuthToken = "Y2Y6"
    static let orgKey = "currentOrg"
    
    static var oauthToken: String?
    static var baseURLString: String {
        do {
            return try Keychain.getApiURL()
        } catch {
            return ""
        }
    }
    
    class func save(apiURL: String, authURL: String, username: String, password: String) {
        Keychain.setCredentials([
            "apiURL": apiURL,
            "authURL": authURL,
            "username": username,
            "password": password
            ])
    }
    
    class func reset() {
        let domain = NSBundle.mainBundle().bundleIdentifier
        
        Keychain.clearCredentials()
        CFSession.oauthToken = nil
        NSUserDefaults.standardUserDefaults().removePersistentDomainForName(domain!)
    }
    
    class func isEmpty() -> Bool {
        return (CFSession.oauthToken == nil || !Keychain.hasCredentials())
    }
    
    class func setOrg(orgGuid: String) {
        return NSUserDefaults.standardUserDefaults().setObject(orgGuid, forKey: orgKey)
    }
    
    class func getOrg() -> String? {
        return NSUserDefaults.standardUserDefaults().objectForKey(orgKey) as! String?
    }
    
    class func isOrgStale(currentOrgs: [String]) -> Bool {
        return CFSession.getOrg() == nil || !currentOrgs.contains(CFSession.getOrg()!)
    }
}