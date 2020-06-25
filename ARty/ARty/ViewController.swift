//
//  ViewController.swift
//  ARty
//
//  Created by 藤崎伊織 on 2020/06/04.
//

import UIKit
import SceneKit
import ARKit
import NCMB
import ReplayKit

class ViewController: UIViewController, ARSCNViewDelegate, UITextFieldDelegate, RPPreviewViewControllerDelegate {

    // MARK: Properties
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var imageSelectButton: UIButton!
    @IBOutlet weak var heightTextField: UITextField!
    @IBOutlet weak var widthTextField: UITextField!
    @IBOutlet weak var ssImageView: UIImageView!
    var omniLight: SCNLight!
    
    
    var worldMapURL: URL = {
        do{
            return try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("worldMapURL")
        }catch{
            fatalError("No such file")
        }
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // デリゲートを設定
        sceneView.delegate = self
        heightTextField.delegate = self
        widthTextField.delegate = self
        
        // シーンの追加
        sceneView.scene = SCNScene()
        
        // 特徴点の表示
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        
        // Omniライトの追加
        let omniLightNode = SCNNode()
        omniLightNode.light = SCNLight()
        omniLightNode.light!.type = .omni
        omniLightNode.position = SCNVector3(x: 0, y: 10, z: 10)
        omniLightNode.light!.color = UIColor.white
        self.sceneView.scene.rootNode.addChildNode(omniLightNode)
        
        omniLight = omniLightNode.light
        
        // コンフィギュレーションの設定
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        
        // セッションを開始する
        sceneView.session.run(configuration)
    }
    
    // MARK: Method
    func startRecoding() {
        // すでに録画中なら何もしない
        guard !RPScreenRecorder.shared().isRecording else { return }
        
        // 録画開始
        RPScreenRecorder.shared().startRecording(handler: { error in
            if error == nil {
                print("nilだよ")
            } else {
                print("errorあるよ")
            }
        })
        print("録画開始するよ")
    }
    
    func getScreenShot(windowFrame: CGRect) -> UIImage {
        let image = sceneView.snapshot()
        
        return image
    }
    
    func endRecording() {
        // 録画中ではなければ終了する
        guard RPScreenRecorder.shared().isRecording else { return }
        
        // 録画終了
        RPScreenRecorder.shared().stopRecording(handler: { previewViewController, error in
            guard let previewViewController = previewViewController else { return }
            previewViewController.previewControllerDelegate = self
            
            print("録画終了するよ")
            
            // プレビューの表示
            self.present(previewViewController, animated: true, completion: nil)
        })
    }
    
    // MARK: Action
    // 保存するボタンを押したとき
    @IBAction func saveButtonPressed(_ sender: Any){
        // 現在のARWorldMapを取得
        sceneView.session.getCurrentWorldMap{worldMap, error in
            guard let map = worldMap else{return}
            
            // シリアライズ
            guard let data = try? NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: true)else{return}
            
            // ローカルに保存
            guard((try? data.write(to: self.worldMapURL)) != nil)else{return}
            
            // TODO: ここにファイルストアに保存する処理を書く
            
            // 日付を取得
            let date = Date()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy.MM.dd.HH.mm.ss"
            print("date:\(dateFormatter.string(from: date))")
            
            // ファイル名を設定
            let fileName = "WorldMap.\(dateFormatter.string(from: date))"
            print("fileName:\(fileName)")
            
            // ファイルストアに保存
            let file = NCMBFile(fileName: fileName)
            
            file.saveInBackground(data: data, callback: {result in
                switch result {
                case .success:
                    print("保存に成功")
                case let .failure(error):
                    print("保存に失敗:\(error)")
                }
            })
            
            
        }
    }
    
    @IBAction func ssButtonAction(_ sender: Any) {
        let image = getScreenShot(windowFrame: self.view.bounds)
        ssImageView.image = image
    }
    
    // 読み込むボタンを押したとき
    @IBAction func loadButtonPressed(_ sender: Any){
        //保存したARWorldMapの読み出し
        var data: Data? = nil
        do{
            try data = Data(contentsOf: self.worldMapURL)
        }catch{return}
        //デシリアライズ
        guard let worldMap = try? NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: data!)else{return}
        
        //WorldMapの再設定
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.initialWorldMap = worldMap
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    @IBAction func imageSelectButtonAction(_ sender: Any) {
        // タップされたらイメージビューを開く。
        
        let imagePickerController = UIImagePickerController()
        
        // フォトライブラリから読み込み
        imagePickerController.sourceType = .photoLibrary
        
        // モーダルを開く
        imagePickerController.delegate = self
        present(imagePickerController, animated: true, completion: nil)
    }
    
    @IBAction func recodeStartButtonAction(_ sender: Any) {
        startRecoding()
    }
    
    
    @IBAction func recodeEndButtonAction(_ sender: Any) {
        endRecording()
    }
    
    // 画面をタップしたとき
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // タップした座標を取り出す
        guard let touch = touches.first else{return}
        
        // スクリーン座標に変換する
        let touchPos = touch.location(in: sceneView)
        
        // タップされた位置のARアンカーを探す
        let hitTest = sceneView.hitTest(touchPos, types: .existingPlaneUsingExtent)
        if !hitTest.isEmpty{
            // タップした箇所が取得できていればアンカーを追加
            let anchor = ARAnchor(transform: hitTest.first!.worldTransform)
            sceneView.session.add(anchor: anchor)
        }
    }
    
    // 平面、垂直面が検出されたとき
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor){
        guard !(anchor is ARPlaneAnchor) else{return}
        
        // ノードを作成
        let boxNode = SCNNode()
        
        // stampImageViewからスタンプを取得
        DispatchQueue.global().async{
            DispatchQueue.main.async{
                let stamp = self.imageSelectButton.currentImage
                
                // スタンプのサイズを設定
                let intWidth = Int(self.widthTextField.text ?? "300")
                let floatWidth: CGFloat = CGFloat(intWidth!)
                let intHeight = Int(self.heightTextField.text ?? "300")
                let floatHeight: CGFloat = CGFloat(intHeight!)
                
                print("画像 width = \(String(describing: floatWidth)), height = \(String(describing: floatHeight))")
                
                // ボックスを作成
                let box = SCNBox(width: floatWidth / 10000, height: 0.0001, length: floatHeight / 10000, chamferRadius: 0)
                
                // スタンプテクスチャのマテリアルを生成
                let stampTexture = SCNMaterial()
                stampTexture.diffuse.contents = stamp
                
                // テクスチャを貼らない面用に色だけ設定したマテリアルを生成
                let blank = SCNMaterial()
                blank.diffuse.contents = UIColor.clear
                
                // ボックスにマテリアルを貼り付け
                box.materials = [blank, blank, blank, blank, stampTexture, blank]
                
                // ジオメトリを設定
                boxNode.geometry = box
                boxNode.position.y += 0.01
                
                // 検出面の子要素にする
                node.addChildNode(boxNode)
            }
        }
    }
    
    // MARK: UITextField

    // テキストフィールドでリターンが押されたときに呼ばれる
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // キーボードを閉じる
        textField.resignFirstResponder()
        
        return true
    }
    
    
}

// MARK: UIImagePickerControllerDelegate+UINavigationControllerDelegate
extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        // モーダルのViewControllerを閉じる
        dismiss(animated: true, completion: nil)
    }
    
    // 画像を選択した後の処理
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let selectedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else {
          fatalError("Expected a dictionary containing an image, but was provided the following: \(info)")
        }
        
        // 選択した画像を選択画像ビューに反映
        imageSelectButton.setImage(selectedImage, for: .normal)
        
        // スタンプ画像のサイズを出力
        print("画像の高さ:\(selectedImage.size.height)")
        print("画像の幅:\(selectedImage.size.width)")
        
        // Pickerを閉じる
        dismiss(animated: true, completion: nil)
    }
}
