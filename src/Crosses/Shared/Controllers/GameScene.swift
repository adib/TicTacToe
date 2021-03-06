//
//  GameScene.swift
//  Crosses
//
//  Copyright (C) 2017  Sasmito Adibowo – http://cutecoder.org

//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.

//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.

//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.

import SpriteKit
#if os(watchOS)
    import WatchKit
    // <rdar://problem/26756207> SKColor typealias does not seem to be exposed on watchOS SpriteKit
    typealias SKColor = UIColor
#endif

class GameScene: SKScene,GameBoardSpriteDelegate,GameSessionDelegate {
    
    class func newGameScene() -> GameScene {
        // Load 'GameScene.sks' as an SKScene.
        guard let scene = SKScene(fileNamed: "GameScene") as? GameScene else {
            print("Failed to load GameScene.sks")
            abort()
        }
        
        // Set the scale mode to scale to fit the window
        scene.scaleMode = .aspectFill
        
        return scene
    }
    
    let gameRestartDelay = TimeInterval(0.3)
    
    var session : GameSession? {
        didSet {
            if let s = session {
                s.delegate = self
            }
        }
    }

    weak var gameBoard : GameBoardSprite! {
        didSet {
            if let v = gameBoard {
                v.delegate = self
            }
        }
    }
    
    weak var titleLabel : SKLabelNode!

    weak var statusLabel : SKLabelNode!
    
    var scores = GameScore()
    
    func setUpScene() {
        let gameBoard = self.childNode(withName: "//board") as! GameBoardSprite
        gameBoard.isUserInteractionEnabled = true
        self.gameBoard = gameBoard
        
        self.titleLabel = self.childNode(withName: "//titleLabel") as! SKLabelNode
        self.statusLabel = self.childNode(withName: "//statusLabel") as! SKLabelNode
        
        let session = GameSession()
        self.session = session
        self.titleLabel.text = NSLocalizedString("Your Move", comment: "Game Title")
        updateScores()
        session.start(computerMove: false)
    }
    
    #if os(watchOS)
    override func sceneDidLoad() {
        self.setUpScene()
    }
    #else
    override func didMove(to view: SKView) {
        self.setUpScene()
    }
    #endif

    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
    
    func updateScores() {
        self.statusLabel.text = String.localizedStringWithFormat(NSLocalizedString("Games Played: %d  Won: %d  Lost: %d", comment: "Score title"), scores.totalGamesPlayed,scores.totalVictories,scores.totalLosses)
    }
    
    func restartGame() {
        gameBoard.reset()
        let session = GameSession()
        self.session = session
        session.start(computerMove: scores.lastGameLost)
    }
    
    // MARK: - GameBoardSpriteDelegate
    
    func gameBoardSprite(_ sprite: GameBoardSprite, didPressAtLocation pressLocation: GameBoardState.Location) {
        self.titleLabel.text = ""
        session!.makeCurrentPlayerMove(location: pressLocation)
    }
    
    // MARK: - GameSessionDelegate
    
    func gameSession(_ session: GameSession, player: Player, didMoveTo location: GameBoardState.Location) {
        gameBoard!.setCellAt(location: location, value: player.chip)
    }

    func gameSession(_ session: GameSession, didWinForPlayer wonPlayer: Player) {
        scores.totalGamesPlayed += 1
        if session.computerPlayer == wonPlayer {
            scores.totalLosses += 1
            scores.lastGameLost = true
            self.titleLabel.text = NSLocalizedString("Computer Won!", comment: "Game Title")
        } else if session.userPlayer == wonPlayer {
            scores.totalVictories += 1
            scores.lastGameLost = false
            self.titleLabel.text = NSLocalizedString("You've Won!", comment: "Game Title")
        }
        updateScores()
        self.perform(#selector(GameScene.restartGame), with: nil, afterDelay: gameRestartDelay)
    }

    func gameSessionDidTie(_ session: GameSession) {
        scores.totalGamesPlayed += 1
        self.titleLabel.text = NSLocalizedString("Tie Game", comment: "Game Title")
        updateScores()
        self.perform(#selector(GameScene.restartGame), with: nil, afterDelay: gameRestartDelay)
    }
}

