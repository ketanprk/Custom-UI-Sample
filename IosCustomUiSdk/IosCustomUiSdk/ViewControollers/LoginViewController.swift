
import UIKit
import Applozic

class LoginViewController: UIViewController {
    
    @IBOutlet weak var userName: UITextField!
    @IBOutlet weak var password: UITextField!
    
    @IBOutlet weak var emailId: UITextField!
    var  applozicClient = ApplozicClient()
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        applozicClient = ApplozicClient(applicationKey: "applozic-sample-app") as ApplozicClient //Pass applicationKey here
        // Do any additional setup after loading the view.
        ALUserDefaultsHandler.setUserAuthenticationTypeId(1) // APPLOZIC
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func getStartedBtn(_ sender: AnyObject) {
        
        let alUser : ALUser =  ALUser()
        if(self.userName.text as NSString? == nil || (self.userName.text! as NSString).length == 0 )
        {
            let alert = UIAlertController(title: "Applozic", message: "Please enter userId ", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Okay", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return;
        }
        alUser.userId = self.userName.text
        ALUserDefaultsHandler.setUserId(alUser.userId)
        
        print("userName:: " , alUser.userId)
        if(!((emailId.text?.isEmpty)!)){
            alUser.email = emailId.text
            ALUserDefaultsHandler.setEmailId(alUser.email)
        }
        
        if (!((password.text?.isEmpty)!)){
            alUser.password = password.text
            ALUserDefaultsHandler.setPassword(alUser.password)
        }
        registerUserToApplozic(alUser: alUser)
    }
    
    private func registerUserToApplozic(alUser: ALUser) {
        
        
        if ALUserDefaultsHandler.isLoggedIn() {
            applozicClient.logoutUser { (error, response) in
                
                if(error == nil){
                    self.login(alUser: alUser)
                }
                
            }
        }else{
            self.login(alUser: alUser)
        }
        
    }
    
    public func login(alUser: ALUser){
        applozicClient = ApplozicClient(applicationKey: "applozic-sample-app") as ApplozicClient //Pass applicationKey here
        applozicClient.loginUser(alUser) { (response, error) in
            
            if(error == nil){
                
                let conversationVC = ConversationListViewController();
                let nav = ALKBaseNavigationViewController(rootViewController: conversationVC)
                self.present(nav, animated: false, completion: nil)
            }else{
                NSLog("[REGISTRATION] Applozic user registration error: %@", error.debugDescription)
                
            }
        }
    }
}


