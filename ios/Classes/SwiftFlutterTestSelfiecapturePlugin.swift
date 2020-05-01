import Flutter
import UIKit
import GoogleMobileVision

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
        else if (call.method == "ocrFromDocImage"){
            var tmpImagePath = ""
            var tmpFaceImagePath = ""
            var tmpXoffSet = ""
            var tmpYoffSet = ""
            guard let args = call.arguments else {
                return
            }
            if let myArgs = args as? [String: Any],
                let tmp_ImagePath = myArgs["imagePath"] as? String,
                let tmp_FaceImagePath = myArgs["destFaceImagePath"] as? String,
                let tmp_XoffSet = myArgs["xOffset"] as? String,
                let tmp_YoffSet = myArgs["yOffset"] as? String{
               
                tmpImagePath = tmp_ImagePath
                tmpFaceImagePath = tmp_FaceImagePath
                tmpXoffSet = tmp_XoffSet
                tmpYoffSet = tmp_YoffSet
            }

            self.detectTextAndFace(strImagePath: tmpImagePath, destFaceImagePath: tmpFaceImagePath, xOffset: Int(tmpXoffSet)!, yOffset: Int(tmpYoffSet)!)
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
    
    
    public func detectTextAndFace(strImagePath: String, destFaceImagePath: String, xOffset: Int, yOffset: Int){
        
        var textDetector = GMVDetector()
        var faceDetector = GMVDetector()
        
        textDetector = GMVDetector.init(ofType: GMVDetectorTypeText, options: nil)!
        var image = UIImage()
        
        var url = URL(string: strImagePath)

        if url == nil{
            url = URL.init(fileURLWithPath: strImagePath)
        }

        DispatchQueue.global().async {
            let data = try? Data(contentsOf: url!) //make sure your image in this url does exist, otherwise unwrap in a if let check / try-catch
            DispatchQueue.main.async {
                image = UIImage(data: data!)!
                let arr : [GMVTextBlockFeature] = textDetector.features(in: image, options: nil)! as! [GMVTextBlockFeature]
                
                for i in 0..<arr.count{
                    print(arr[i].value!)
                }
                
                faceDetector = GMVDetector.init(ofType: GMVDetectorTypeFace, options: nil)!
                let arrFace : [GMVFaceFeature] = faceDetector.features(in: image, options: nil)! as! [GMVFaceFeature]
                
                for i in 0..<arrFace.count{
                    // Face
                    let rect = arrFace[i].bounds
                    print(rect)
                    let xRectImage = Int(arrFace[i].bounds.origin.x) - xOffset
                    let yRectImage = Int(arrFace[i].bounds.origin.y) - xOffset
                    let widthRectImage = Int(arrFace[i].bounds.size.width) + yOffset
                    let heightRectImage = Int(arrFace[i].bounds.size.height) - yOffset
                    let img_rect = CGRect.init(x: xRectImage, y: yRectImage, width: widthRectImage, height: heightRectImage)
                    let img = self.cropImage(image: image, toRect: img_rect)
                    self.saveImage(image: img, tmp_path: destFaceImagePath, items: arr)
                }
            }
        }
    }
    
    func cropImage(image:UIImage, toRect rect:CGRect) -> UIImage{
        let imageRef:CGImage = image.cgImage!.cropping(to: rect)!
        let croppedImage:UIImage = UIImage(cgImage:imageRef)
        return croppedImage
    }
    
    func saveImage(image: UIImage, tmp_path: String, items : [GMVTextBlockFeature]) -> [String: AnyObject] {
        self.clearTempFolder()
        var resultOfOCR = [String: AnyObject]()
        var path = tmp_path
        var rotatedimage = image//.rotate(radians: .pi/2)
        
        guard let data = UIImageJPEGRepresentation(rotatedimage, 1) ?? UIImagePNGRepresentation(rotatedimage) else {
            return (resultOfOCR)
        }

        if path == ""{
            guard let directory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else {
                return (resultOfOCR)
            }
            path = directory
        }
        
        do {
            if path == ""{
                path = "\(path)/faceImage.jpeg"
            }
            try data.write(to: URL.init(fileURLWithPath: path))
            print("")
            print(path)
            resultOfOCR["ExtractedData"] = items as AnyObject
            resultOfOCR["FaceImagePath"] = path as AnyObject
            return (resultOfOCR)
        } catch {
            print(error.localizedDescription)
            return (resultOfOCR)
        }
    }
    func clearTempFolder() {
        let fileManager = FileManager.default
        let tempFolderPath = NSTemporaryDirectory()
        do {
            let filePaths = try fileManager.contentsOfDirectory(atPath: tempFolderPath)
            for filePath in filePaths {
                try fileManager.removeItem(atPath: tempFolderPath + filePath)
            }
        } catch {
            print("Could not clear temp folder: \(error)")
        }
    }

}
