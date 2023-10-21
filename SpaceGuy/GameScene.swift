//
//  GameScene.swift
//  SpaceGuy
//
//  Created by Andrew Acheampong on 10/21/23.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    //Nodes
    var player : SKNode?
    var joystick : SKNode?
    var joystickKnob: SKNode?
    
    //boolean
    var joystckAction = false
    
    //measure
    var knobRadius : CGFloat = 50.0
    
    //Sprite Engine
    var previousTimeInterval : TimeInterval = 0
    var playerisFacingRight = true
    let playerSpeed = 4.0
    
    
    //Player state
    var playerStateMachine : GKStateMachine!
    
    
    //didmove
    override func didMove(to view: SKView) {
        player = childNode(withName: "player")
        joystick = childNode(withName: "joystick")
        joystickKnob = joystick?.childNode(withName: "knob")
        
        playerStateMachine = GKStateMachine(states: [
            JumpingState(playerNode: player!),
            WalkingState(playerNode: player!),
            idleState(playerNode: player!),
            LandingState(playerNode: player!),
            StunnedState (playerNode: player!),
        ])
        
        playerStateMachine.enter(idleState.self)
    }
}

// MARK: Touches
extension GameScene{
    //touch began
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            if let joystickKnob = joystickKnob{
                let location = touch.location(in: joystick!)
                joystckAction = joystickKnob.frame.contains(location)
            }
            
            let location = touch.location(in: self)
            if !( joystick?.contains(location))! {
                playerStateMachine.enter(JumpingState.self)
            }
            
        }
        
        
    }
    //touch moved
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let joystick = joystick else {return}
        guard let joystickKnob = joystickKnob else {return }
        
        if !joystckAction { return}
        
        //Distance
        for touch in touches {
            let position = touch.location(in: joystick)
            
            //use Pythagorean theory the distance between initial point of knob to where we are going to hold it
            let length = sqrt(pow(position.y, 2) + pow ( position.x, 2))
            let angle = atan2(position.y, position.x)
            
            if knobRadius > length{
                joystickKnob.position = position
            }else {
                joystickKnob.position  = CGPoint( x: cos(angle)*knobRadius,y: sin(angle) * knobRadius)
            }
        }
    }
    //touch end
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let xJoystickCoordinate = touch.location(in: joystick!).x
            let xLimit: CGFloat = 200.0
            if xJoystickCoordinate > -xLimit && xJoystickCoordinate < xLimit{
                resestKnobPosition()
            }
        }
    }
}

//Mark: Action
extension GameScene{
    func resestKnobPosition() {
        let initialPoint = CGPoint(x: 0, y: 0)
        let moveBack = SKAction.move(to: initialPoint, duration: 0.1)
        moveBack.timingMode = .linear
        joystickKnob?.run(moveBack)
        joystckAction = false
        
    }
}

//Mark : Game Loop

extension GameScene {
    override func update(_ currentTime: TimeInterval) {
        let deltaTime  = currentTime - previousTimeInterval
        previousTimeInterval = currentTime
        
        //player movement
        guard let joystickKnob = joystickKnob else { return }
        let xPosition = Double(joystickKnob.position.x)
        let positivePosition = xPosition < 0 ? -xPosition : xPosition
        
        if floor(positivePosition) != 0 {
            playerStateMachine.enter(WalkingState.self)
        }else{
            playerStateMachine.enter(idleState.self)
        }
        
        let displacement = CGVector(dx: deltaTime * xPosition * playerSpeed, dy: 0)
        let move = SKAction.move(by: displacement, duration: 0)
        let faceAction : SKAction!
        let movingRight = xPosition > 0
        let movingLeft = xPosition < 0
        
        if movingLeft && playerisFacingRight{
            playerisFacingRight = false
            let faceMovement = SKAction.scaleX(to: -1, duration: 0.0 )
            faceAction = SKAction.sequence([move, faceMovement])
            
            
        }
        else if movingRight && playerisFacingRight {
            playerisFacingRight = true
            let faceMovement = SKAction.scale(to: 1, duration: 0.0)
            faceAction = SKAction.sequence([move,faceMovement])
        }else{
            faceAction = move
        }
        player?.run(faceAction)
        
        
    }
}
