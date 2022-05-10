//
//  TimerViewController.swift
//  CHTimer
//
//  Created by Chae_Haram on 2022/05/09.
//

import UIKit

class TimerViewController: UIViewController {

    static var identifier = "TimerVC"
    
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var timeProgressBar: UIProgressView!
    @IBOutlet weak var alertLabel: UILabel!
    @IBOutlet weak var lapsTableView: UITableView!
    @IBOutlet weak var replayButton: UIButton!
    
    var timer = Timer()
    var setTime: Int = Int()
    var hours: Int = Int()
    var minutes: Int = Int()
    var seconds: Int = Int()
    var milliseconds: Int = Int()
    var elapsedTimeSeconds: Int = Int()
    var remainSeconds: Int = Int()
    var currentType: CurrentType = .play
    var timerType: TimerType = .hour
    
    enum CurrentType {
        case play
        case pause
    }
    
    enum TimerType {
        case hour
        case minute
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        lapsTableView.delegate = self
        lapsTableView.dataSource = self
        
        replayButton.layer.cornerRadius = 10
        
        if setTime >= 3600 {
            timerType = .hour
        } else {
            timerType = .minute
        }
        
        alertLabel.isHidden = true
        startTimer(with: setTime)
        
        lapsTableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        lapsTableView.reloadData()
    }
    
    func startTimer(with countDownSeconds: Int) {
        let startTime = Date()
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.001, repeats: true, block: { [self] timer in
            elapsedTimeSeconds = Int(Date().timeIntervalSince(startTime))
            remainSeconds = countDownSeconds - elapsedTimeSeconds
            guard remainSeconds >= 0 else {
                timer.invalidate()
                return
            }

            if timerType == .hour {
                hours = remainSeconds / 3600
                minutes = (remainSeconds % 3600) / 60
                seconds = remainSeconds % 60
            
                if hours == 0 && minutes == 0 && seconds <= 10 {
                    alertLabel.isHidden = false
                    timerLabel.textColor = .red
                }
                if hours == 0 && minutes == 0 && seconds == 0 {
                    UIAlertController.timeEndAlert(message: "타이머가 종료되었습니다.", vc: self)
                }
                self.timerLabel.text = String(format: "%02d : %02d : %02d", hours, minutes, seconds)
            } else {
                minutes = (remainSeconds % 3600) / 60
                seconds = remainSeconds % 60
                milliseconds = remainSeconds 
                
                if minutes == 0 && seconds <= 10 {
                    alertLabel.isHidden = false
                    timerLabel.textColor = .red
                }
                if minutes == 0 && seconds == 0 && milliseconds == 0 {
                    UIAlertController.timeEndAlert(message: "타이머가 종료되었습니다.", vc: self)
                }
                self.timerLabel.text = String(format: "%02d : %02d : %02d", minutes, seconds, milliseconds)
            }
            
        })
    }
    
    @IBAction func replayButton(_ sender: UIButton) {
        if currentType == .play {
            replayButton.setTitle("다시시작", for: .normal)
            replayButton.backgroundColor = .systemGreen
            timer.invalidate()
            currentType = .pause
        } else {
            replayButton.setTitle("일시정지", for: .normal)
            replayButton.backgroundColor = .systemGray2
            startTimer(with: remainSeconds)
            currentType = .play
        }
    }
    
    @IBAction func lapButton(_ sender: UIButton) {
        let lap = timerLabel.text!
        var percent = 100 - ((Double(remainSeconds) / Double(setTime)) * 100)
        percent = round(percent * 10) / 10
        if percent > 100 {
            percent = 100
        }
        let addLap = Laps(lap: lap, percent: percent)

        Laps.laps.append(addLap)
        
        let sortData = Laps.laps.sorted(by: { $0.percent > $1.percent })
        Laps.laps = sortData
        
        lapsTableView.reloadData()
        
    }
    
    @IBAction func cancelButton(_ sender: UIButton) {
        timer.invalidate()
        Laps.laps = []
        self.dismiss(animated: true)
    }
    
}

extension TimerViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: LapsTableViewCell.identifier, for: indexPath) as? LapsTableViewCell else { return UITableViewCell() }
        let lapCell = Laps.laps[indexPath.row]
        
        cell.lapLabel.text = lapCell.lap
        cell.percentLabel.text = "( \(lapCell.percent)% 경과 )"
        cell.memoLabel.text = lapCell.memo
        
        return cell
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Laps.laps.count
    }
    
}

extension TimerViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if currentType == .play {
            UIAlertController.showAlert(message: "타이머를 멈추고 다시 시도해주세요.", vc: self)
        } else {
            guard let memoVC = self.storyboard?.instantiateViewController(withIdentifier: MemoViewController.identifier) as? MemoViewController else { return }
            memoVC.addMemo = Laps.laps[indexPath.row]
            memoVC.row = indexPath.row
            memoVC.modalPresentationStyle = .fullScreen
            self.present(memoVC, animated: true)
        }
        
    }
}
