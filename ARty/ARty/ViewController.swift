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
    @IBOutlet weak var switchButton: UIButton!
    @IBOutlet weak var heightTextField: UITextField!
    @IBOutlet weak var widthTextField: UITextField!
    @IBOutlet weak var ssImageView: UIImageView!
    var omniLight: SCNLight!
    
    // Graffiti
    var fontSize: Float = 0.005;
    
    @IBOutlet weak var fontSizeTextField: UITextField!
    var startPos = SIMD3<Float>(0, 0, 0)
    var currentPos = SIMD3<Float>(0, 0, 0)
    var depth: Float = Float()
    var lineColor: UIColor = UIColor.white
    
    var polygonVertices: [SCNVector3] = []
    var indices: [Int32] = []
    var centerVerticesCount: Int32 = 0
    
    var pointTouching: CGPoint = .zero
    var isDrawing: Bool = false
    
    var drawingNode: SCNNode?
    
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
        
        
        // Graffiti
        fontSizeTextField.delegate = self
        fontSize = Float(self.fontSizeTextField.text ?? "0.005")!
        
        // デリゲートを設定
        sceneView.delegate = self
        heightTextField.delegate = self
        widthTextField.delegate = self
        
        // シーンの追加
        sceneView.scene = SCNScene()
        
        // 特徴点の表示
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        
        //ライトの追加
        sceneView.autoenablesDefaultLighting = true
        
        // switchButtonの初期設定
        switchButton.isSelected = true
        
        // コンフィギュレーションの設定
        let configuration = ARWorldTrackingConfiguration()
            configuration.planeDetection = [.horizontal, .vertical]
            configuration.environmentTexturing = .automatic
        
        // セッションを開始する
        sceneView.session.run(configuration)
    }
    
    // MARK: Method
    func getScreenShot(windowFrame: CGRect) -> UIImage {
        let image = sceneView.snapshot()
        
        return image
    }
    
    // Graffiti
    private func begin(){
        drawingNode = SCNNode()
        sceneView.scene.rootNode.addChildNode(drawingNode!)
    }
    
    private func addPointAndCreateVertices(){
        //カメラノード
        guard let camera: SCNNode = sceneView.pointOfView else{
            return
        }
        
        let pointScreen: SCNVector3 = SCNVector3Make(Float(pointTouching.x),Float(pointTouching.y), 0.997)
        let pointWorld: SCNVector3 = sceneView.unprojectPoint(pointScreen)
        let pointCamera: SCNVector3 = camera.convertPosition(pointWorld, from: nil)
        
        let x: Float = pointCamera.x
        let y: Float = pointCamera.y
        let z: Float = -0.2
        
        let vertice0InCamera: SCNVector3 = SCNVector3Make(x - fontSize, y + fontSize, z)
        let vertice1InCamera: SCNVector3 = SCNVector3Make(x + fontSize, y + fontSize, z)
        let vertice2InCamera: SCNVector3 = SCNVector3Make(x - fontSize, y - fontSize, z)
        let vertice3InCamera: SCNVector3 = SCNVector3Make(x + fontSize, y - fontSize, z)
        
        let vertice0: SCNVector3 = camera.convertPosition(vertice0InCamera, to: nil)
        let vertice1: SCNVector3 = camera.convertPosition(vertice1InCamera, to: nil)
        let vertice2: SCNVector3 = camera.convertPosition(vertice2InCamera, to: nil)
        let vertice3: SCNVector3 = camera.convertPosition(vertice3InCamera, to: nil)
        
        polygonVertices += [vertice0, vertice1, vertice2, vertice3]
        centerVerticesCount += 2
        
        guard centerVerticesCount > 2 else {
            return
        }
        
        let leftn: Int32 = centerVerticesCount - 4
        let leftm: Int32 = 2 * leftn
        let nextLeftIndices: [Int32] = [
            leftm    , leftm + 1, leftm + 2,//前面
            leftm    , leftm + 1, leftm + 4,//上面左
            leftm    , leftm + 2, leftm + 4,//左側面上
            //leftm + 1, leftm + 2, leftm + 5,//内面上
            leftm + 1, leftm + 4, leftm + 5,//上面右
            //leftm + 1, leftm + 2, leftm + 6,//
            leftm + 2, leftm + 4, leftm + 6,//
            leftm + 4, leftm + 5, leftm + 6 //
        ]
        indices += nextLeftIndices
        
        let rightn: Int32 = centerVerticesCount - 4
        let rightm: Int32 = 2 * rightn + 1
        let nextRightIndices: [Int32] = [
            rightm    , rightm + 1, rightm + 2,
            //rightm    , rightm + 1, rightm + 4,
            rightm    , rightm + 2, rightm + 4,
            rightm + 1, rightm + 2, rightm + 5,
            //rightm + 1, rightm + 4, rightm + 5,
            rightm + 1, rightm + 2, rightm + 6,
            rightm + 2, rightm + 4, rightm + 6,
            rightm + 4, rightm + 5, rightm + 6
        ]
        indices += nextRightIndices
        
        updateGeometry()
    }
    
    private func reset() {
        centerVerticesCount = 0
        polygonVertices.removeAll()
        indices.removeAll()
        drawingNode = nil
    }
    
    private func updateGeometry(){
        let source = SCNGeometrySource(vertices: polygonVertices)
        let element = SCNGeometryElement(indices: indices, primitiveType: .triangles)
        drawingNode?.geometry = SCNGeometry(sources:[source], elements: [element])
    
        drawingNode?.geometry?.firstMaterial?.diffuse.contents = #colorLiteral(red: 0.4627581835, green: 0.9555212855, blue: 0.5625822544, alpha: 1)
        drawingNode?.geometry?.firstMaterial?.isDoubleSided = true
    }
    
    // MARK: Action
    
    // switchボタンを押した時
    @IBAction func switchButtonAction(_ sender: Any) {
        switchButton.isSelected = !switchButton.isSelected
        
    }
    
    // 保存するボタンを押したとき
    @IBAction func saveButtonPressed(_ sender: Any){
        // 現在のARWorldMapを取得
        sceneView.session.getCurrentWorldMap{worldMap, error in
            guard let map = worldMap else{return}
            
            // シリアライズ
            guard let data = try? NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: true)else{return}
            
            // ローカルに保存
            guard((try? data.write(to: self.worldMapURL)) != nil)else{return}
            
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
    
    // 平面、垂直面が検出されたとき
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor){
        guard !(anchor is ARPlaneAnchor) else{return}
        
        // stampImageViewからスタンプを取得
        DispatchQueue.global().async{
            DispatchQueue.main.async{
                if anchor.name == "stamp"{
                    
                    // ノードを作成
                    let boxNode = SCNNode()
                    
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
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval){
        
        //print("こっち？")
        
        if isDrawing {
            print("落書き処理中")
            addPointAndCreateVertices()
        }
    }
    
    // MARK: Touch Method
    
    // 画面をタップしたとき
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if switchButton.isSelected {
            
            print("画面タップ：スタンプ")
            
            // スタンプの処理
            // タップした座標を取り出す
            guard let touch = touches.first else{return}
            
            // スクリーン座標に変換する
            let touchPos = touch.location(in: sceneView)
            
            // タップされた位置のARアンカーを探す
            let hitTest = sceneView.hitTest(touchPos, types: .existingPlaneUsingExtent)
            if !hitTest.isEmpty{
                // タップした箇所が取得できていればアンカーを追加
                let anchor = ARAnchor(name: "stamp", transform: hitTest.first!.worldTransform)
                print(anchor.name)
                sceneView.session.add(anchor: anchor)
            }
        } else {
            print("画面タップ：落書き")
            // 落書きの処理
            guard let location = touches.first?.location(in: nil) else{
                return
            }
            pointTouching = location
            
            begin()
            isDrawing = true
        }
    }
    
    // タッチされた状態で指で動かすと呼ばれる
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if switchButton.isSelected {
            
        } else {
            guard let location = touches.first?.location(in: nil) else{
                return
            }
            pointTouching = location
        }
        
        
    }
    
    // 指を離したら呼ばれる
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if switchButton.isSelected {
            print("画面リリース：スタンプ")
        } else {
            print("画面リリース：落書き")
            isDrawing = false
            reset()
        }
    }
    
    // MARK: UITextField

    // テキストフィールドでリターンが押されたときに呼ばれる
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // キーボードを閉じる
        textField.resignFirstResponder()
        
        if textField == fontSizeTextField {
            fontSize = Float(self.fontSizeTextField.text ?? "0.005")!
            
            if fontSize < 0.001 {
                fontSize = 0.001
                fontSizeTextField.text = "0.001"
            }
            
            if fontSize > 0.01 {
                fontSize = 0.01
                fontSizeTextField.text = "0.01"
            }
        }
        
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
          fatalError()
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
