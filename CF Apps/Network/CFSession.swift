import Foundation
import UIKit
import Alamofire

class CFSession {
    static let loginAuthToken = "Y2Y6"
    static let accountKey = "currentAccount"
    static let orgKey = "currentOrg"
    
    static var oauthToken: String?
    static var baseURLString: String {
        if let account = CFSession.account() {
            return account.target
        }
        return ""
    }
    
    class func account(account: CFAccount) {
        NSUserDefaults.standardUserDefaults().setObject(account.account, forKey: accountKey)
        
        NSNotificationCenter.defaultCenter().postNotificationName("AccountSwitched", object: nil)
    }
    
    class func account() -> CFAccount? {
        if let key = currentAccountKey() {
            return CFAccountStore.read(key)
        }
        return nil
    }
    
    class func isCurrent(account: CFAccount) -> Bool {
        if let sessionAccount = self.account() {
            return sessionAccount.account == account.account
        }
        return false
    }
    
    class func org(orgGuid: String) {
        return NSUserDefaults.standardUserDefaults().setObject(orgGuid, forKey: orgKey)
    }
    
    class func org() -> String? {
        return NSUserDefaults.standardUserDefaults().objectForKey(orgKey) as! String?
    }
    
    class func reset() {
        CFSession.oauthToken = nil
        cancelRequests()
        
        
        NSUserDefaults.standardUserDefaults().removeObjectForKey(accountKey)
        NSUserDefaults.standardUserDefaults().removeObjectForKey(orgKey)
    }
    
    class func logout(isError: Bool) {
        let account = CFSession.account()!
        reset()
        
        try! CFAccountStore.delete(account)
        
        let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
        if CFAccountStore.isEmpty() {
            let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let loginController = storyboard.instantiateViewControllerWithIdentifier("LoginView") as! LoginViewController
            loginController.authError = isError
            delegate.window?.rootViewController = loginController
        } else {
            let appsController = delegate.showAppsScreen()
            appsController.performSegueWithIdentifier("accounts", sender: nil)
        }
    }
    
    private class func cancelRequests() {
        Alamofire.Manager.sharedInstance.session.getAllTasksWithCompletionHandler { tasks in
            tasks.forEach { $0.cancel() }
        }
    }

    private class func currentAccountKey() -> String? {
        return NSUserDefaults.standardUserDefaults().objectForKey(accountKey) as! String?
    }
}