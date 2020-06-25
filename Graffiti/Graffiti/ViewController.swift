//
//  ViewController.swift
//  Graffiti
//
//  Created by 藤崎伊織 on 2020/06/18.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, UITextFieldDelegate/*, ARSCNViewDelegate */{

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var fontSizeTextField: UITextField!
    
    var fontSize: Float = 0.005;
    
    let defaultConfiguration: ARWorldTrackingConfiguration = {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        configuration.environmentTexturing = .automatic
        return configuration
    }()
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // デリゲートを設定
        sceneView.delegate = self
        fontSizeTextField.delegate = self
        
        fontSize = Float(self.fontSizeTextField.text ?? "0.005")!
        
        // シーンを作成
        //sceneView.scene = SCNScene()
        
        //特徴点を表示する
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        
        //ライトの追加
        sceneView.autoenablesDefaultLighting = true
        
        sceneView.showsStatistics = true
        
        // セッションを開始する
        //let configuration = ARWorldTrackingConfiguration()
        //configuration.frameSemantics = .personSegmentationWithDepth
        //sceneView.session.run(configuration)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        sceneView.session.run(defaultConfiguration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        sceneView.session.pause()
    }
    
    // テキストフィールドでリターンが押されたときに呼ばれる
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // キーボードを閉じる
        textField.resignFirstResponder()
        
        fontSize = Float(self.fontSizeTextField.text ?? "0.005")!
        
        if fontSize < 0.001 {
            fontSize = 0.001
            fontSizeTextField.text = "0.001"
        }
        
        if fontSize > 0.01 {
            fontSize = 0.01
            fontSizeTextField.text = "0.01"
        }
        
        return true
    }
    
    
    // MARK: Touch Method
    
    // タッチされると呼ばれる
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        /*
        // タップした座標を取り出す
        guard let touchPos = touches.first?.location(in: sceneView) else { return }
        
        // 特徴点に当たっているか
        let hitTestResult = sceneView.hitTest(touchPos, types: .featurePoint)
        
        if !hitTestResult.isEmpty {
            if let hitResult = hitTestResult.first {
                
                // ワールド座標を代入
                startPos = SIMD3<Float>(hitResult.worldTransform.columns.3.x, hitResult.worldTransform.columns.3.y, hitResult.worldTransform.columns.3.z)
                
                
                print("startPos: \(startPos)")
                
                // 奥行きを保持
                depth = hitResult.worldTransform.columns.3.z
                
                // 球のNodeを作る
                let ball = SCNSphere(radius: 0.001)
                ball.firstMaterial?.diffuse.contents = lineColor
                let node = SCNNode(geometry: ball)
                node.position = SCNVector3(startPos)
                sceneView.scene.rootNode.addChildNode(node)
                
            }
        }
        */
        guard let location = touches.first?.location(in: nil) else{
            return
        }
        pointTouching = location
        
        begin()
        isDrawing = true
    }
    
    // タッチされた状態で指で動かすと呼ばれる
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        /*
        // タップされている座標を取り出す
        guard let touchPos = touches.first?.location(in: sceneView) else { return }
        
        // 特徴点に当たっているか
        let hitTestResult = sceneView.hitTest(touchPos, types: .featurePoint)
        
        if !hitTestResult.isEmpty {
            if let hitResult = hitTestResult.first {
                // startPosを再設定
                startPos = currentPos
                
                // ワールド座標を返す
                currentPos = SIMD3<Float>(hitResult.worldTransform.columns.3.x, hitResult.worldTransform.columns.3.y, depth)
                //currentPos = SIMD3<Float>(hitResult.worldTransform.columns.3.x, hitResult.worldTransform.columns.3.y, hitResult.worldTransform.columns.3.z)
                
                // TODO: currentPos出力
                // print("currentPos: \(currentPos)")
                
                // 直線を描画
                drawLine(from: SCNVector3(startPos), to: SCNVector3(currentPos))
            }
        }
        */
        guard let location = touches.first?.location(in: nil) else{
            return
        }
        pointTouching = location
        
    }
    
    // 指を離したら呼ばれる
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        isDrawing = false
        reset()
    }
    
    // MARK: Method
    
    // 線を描画
    func drawLine(from: SCNVector3, to: SCNVector3) {
        
        
        
        /*
        // 球のNodeを作る
        let ball = SCNSphere(radius: 0.005)
        ball.firstMaterial?.diffuse.contents = UIColor.white
        let node = SCNNode(geometry: ball)
        node.position = from
        sceneView.scene.rootNode.addChildNode(node)*/
        
        
        /*// 直線のGeometryを作成
        let source = SCNGeometrySource(vertices: [from, to])
        let element = SCNGeometryElement(data: Data.init(bytes: [0, 1]), primitiveType: .line, primitiveCount: 1, bytesPerIndex: 1)
        let geometry = SCNGeometry(sources: [source], elements: [element])
        
        // 直線ノードの作成
        let node = SCNNode()
        node.geometry = geometry
        node.geometry?.materials.first?.diffuse.contents = UIColor.white
        sceneView.scene.rootNode.addChildNode(node)*/
    }
    
    /*
    // 毎フレーム呼ばれる
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
    }
    */
}

//拡張
extension ViewController{
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
        //polygonVertices += [vertice1, vertice2, vertice3]
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
        drawingNode?.geometry?.firstMaterial?.diffuse.contents = #colorLiteral(red: 0.7336325645, green: 0.7942582965, blue: 1, alpha: 1)
        drawingNode?.geometry?.firstMaterial?.isDoubleSided = true
    }
}

extension ViewController: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval){
        if isDrawing {
            addPointAndCreateVertices()
        }
    }
}
