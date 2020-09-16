//
//  ARViewController.swift
//  SceneKitCustomerApp
//
//  Created by MacMini45 on 16/09/20.
//  Copyright © 2020 macmini08. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

enum PropertyARModelView: Int {
    case bird
    case person
}

class ARViewController: UIViewController, ARSCNViewDelegate {

    /// Outlets
    @IBOutlet weak var setResetButton: UIButton!
    @IBOutlet weak var viewStackView: UIStackView!
    @IBOutlet weak var helpLabel: UILabel!
    @IBOutlet weak var trackingStatusLabel: UILabel!

    /// Constraints
    @IBOutlet weak var viewStackViewTopConstraint: NSLayoutConstraint!

    /// Properties
    // To get selected property id
    var selectedPropertyId = 0
    var viewType: PropertyARModelView = .bird
    private var nodeModel:SCNNode!
    private var modelScene = SCNScene()
    private var nodeName = ""
    private var previousNode: SCNNode?
    private var isPositionSet = false
    private var sceneView = ARSCNView()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setScreenLayout()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        sceneView.session.run(configuration)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Pause the view's session
        sceneView.session.pause()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Custom Methods
    func setScreenLayout() {

        if viewType == .bird {
            removePreviousModels()
            self.helpLabel.text = "Tap on a point, preferably on a flat surface, where you would like to place the model.\nTap anywhere to reset its position and tap the Set button to prevent further touches."
        } else if viewType == .person {
            removePreviousModels()
            helpLabel.text = "Tap on a point on the floor below you to place the model in accordance with your surroundings.\nTap anywhere to reset its position and tap the Set button to prevent further touches."
        }

        // Set corner radius of button and label and hide button initially
        setResetButton.isHidden = true
        setResetButton.layer.cornerRadius = 25.0
        helpLabel.layer.cornerRadius = 10.0
        helpLabel.layer.masksToBounds = true
        trackingStatusLabel.layer.cornerRadius = 5.0
        trackingStatusLabel.layer.masksToBounds = true

        sceneView = ARSCNView(frame: view.bounds)
        view.addSubview(sceneView)
        view.sendSubviewToBack(sceneView)
        view.bringSubviewToFront(viewStackView)

        // Set the view's delegate
        sceneView.delegate = self

        // Show statistics such as fps and timing information
//        sceneView.showsStatistics = true
//        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        sceneView.antialiasingMode = .multisampling4X
        sceneView.automaticallyUpdatesLighting = true

        // Create a new scene
        let scene = SCNScene()

        // Set the scene to the view
        sceneView.scene = scene

        modelScene = SCNScene(named: "art.scnassets/model.dae")!

        let newChildNode: SCNNode!
        if modelScene.rootNode.childNodes.count > 0 {
            newChildNode = modelScene.rootNode.clone()
            newChildNode.name = "childNode"
            nodeName = "childNode"
            for node in modelScene.rootNode.childNodes {
                node.removeFromParentNode()
            }
            modelScene.rootNode.addChildNode(newChildNode)
        }

        nodeModel =  modelScene.rootNode.childNode(withName: nodeName, recursively: true)
    }

    @objc func hideShowButtonImage(notification: Notification) {
        if let isVisible = notification.userInfo!["isVisible"] as? Bool {
            if isVisible {
                viewStackViewTopConstraint.constant = -(58)
                sceneView.isUserInteractionEnabled = false
                UIView.animate(withDuration: 0.5, animations: {
                    self.view.layoutIfNeeded()
                })
            } else {
                viewStackViewTopConstraint.constant = 10
                sceneView.isUserInteractionEnabled = true
                UIView.animate(withDuration: 0.5, animations: {
                    self.view.layoutIfNeeded()
                })
            }
        }
    }

    func birdViewAction() {
        viewType = .bird

        removePreviousModels()
        self.helpLabel.text = "Tap on a point, preferably on a flat surface, where you would like to place the model.\nTap anywhere to reset its position and tap the Set button to prevent further touches."
    }

    func personViewAction() {
        viewType = .person

        removePreviousModels()
        helpLabel.text = "Tap on a point on the floor below you to place the model in accordance with your surroundings.\nTap anywhere to reset its position and tap the Set button to prevent further touches."
    }

    func setResetButtonAction() {
        if isPositionSet {
            setResetButton.setTitle("Set", for: .normal)
            helpLabel.isHidden = false
            trackingStatusLabel.isHidden = false
            //            personViewButton.isHidden = false
            //            birdViewButton.isHidden = false
        } else {
            setResetButton.setTitle("Reset", for: .normal)
            helpLabel.isHidden = true
            trackingStatusLabel.isHidden = true
            //            personViewButton.isHidden = true
            //            birdViewButton.isHidden = true
        }
        isPositionSet = !isPositionSet
    }

    // MARK: - Action Methods
    @IBAction func setResetButtonTap(_ sender: Any) {
        setResetButtonAction()
    }

    @IBAction func birdEyeButtonTapped(_ sender: Any) {
        birdViewAction()
    }

    @IBAction func personViewButtonTapped(_ sender: Any) {
        personViewAction()
    }

    // MARK: - ARSCNViewDelegate
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if !anchor.isKind(of: ARPlaneAnchor.self) {
            DispatchQueue.main.async {

                if self.previousNode != nil {
                    self.previousNode?.removeFromParentNode()
                }

                let modelClone = self.nodeModel.clone()
                modelClone.position = SCNVector3Zero

                if self.viewType == .bird {
                    modelClone.scale = SCNVector3Make(0.02, 0.02, 0.02)
                }

                self.previousNode = modelClone
                self.setResetButton.isHidden = false

                // Add model as a child of the node
                node.addChildNode(modelClone)
            }
        }
    }

    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user

    }

    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay

    }

    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required

    }

    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        // session camera state
        let attributedTitle = NSMutableAttributedString.init(string: "Status")
        attributedTitle.append(NSMutableAttributedString.init(string: " ●", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.systemFont(ofSize: 30, weight: UIFont.Weight.semibold)])))
        self.trackingStatusLabel.attributedText = attributedTitle
        switch camera.trackingState {
        case .notAvailable:
            attributedTitle.addAttribute(NSAttributedString.Key.foregroundColor, value: #colorLiteral(red: 1, green: 0.1491314173, blue: 0, alpha: 1), range: NSRange(location:attributedTitle.length - 1,length:1))
            self.trackingStatusLabel.attributedText = attributedTitle
            break
        case .limited(_):
            attributedTitle.addAttribute(NSAttributedString.Key.foregroundColor, value: #colorLiteral(red: 0.9739639163, green: 0.7061158419, blue: 0.1748842001, alpha: 1), range: NSRange(location:attributedTitle.length - 1,length:1))
            self.trackingStatusLabel.attributedText = attributedTitle
            break
        case .normal:
            attributedTitle.addAttribute(NSAttributedString.Key.foregroundColor, value: #colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1), range: NSRange(location:attributedTitle.length - 1,length:1))
            self.trackingStatusLabel.attributedText = attributedTitle
            break
        }
    }

    // MARK: - Private methods

    private func removePreviousModels() {

        if previousNode != nil {

            previousNode?.removeFromParentNode()
            previousNode = nil

            isPositionSet = false
            setResetButton.setTitle("Set", for: .normal)
            setResetButton.isHidden = true

            helpLabel.isHidden = false
            trackingStatusLabel.isHidden = false
//            personViewButton.isHidden = false
//            birdViewButton.isHidden = false
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {

        if !isPositionSet {

            let location = touches.first!.location(in: sceneView)

            // Let's test if a 3D Object was touch
            var hitTestOptions = [SCNHitTestOption: Any]()
            hitTestOptions[SCNHitTestOption.boundingBoxOnly] = true

            let hitResults: [SCNHitTestResult]  = sceneView.hitTest(location, options: hitTestOptions)

            if let hit = hitResults.first {
                if getParent(hit.node) != nil {
                    removePreviousModels()
                    return
                }
            }

            // No object was touch? Try feature points
            let hitResultsFeaturePoints: [ARHitTestResult]  = sceneView.hitTest(location, types: .featurePoint)

            if let hit = hitResultsFeaturePoints.first {

                // Get the rotation matrix of the camera
                let rotate = simd_float4x4(SCNMatrix4MakeRotation(sceneView.session.currentFrame!.camera.eulerAngles.y, 0, 1, 0))

                // Combine the matrices
                let finalTransform = simd_mul(hit.worldTransform, rotate)
                sceneView.session.add(anchor: ARAnchor(transform: finalTransform))
            }
        }
    }

    private func getParent(_ nodeFound: SCNNode?) -> SCNNode? {
        if let node = nodeFound {
            if node.name == nodeName {
                return node
            } else if let parent = node.parent {
                return getParent(parent)
            }
        }
        return nil
    }


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

fileprivate func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
    guard let input = input else { return nil }
    return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value)})
}

fileprivate func convertFromNSAttributedStringKey(_ input: NSAttributedString.Key) -> String {
    return input.rawValue
}
