/**
 * Copyright (c) 2017 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
 * distribute, sublicense, create a derivative work, and/or sell copies of the
 * Software in any work that is designed, intended, or marketed for pedagogical or
 * instructional purposes related to programming, coding, application development,
 * or information technology.  Permission for such use, copying, modification,
 * merger, publication, distribution, sublicensing, creation of derivative works,
 * or sale is expressly withheld.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import ARKit

var isWorldSetUp = false
var sight: SKSpriteNode!
let gameSize = CGSize(width: 2, height: 2)
var count = 0

var hasBugspray = false {
  didSet {
    let sightImageName = hasBugspray ? "bugspraySight" : "sight"
    sight.texture = SKTexture(imageNamed: sightImageName)
  }
}

class GameScene: SKScene {
  
  var sceneView: ARSKView {
    return view as! ARSKView
  }
  
  
  private func setUpWorld() {
    
    
    guard let currentFrame = sceneView.session.currentFrame,
      // 1
      let scene = SKScene(fileNamed: "Level1")
      else { return }
    
    var bugCountDown = SKLabelNode(text: "10")
    bugCountDown.fontSize = 40
    bugCountDown.fontName = "Verdana-Bold"
    bugCountDown.position = CGPoint(x: -150, y: 380)
    bugCountDown.name = "bugCountDown"
    addChild(bugCountDown)
      
    for node in scene.children {
      if let node = node as? SKSpriteNode {
        var translation = matrix_identity_float4x4
        // 2
        let positionX = node.position.x / scene.size.width
        let positionY = node.position.y / scene.size.height
        translation.columns.3.x =
                Float(positionX * gameSize.width)
        translation.columns.3.z =
                -Float(positionY * gameSize.height)
        translation.columns.3.y = Float(drand48() - 0.5)

        let transform =
               currentFrame.camera.transform * translation
        let anchor = Anchor(transform: transform)
        if let name = node.name,
          let type = NodeType(rawValue: name) {
          anchor.type = type
          sceneView.session.add(anchor: anchor)
          if anchor.type == .firebug {
            addBugSpray(to: currentFrame)
          }
        }
      }
    }
    isWorldSetUp = true
  }
  
  override func update(_ currentTime: TimeInterval) {
    if !isWorldSetUp {
      setUpWorld()
    }
    
    // 1
    guard let currentFrame = sceneView.session.currentFrame,
      let lightEstimate = currentFrame.lightEstimate else {
        return
    }
    // 2
    let neutralIntensity: CGFloat = 1000
    let ambientIntensity = min(lightEstimate.ambientIntensity,
                               neutralIntensity)
    let blendFactor = 1 - ambientIntensity / neutralIntensity

    // 3
    for node in children {
      if let bug = node as? SKSpriteNode {
        bug.color = .black
        bug.colorBlendFactor = blendFactor
      }
    }
  }
  
  override func didMove(to view: SKView) {
    sight = SKSpriteNode(imageNamed: "sight")
    addChild(sight)
    srand48(Int(Date.timeIntervalSinceReferenceDate))
  }
  
  override func touchesBegan(_ touches: Set<UITouch>,
                             with event: UIEvent?) {
    let location = sight.position
    let hitNodes = nodes(at: location)
    print(hitNodes)
    print("hasBugSpray: \(hasBugspray)")
    var hitBug: SKNode?
    for node in hitNodes {
      print("Node Value: \(node.name)")
      
      if node.name == NodeType.bug.rawValue ||
      (node.name == NodeType.firebug.rawValue && hasBugspray) {
        hitBug = node
        break
      }
      else if node.name == NodeType.bugspray.rawValue {
        hasBugspray = true
      }
      else if (node as? SKLabelNode) != nil {
        print("sklabelnode")
        node.removeFromParent()

          self.setUpWorld()

      }
      print("hasBugSpray: \(hasBugspray)")
    }
    
    run(Sounds.fire)
    if let hitBug = hitBug,
      let anchor = sceneView.anchor(for: hitBug) {
      let action = SKAction.run {
        count += 1
        print("Count is: \(count)")
        
        self.sceneView.session.remove(anchor: anchor)
        
        var countDown: SKLabelNode? = self.sceneView.scene?.childNode(withName: "bugCountDown") as? SKLabelNode
        if let countDown = countDown, let countString = countDown.text {
          print("lelvell")
          if let count = Int(countString) {
            print("dsfsdfs")
            countDown.text = String(count - 1)
          }
        }
        
        if count == 10 {
          let winner = SKLabelNode(fontNamed: "Menlo")
          winner.text = "You Win!"
          winner.fontSize = 65
          winner.fontColor = SKColor.red
          winner.position = CGPoint(x: self.frame.midX, y: self.frame.midY)
          count = 0
          self.sceneView.scene?.childNode(withName: "bugspray")?.removeFromParent()
          self.sceneView.scene?.childNode(withName: "bugCountDown")?.removeFromParent()

          sight.texture = SKTexture(imageNamed: "sight")
          self.addChild(winner)
        }
      }
      let group = SKAction.group([Sounds.hit, action])
      let sequence = [SKAction.wait(forDuration: 0.3), group]
      hitBug.run(SKAction.sequence(sequence))
    }
  }
  
  private func addBugSpray(to currentFrame: ARFrame) {
    print("addBugSpray")
    var translation = matrix_identity_float4x4
    translation.columns.3.x = 2
    translation.columns.3.z = 1
    translation.columns.3.y = 2
    let transform = currentFrame.camera.transform * translation
    let anchor = Anchor(transform: transform)
    anchor.type = .bugspray
    sceneView.session.add(anchor: anchor)
  }
  
  private func remove(bugspray anchor: ARAnchor) {
    print("Remove bugspray")
    run(Sounds.bugspray)
    sceneView.session.remove(anchor: anchor)
    hasBugspray = true
  }
}
