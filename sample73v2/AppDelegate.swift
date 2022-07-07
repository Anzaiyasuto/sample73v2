//
//  AppDelegate.swift
//  sample73v2
//
//  Created by AnzaiYasuto al18011 on 2022/07/03.
//

import UIKit
import GoogleMaps
import GooglePlaces
import UserNotifications
import NotificationCenter
import CoreLocation


@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        GMSServices.provideAPIKey("AIzaSyAHqB7OlRuY2tCOsZ9o8SvJBCFD1sr1hL0")
        // Override point for customization after application launch.
        GMSPlacesClient.provideAPIKey("AIzaSyAHqB7OlRuY2tCOsZ9o8SvJBCFD1sr1hL0")
        
        //77
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().requestAuthorization(options: [.badge, .alert, .sound]) {(granted, error) in if granted{print("通過許可")}
            
        }
        
        //UNTimeIntervalNotificationTrigger
        /*
        let content = UNMutableNotificationContent()
        content.title = "TimeInterval";
        content.body = "swift-saralymanからの通知だよ";
        content.sound = UNNotificationSound.default
        let trigger = UNTimeIntervalNotificationTrigger.init(timeInterval: 5, repeats: false)//５秒後
        let request = UNNotificationRequest.init(identifier: "TestNotification", content: content, trigger: trigger)
        let center = UNUserNotificationCenter.current()
        center.add(request)
        center.delegate = self
        
        return true
        */
        //UNLocationNotificationTrigger
        
        let content = UNMutableNotificationContent()
        content.title = "apple tourimasu"
        content.body = "sitei hanni wo tuuka"
        content.sound = UNNotificationSound.default
        let coordinate = CLLocationCoordinate2DMake(37.33438, -122.04150)
        let region = CLCircularRegion(center: coordinate, radius: 100.0, identifier: "test")
        region.notifyOnEntry = true
        region.notifyOnExit = true
        let trigger1 = UNLocationNotificationTrigger(region: region, repeats: true)
        let request = UNNotificationRequest.init(identifier: "TestNotification", content: content, trigger: trigger1)
        let center = UNUserNotificationCenter.current()
        center.add(request)
        center.delegate = self
        
        return true
        
    }
    
    
    //77追記
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert,.sound])
    }
    
    //ポップアップ押した後に呼ばれる関数(↑の関数が呼ばれた後に呼ばれる)
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        
        //Alertダイアログでテスト表示
        let contentBody = response.notification.request.content.body
        let alert:UIAlertController = UIAlertController(title: "受け取りました", message: contentBody, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: {
            (action:UIAlertAction!) -> Void in
            print("Alert押されました")
        }))
        self.window?.rootViewController?.present(alert, animated: true, completion: nil)
        
        completionHandler()
    }
    //ここまでです
    

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

