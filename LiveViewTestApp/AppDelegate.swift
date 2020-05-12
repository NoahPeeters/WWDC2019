//
//  See LICENSE folder for this template’s licensing information.
//
//  Abstract:
//  Implements the application delegate for LiveViewTestApp with appropriate configuration points.
//

import UIKit
import Book_Sources

@UIApplicationMain
class AppDelegate: NSObject, UIApplicationDelegate {
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
            window = UIWindow(frame: UIScreen.main.bounds)

            let vc = LiveViewController()
            vc.updateSettings(Settings.mandelbrot())

            window?.rootViewController = vc
            window?.makeKeyAndVisible()
            return true
        }}
