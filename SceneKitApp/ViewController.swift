//
//  ViewController.swift
//  SceneKitCustomerApp
//
//  Created by macmini08 on 01/10/18.
//  Copyright © 2018 macmini08. All rights reserved.
//

import UIKit
import SceneKit
import SceneKit.ModelIO

enum PropertyModelView: Int {
    case floorPlan
    case bird
    case person
}

class ViewController: UIViewController {

    @IBOutlet weak var sceneView: SCNView!
    
    private let floorCameraNode = SCNNode()
    private let birdCameraNode = SCNNode()
    private let personCameraNode = SCNNode()
    private let invisibleOriginNode = SCNNode()
    private let invisibleMovableNode = SCNNode()
    
    private var scene: SCNScene?
    
    private var currentFloorPosition = SCNVector3Make(0, 35, 0)
    private var currentBirdPosition = SCNVector3Make(35, 35, 35)
    private var currentPersonPosition = SCNVector3Make(0, 1, 0)
    private var currentInvisibleMovableNodePosition = SCNVector3Make(-100, 1, -150)
    private var currentFloorScale: CGFloat = 1.0
    private var currentBirdScale: CGFloat = 1.0
    private var maxBirdViewHeight: Float = 0.0
    private let minBirdViewHeight: Float = 15.0
    private let initialDistance: Float = 35.0

    var viewType: PropertyModelView = .floorPlan
    private var shouldTranslateHorizontal = false
    private var confirmTranslation = false

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        setupSceneKit()
    }

    @IBAction func floorplanButtonTapped(_ sender: Any) {
        floorPlanAction()
    }

    @IBAction func birdEyeButtonTapped(_ sender: Any) {
        birdViewAction()
    }
    
    @IBAction func personButtonTapped(_ sender: Any) {
        personViewAction()
    }

    private func setupSceneKit() {
        maxBirdViewHeight = sqrt(pow(currentBirdPosition.x, 2) + pow(currentBirdPosition.y, 2) + pow(currentBirdPosition.z, 2))
        
        view.addSubview(sceneView)
        view.sendSubviewToBack(sceneView)
        
        
        //let objPath = Util.getModelFilePath(propertyId: selectedPropertyId)

        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panGesture(sender:)))
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(pinch(sender:)))

        sceneView.addGestureRecognizer(pinch)
        sceneView.addGestureRecognizer(panRecognizer)
        
        scene = SCNScene(named: "art.scnassets/model.dae")//SCNScene.init(url: URL(string: objPath)!, options: nil)

        if let materials = scene?.rootNode.childNodes[0].geometry?.materials {
            for material in materials {
                material.lightingModel = .blinn
                if let alpha = material.transparent.contents as? CGFloat, alpha < 1 {
                    material.transparency = alpha
                }
            }
        }

        sceneView.scene = scene
        
        createInvisibleOriginNode()
        createInvisibleMovableNode()
        createFloorCameraNode()
        createBirdCameraNode()
        createPersonCameraNode()
    }
    
    private func createInvisibleOriginNode() {
        invisibleOriginNode.position = SCNVector3(0, 0, 0)
    }
    
    private func createInvisibleMovableNode() {
        invisibleMovableNode.position = currentInvisibleMovableNodePosition
    }
    
    private func createBirdCameraNode() {
        birdCameraNode.camera = SCNCamera()
        let lookAt = SCNLookAtConstraint(target: invisibleOriginNode)
        lookAt.isGimbalLockEnabled = true
        birdCameraNode.constraints = [lookAt]
        birdCameraNode.position = currentBirdPosition
        self.scene?.rootNode.addChildNode(birdCameraNode)
    }
    
    private func createPersonCameraNode() {
        personCameraNode.camera = SCNCamera()
        personCameraNode.camera?.zNear = 0
        personCameraNode.camera?.automaticallyAdjustsZRange = true
        let lookAt = SCNLookAtConstraint(target: invisibleMovableNode)
        lookAt.isGimbalLockEnabled = true
        personCameraNode.constraints = [lookAt]
        personCameraNode.position = currentPersonPosition
        self.scene?.rootNode.addChildNode(personCameraNode)
    }
    
    private func createFloorCameraNode() {
        floorCameraNode.camera = SCNCamera()
        floorCameraNode.transform = SCNMatrix4MakeRotation(-.pi/2, 1, 0, 0)
        floorCameraNode.position = currentFloorPosition
        self.scene?.rootNode.addChildNode(floorCameraNode)
        sceneView.pointOfView = floorCameraNode
    }

    // MARK: - Gesture Recognizer methods
    @objc func panGesture(sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: sender.view!)

        if !confirmTranslation && (abs(translation.x) > 3.0 || abs(translation.y) > 3.0) {
            confirmTranslation = true
            if abs(translation.x) > abs(translation.y) {
                shouldTranslateHorizontal = true
            } else {
                shouldTranslateHorizontal = false
            }
        }

        if viewType == .floorPlan {

            performFloorPlanTranslation(sender: sender)

        } else if viewType == .bird {

            if !confirmTranslation || (confirmTranslation && shouldTranslateHorizontal) {

                performBirdViewXAxisTranslation(sender: sender)

            } else if !confirmTranslation || (confirmTranslation && !shouldTranslateHorizontal) {

                performBirdViewYAxisTranslation(sender: sender)
            }
        } else if viewType == .person {

            if !confirmTranslation || (confirmTranslation && shouldTranslateHorizontal) {

                performPersonViewXAxisTranslation(sender: sender)

            } else if !confirmTranslation || (confirmTranslation && !shouldTranslateHorizontal) {

                performPersonViewYAxisTranslation(sender: sender)
            }
        }
    }

    @objc func pinch(sender:UIPinchGestureRecognizer) {

        if viewType == .floorPlan {

            performFloorPlanScaling(sender: sender)

        } else if viewType == .bird {

            performBirdViewScaling(sender: sender)
        }
    }

    private func performFloorPlanTranslation(sender: UIPanGestureRecognizer) {

        let translation = sender.translation(in: sender.view!)

        let scalePositionFactor = 3 * ( (currentFloorPosition.y - initialDistance) / Float(currentFloorScale) )
        let xPos = currentFloorPosition.x - Float(translation.x/CGFloat(30 - (2 * scalePositionFactor)))
        let zPos = currentFloorPosition.z - Float(translation.y/CGFloat(30 - (2 * scalePositionFactor)))
        let newPosition = SCNVector3Make(xPos, currentFloorPosition.y, zPos)
        floorCameraNode.position = newPosition

        if(sender.state == UIGestureRecognizer.State.ended) {
            currentFloorPosition = newPosition
        }
    }

    private func performBirdViewXAxisTranslation(sender: UIPanGestureRecognizer) {

        let translation = sender.translation(in: sender.view!)

        //u=scosθ-tsinθ and v=ssinθ+tcosθ
        let angle = Float(translation.x/5) * .pi / 180
        let xPos = currentBirdPosition.x * cos(angle) - currentBirdPosition.z * sin(angle)
        let zPos = currentBirdPosition.x * sin(angle) + currentBirdPosition.z * cos(angle)

        let newPosition = SCNVector3Make(xPos, currentBirdPosition.y, zPos)
        birdCameraNode.position = newPosition

        if (sender.state == .ended) {
            currentBirdPosition = newPosition
            confirmTranslation = false
        }
    }

    private func performBirdViewYAxisTranslation(sender: UIPanGestureRecognizer) {

        let translation = sender.translation(in: sender.view!)

        /*
         x/z ratio will be constant when moving vertically
         using that the formula can be as follows
         */

        let radius = sqrt(pow(currentBirdPosition.x, 2) + pow(currentBirdPosition.y, 2) + pow(currentBirdPosition.z, 2))
        let xzRatio = currentBirdPosition.x / currentBirdPosition.z

        let yPos = min(max(currentBirdPosition.y + Float(translation.y/30), radius/3), radius/1.1)
        var zPos = sqrt((pow(radius, 2) - pow(yPos, 2)) / (1 + pow(xzRatio, 2)))
        if currentBirdPosition.z < 0 {
            zPos = -abs(zPos)
        } else {
            zPos = abs(zPos)
        }
        let xPos = xzRatio * zPos

        let newPosition = SCNVector3Make(xPos, yPos, zPos)
        birdCameraNode.position = newPosition

        if sender.state == .ended {
            currentBirdPosition = newPosition
            confirmTranslation = false
        }
    }

    private func performPersonViewXAxisTranslation(sender: UIPanGestureRecognizer) {

        let translation = sender.translation(in: sender.view!)

        //u=scosθ-tsinθ and v=ssinθ+tcosθ
        let angle = Float(-translation.x/10) * .pi / 180
        let xPos = currentInvisibleMovableNodePosition.x * cos(angle) - currentInvisibleMovableNodePosition.z * sin(angle)
        let zPos = currentInvisibleMovableNodePosition.x * sin(angle) + currentInvisibleMovableNodePosition.z * cos(angle)
        let newPosition = SCNVector3Make(xPos, currentInvisibleMovableNodePosition.y, zPos)

        invisibleMovableNode.position = newPosition

        let lookAt = SCNLookAtConstraint(target: invisibleMovableNode)
        lookAt.isGimbalLockEnabled = true
        personCameraNode.constraints = [lookAt]

        if(sender.state == UIGestureRecognizer.State.ended) {
            currentInvisibleMovableNodePosition = newPosition
            confirmTranslation = false
        }
    }

    private func performPersonViewYAxisTranslation(sender: UIPanGestureRecognizer) {

        let translation = sender.translation(in: sender.view!)

        // Equation of a line
        // y = mx + c

        let slope = (currentInvisibleMovableNodePosition.z - currentPersonPosition.z) / (currentInvisibleMovableNodePosition.x - currentPersonPosition.x)
        let constant = currentPersonPosition.z - (slope * currentPersonPosition.x)
        var direction: Float = 1.0
        if Float(translation.y) * currentInvisibleMovableNodePosition.x > 0 {
            direction = -1.0
        }

        let xChange = sqrt(pow(Float(translation.y/100), 2) / Float(1 + pow(slope, 2)))
        let xPos = currentPersonPosition.x - (xChange * direction)
        let zPos = (slope * xPos) + constant

        let newPosition = SCNVector3Make(xPos, currentPersonPosition.y, zPos)
        personCameraNode.position = newPosition

        if(sender.state == UIGestureRecognizer.State.ended) {
            currentPersonPosition = newPosition
            confirmTranslation = false
        }
    }

    private func performFloorPlanScaling(sender: UIPinchGestureRecognizer) {

        var scale = currentFloorScale * sender.scale
        if scale < 1 {
            scale = 1
        }
        if scale > 8 {
            scale = 8
        }

        let yPos = max(min(initialDistance,  currentFloorPosition.y - Float(3 * (scale - currentFloorScale))), 0)
        let newPosition = SCNVector3Make(currentFloorPosition.x, yPos, currentFloorPosition.z)
        floorCameraNode.position = newPosition

        if sender.state == .ended {
            currentFloorPosition = newPosition
            currentFloorScale = scale
        }
    }

    private func performBirdViewScaling(sender: UIPinchGestureRecognizer) {

        var scale = currentBirdScale * sender.scale
        if scale < 1 {
            scale = 1
        }
        if scale > 8 {
            scale = 8
        }

        /*
         r       =    sqrt(x^2+y^2+z^2)
         theta   =    tan^(-1)(y/x)
         phi     =    cos^(-1)(z/r)
         */

        var radius = sqrt(pow(currentBirdPosition.x, 2) + pow(currentBirdPosition.y, 2) + pow(currentBirdPosition.z, 2))
        var theta = atan(currentBirdPosition.y / currentBirdPosition.x)
        if theta < 0 {
            theta = theta + .pi
        }
        let phi = acos(currentBirdPosition.z / radius)

        radius = max(maxBirdViewHeight - Float((scale - 1) * 5), minBirdViewHeight)
        let zPos = radius * cos(phi)
        let xPos = radius * cos(theta) * sin(phi)
        let yPos = radius * sin(theta) * sin(phi)

        let newPosition = SCNVector3Make(xPos, yPos, zPos)
        birdCameraNode.position = newPosition

        if sender.state == .ended {
            currentBirdPosition = newPosition
            currentBirdScale = scale
        }
    }

    func floorPlanAction() {
        viewType = .floorPlan
        sceneView.pointOfView = floorCameraNode
    }

    func birdViewAction() {
        viewType = .bird
        sceneView.pointOfView = birdCameraNode
    }

    func personViewAction() {
        viewType = .person
        sceneView.pointOfView = personCameraNode
    }
}

