import Flutter
import UIKit

let navBar = UINavigationController.init()
var receivedPath = String()

var resultDismiss : FlutterResult!

public class SwiftFlutterTestSelfiecapturePlugin: NSObject, FlutterPlugin, DismissProtocol {

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "selfie_ocr_mtpl", binaryMessenger: registrar.messenger())
        let instance = SwiftFlutterTestSelfiecapturePlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if (call.method == "getPlatformVersion") {
            result("iOS " + UIDevice.current.systemVersion)
        }
        else if call.method == "detectLiveliness" {
            resultDismiss = result
            
            var msgselfieCapture = ""
            var msgBlinkEye = ""
            guard let args = call.arguments else {
                return
            }
            if let myArgs = args as? [String: Any],
                let captureText = myArgs["msgselfieCapture"] as? String,
                let blinkText = myArgs["msgBlinkEye"] as? String{
                msgselfieCapture = captureText
                msgBlinkEye = blinkText
            }
            self.detectLiveness(captureMessage: msgselfieCapture, blinkMessage: msgBlinkEye)
        }
    }
    
    public func detectLiveness(captureMessage: String, blinkMessage: String){
        if let viewController = UIApplication.shared.keyWindow?.rootViewController as? FlutterViewController{
            let storyboardName = "MainLive"
            let storyboardBundle = Bundle.init(for: type(of: self))
            let storyboard = UIStoryboard(name: storyboardName, bundle: storyboardBundle)
            if let vc = storyboard.instantiateViewController(withIdentifier: "TestViewController") as? TestViewController {
                vc.captureMessageText = captureMessage
                vc.blinkMessageText = blinkMessage
                viewController.present(vc, animated: true, completion: nil)
                vc.dismissDelegate = self
            }
        }
    }
    func sendData(filePath: String) {
        receivedPath = filePath
        if resultDismiss != nil{
            resultDismiss(filePath)
        }else{
            resultDismiss("")
        }
    }
}
