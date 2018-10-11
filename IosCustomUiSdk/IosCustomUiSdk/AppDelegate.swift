//
//  AppDelegate.swift
//  IosCustomUiSdk
//
//  Created by apple on 27/09/18.
//  Copyright © 2018 Applozic. All rights reserved.
//

import UIKit
import Applozic
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate,ApplozicUpdatesDelegate,UNUserNotificationCenterDelegate {


    var applozicClient = ApplozicClient()

    public var userId: String?
    public var groupId : NSNumber = 0

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        ALMessageService.syncMessages()

        registerForNotification()

        applozicClient = ApplozicClient.init(applicationKey: "applozic-sample-app", with: self)

        if (launchOptions != nil)
        {
            let dictionary = launchOptions?[UIApplicationLaunchOptionsKey.remoteNotification] as? NSDictionary

            if (dictionary != nil)
            {


                let pushnotification = ALPushNotificationService()

                if(pushnotification.isApplozicNotification(launchOptions)){

                    applozicClient.notificationArrived(to: application, with: launchOptions)
                    self.openChatView(dic: dictionary as! [AnyHashable : Any])

                }else{
                    //handle your notification
                }

            }
        }


        // Override point for customization after application launch.
        return true
    }

    func registerForNotification() {
        if #available(iOS 10.0, *) {

            UNUserNotificationCenter.current().requestAuthorization(options:[.badge, .alert, .sound]) { (granted, error) in

                if granted {
                    DispatchQueue.main.async {
                        UIApplication.shared.registerForRemoteNotifications()
                    }
                }
            }
            UNUserNotificationCenter.current().delegate = self
        } else {
            // Fallback on earlier versions
            let settings = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            UIApplication.shared.registerUserNotificationSettings(settings)
            UIApplication.shared.registerForRemoteNotifications()

        }
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        applozicClient.unsubscribeToConversation()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        ALMessageService.syncMessages()

        applozicClient.subscribeToConversation()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        ALDBHandler.sharedInstance().saveContext()

    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data)
    {

        NSLog("Device token data :: \(deviceToken.description)")

        var deviceTokenString: String = ""
        for i in 0..<deviceToken.count
        {
            deviceTokenString += String(format: "%02.2hhx", deviceToken[i] as CVarArg)
        }

        NSLog("Device token :: \(deviceTokenString)")

        if (ALUserDefaultsHandler.getApnDeviceToken() != deviceTokenString)
        {
            let alRegisterUserClientService: ALRegisterUserClientService = ALRegisterUserClientService()
            alRegisterUserClientService.updateApnDeviceToken(withCompletion: deviceTokenString, withCompletion: {
                (response, error) in
                if error != nil {

                }

            })
        }
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any])
    {
        print("Received notification :: \(userInfo.description)")

        applozicClient.notificationArrived(to: application, with: userInfo)
    }


    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler
        completionHandler: @escaping (UIBackgroundFetchResult) -> Void)
    {
        print("Received notification With Completion :: \(userInfo.description)")

        applozicClient.notificationArrived(to: application, with: userInfo)
        completionHandler(UIBackgroundFetchResult.newData)
    }



    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {



        let applozicPushNotification = ALPushNotificationService()

        if(!applozicPushNotification.isApplozicNotification(notification.request.content.userInfo)){
            completionHandler([.alert,.sound])
        }

        // Play sound and show alert to the user
    }

    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {

        // Determine the user action

        switch response.actionIdentifier {
        case UNNotificationDismissActionIdentifier:
            print("Dismiss Action")
        case UNNotificationDefaultActionIdentifier:
            print("Default")
        case "Snooze":
            print("Snooze")
        case "Delete":
            print("Delete")
        default:
            print("Unknown action")
        }

        let pushNotification = ALPushNotificationService()

        if(pushNotification.isApplozicNotification(response.notification.request.content.userInfo)){

            self.openChatView(dic: response.notification.request.content.userInfo)
        }else{

            let dic =  response.notification.request.content.userInfo
            let viewController = ConversationViewController()

            let userId =  dic["userId"] as? String
            if(userId != nil ){
                viewController.userId = userId
            }else{
                let groupId =  dic["groupId"] as? NSNumber
                viewController.groupId = groupId
            }

            let pushkit = ALPushAssist()

            pushkit.topViewController.navigationController?.pushViewController(viewController, animated: false)

        }

        applozicClient.notificationArrived(to: UIApplication.shared, with: response.notification.request.content.userInfo)

        completionHandler()
    }


    func sendLocalPush(message: ALMessage) {

        if #available(iOS 10.0, *) {
            let center = UNUserNotificationCenter.current()

            let contactService = ALContactDBService()
            let channelService  = ALChannelService()
            UNUserNotificationCenter.current().delegate = self

            var title = String()

            if(message.groupId != nil && message.groupId != 0){
                let  alChannel =  channelService.getChannelByKey(message.groupId)

                guard let channel = alChannel,!channel.isNotificationMuted() else {
                    return
                }

                title =  channel.name
            }else{
                let  alContact = contactService.loadContact(byKey: "userId", value: message.to)

                guard let contact = alContact else {
                    return
                }
                title = contact.displayName != nil ? contact.displayName:contact.userId
            }

            let content = UNMutableNotificationContent()
            content.title = title
            content.body = message.message
            content.sound = UNNotificationSound.default()

            var dict: [AnyHashable: Any]
            if(message.groupId != nil && message.groupId != 0){
                dict = ["groupId":message.groupId ]
            }else{
                dict = ["userId":message.to ]
            }
            content.userInfo = dict

            let identifier = "ApplozicLocalNotification"


            let request = UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: nil
            )

            center.add(request, withCompletionHandler: { (error) in

                if error != nil {
                    // Something went wrong
                }

            })


        } else {
            // Fallback on earlier versions
        }

    }

    func onMessageReceived(_ alMessage: ALMessage!) {

        //    NotificationCenter.default.post(name: Notification.Name(rawValue: "New_Message_Notification"), object: alMessage)

    }

    func onMessageSent(_ alMessage: ALMessage!) {

        //   NotificationCenter.default.post(name: Notification.Name(rawValue: "New_Message_Notification"), object: alMessage)

    }

    func onUserDetailsUpdate(_ userDetail: ALUserDetail!) {

        //  NotificationCenter.default.post(name: Notification.Name(rawValue: "User_info_updated"), object: userDetail)

    }

    func onMessageDelivered(_ message: ALMessage!) {

        // NotificationCenter.default.post(name: Notification.Name(rawValue: "Message_Status_Update"), object: message)


    }

    func onMessageDeleted(_ messageKey: String!) {
        //  NotificationCenter.default.post(name: Notification.Name(rawValue: "Message_Delete_Update"), object: messageKey)

    }

    func onMessageDeliveredAndRead(_ message: ALMessage!, withUserId userId: String!) {

    }

    func onConversationDelete(_ userId: String!, withGroupId groupId: NSNumber!) {


    }

    func conversationRead(byCurrentUser userId: String!, withGroupId groupId: NSNumber!) {
        //  NotificationCenter.default.post(name: Notification.Name(rawValue: "Unread_Conversation_Read"), object: infoDict)

    }

    func onUpdateTypingStatus(_ userId: String!, status: Bool) {
        //    NotificationCenter.default.post(name: Notification.Name(rawValue: "GenericRichListButtonSelected"), object: infoDict)

    }

    func onUpdateLastSeen(atStatus alUserDetail: ALUserDetail!) {
        //  NotificationCenter.default.post(name: Notification.Name(rawValue: "Online_Status_Update"), object: alUserDetail)

    }

    func onUserBlockedOrUnBlocked(_ userId: String!, andBlockFlag flag: Bool) {
        //    NotificationCenter.default.post(name: Notification.Name(rawValue: "GenericRichListButtonSelected"), object: infoDict)

    }

    func onChannelUpdated(_ channel: ALChannel!) {
        // NotificationCenter.default.post(name: Notification.Name(rawValue: "Channel_Info_Sync"), object: channel)

    }

    func onAllMessagesRead(_ userId: String!) {
        // NotificationCenter.default.post(name: Notification.Name(rawValue: "All_Messages_Read"), object: userId)

    }

    func onMqttConnectionClosed() {
        applozicClient.subscribeToConversation()

    }

    func onMqttConnected() {

    }


    func openChatView(dic: [AnyHashable : Any] )  {

        let type = dic["AL_KEY"] as? String
        let alValueJson = dic["AL_VALUE"] as? String

        let data: Data? = alValueJson?.data(using: String.Encoding(rawValue: String.Encoding.utf8.rawValue))

        var theMessageDict: [AnyHashable : Any]? = nil
        if let aData = data {
            theMessageDict = try! JSONSerialization.jsonObject(with: aData, options: []) as? [AnyHashable : Any]
        }

        let notificationMsg = theMessageDict?["message"] as? String

        if(type != nil){

            let myArray = notificationMsg!.components(separatedBy: CharacterSet(charactersIn: ":"))

            var channelKey : NSNumber = 0

            if myArray.count > 2 {
                if let key = Int( myArray[1]) {
                    channelKey = NSNumber(value:key)
                }
            } else {
                channelKey = 0
            }

            let viewController = ConversationViewController()

            if(channelKey != 0) {
                viewController.groupId = channelKey;
            } else {
                viewController.userId = notificationMsg;
            }

            let pushkit = ALPushAssist()

            pushkit.topViewController.navigationController?.pushViewController(viewController, animated: false)
        }
    }



}
