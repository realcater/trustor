//
//  QuestionsView.swift
//  TrustOr
//
//  Created by Dmitry Dementyev on 14.08.2018.
//  Copyright © 2018 Dmitry Dementyev. All rights reserved.
//

import UIKit

class PlayVC: UIViewController {
    
    var gameData: GameData!
    var gameID: UUID?
    var mode: Mode?
    
    var turnTimer: Timer?
    var timeLeft: Int!
    var lastTime: Int!
    
    var btnTimer: Timer?
    var btnTimeLeft: Int!
    
    var guessedQty: Int = 0
    var currentTitle: String?
    var statusTimer: Timer?
    
    @IBOutlet weak var wordLabel: UILabel!
    @IBOutlet weak var circleView: UIView!
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var guessedButton: MyButton!
    @IBOutlet weak var notGuessedButton: MyButton!
    @IBOutlet weak var helpMessage: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = K.Colors.background
        navigationController!.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: K.Colors.lightGray]
        circleView.layer.cornerRadius = K.CircleCornerRadius.big
        lastTime = gameData.settings.roundDuration
        gameData.clear()
        updateTitle()
        nextWord()
        createTurnTimer()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "noWords" {
            let endGameVC = segue.destination as? EndGameVC
            endGameVC?.players = self.gameData.players.sorted { $0.ttlGuesses > $1.ttlGuesses }
            statusTimer?.invalidate()
        }
    }
}

// MARK: - buttons handlers
private extension PlayVC {
    @IBAction func guessedPressed(_ sender: Any) {
        K.Sounds.correct?.resetAndPlay()
        gameData.setWordGuessed(time: lastTime - timeLeft)
        lastTime = timeLeft
        guessedQty+=1
        updateTitle()
        nextWord()
    }
    
    @IBAction func notGuessedTouchDown(_ sender: Any) {
        notGuessedButton.backgroundColor = K.Colors.redDarker
        createBtnTimer(duration: K.Delays.notGuessedBtn)
    }
    @IBAction func notGuessedTouchUp(_ sender: Any) {
        notGuessedButton.backgroundColor = K.Colors.gray
        helpMessage.isHidden = false
        cancelBtnTimer()
    }
}

// MARK: - private functions
private extension PlayVC {
    func updateTitle() {
        currentTitle = "Угадано: \(guessedQty) слов"
        title = currentTitle
    }
    
    func nextWord() {
        if mode != .offline {
            API.updateFrequent(gameID: gameID!, gameData: gameData, title: currentTitle, showWarningOrTitle: self.doNotShowWarnings)
        }
        if gameData.getRandomWordFromPool() {
            wordLabel.text = gameData.currentWord
        } else {
            cancelTurnTimer()
            gameData.turn = K.endTurnNumber
            API.updateUntilSuccess(gameID: gameID!, gameData: gameData, showWarningOrTitle: self.showWarningOrTitle) { self.performSegue(withIdentifier: "noWords", sender: self) }
        }
    }
    
    func nextPair() {
        cancelTurnTimer()
        gameData.turn += 1
        if mode != .offline {
            gameData.explainTime = Date().addingTimeInterval(-100000).convertTo()
            guessedButton.disable()
            notGuessedButton.disable()
            API.updateUntilSuccess(gameID: gameID!, gameData: gameData, title: currentTitle, showWarningOrTitle: self.showWarningOrTitle) {
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    func updateExplainTime() {
        gameData.explainTime = Date().convertTo(use: "yyyy-MM-dd'T'HH:mm:ss'Z'")
        API.updateFrequent(gameID: gameID!, gameData: gameData, title: currentTitle, showWarningOrTitle: self.doNotShowWarnings)
    }
    
    func doNotShowWarnings(_ error: RequestError?, _ title: String? = nil) {
    }

}

// MARK: - TurnTimer
extension PlayVC {
    @objc func updateTurnTimer() {
        timeLeft -= 1
        timerLabel.text = String(timeLeft)

        if timeLeft == 0 {
            K.Sounds.timeOver?.resetAndPlay()
            gameData.setWordLeft(time: lastTime)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                self.nextPair()
            })
        } else if timeLeft == K.Delays.withClicks {
            K.Sounds.click?.play()
            circleView.backgroundColor = K.Colors.redDarker
        } else if timeLeft < K.Delays.withClicks {
            K.Sounds.click?.play()
        }
    }
    
    func createTurnTimer() {
        if turnTimer == nil {
            
            turnTimer = Timer.scheduledTimer(timeInterval: 1.0,
                                         target: self,
                                         selector: #selector(updateTurnTimer),
                                         userInfo: nil,
                                        repeats: true)
            turnTimer?.tolerance = 0.1
            timeLeft = gameData.settings.roundDuration
            timerLabel.text = String(timeLeft)
            if mode != .offline { updateExplainTime() }
        }
    }
    
    func cancelTurnTimer() {
        turnTimer?.invalidate()
        turnTimer = nil
    }
}

// MARK: - BtnTimer
extension PlayVC {
    @objc func resolveBtnTimer() {
        gameData.setWordMissed(time: lastTime-timeLeft)
        K.Sounds.error?.play()
        nextPair()
    }
    
    func createBtnTimer(duration: Double) {
        if btnTimer == nil {
            btnTimer = Timer.scheduledTimer(timeInterval: duration,
                                         target: self,
                                         selector: #selector(resolveBtnTimer),
                                         userInfo: nil,
                                         repeats: false)
            btnTimer?.tolerance = 0.1
        }
    }
    
    func cancelBtnTimer() {
        btnTimer?.invalidate()
        btnTimer = nil
    }
}
