//
//  PVEmulatorViewController.swift
//  Provenance
//
//  Created by Joe Mattiello on 2/13/2018.
//  Copyright (c) 2018 Joe Mattiello. All rights reserved.
//

extension PVEmulatorViewController {
    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        //Notifies UIKit that your view controller updated its preference regarding the visual indicator
        
        #if os(iOS)
        if #available(iOS 11.0, *) {
            setNeedsUpdateOfHomeIndicatorAutoHidden()
        }
        #endif
    }
    
    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        #if os(iOS)
        stopVolumeControl()
        #endif
    }
    
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        #if os(iOS)
            startVolumeControl()
            UIApplication.shared.setStatusBarHidden(true, with: .fade)
        #endif
    }
    
    @objc
    public func finishedPlaying(game : PVGame) {
        guard let startTime = game.lastPlayed else {
            return
        }
        
        let duration = startTime.timeIntervalSinceNow * -1
        let totalTimeSpent = game.timeSpentInGame + Int(duration)

        do {
            try RomDatabase.sharedInstance.writeTransaction {
                game.timeSpentInGame = totalTimeSpent
            }
        } catch {
            ELOG("\(error.localizedDescription)")
        }
        
    }
}

public extension PVEmulatorViewController {
    @objc
    func showSwapDiscsMenu() {
        guard let emulatorCore = self.emulatorCore else {
            ELOG("No core?")
            return
        }
        
        let numberOfDiscs = emulatorCore.discCount
        guard numberOfDiscs > 1 else {
            ELOG("Only 1 disc?")
            return
        }
        
        // Add action for each disc
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        for index in 1...numberOfDiscs {
            actionSheet.addAction(UIAlertAction(title: "\(index)", style: .default, handler: {[unowned self] (sheet) in

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
                    emulatorCore.swapDisc(index)
                })
                
                emulatorCore.setPauseEmulation(false)

                self.isShowingMenu = false
                #if os(tvOS)
                    self.controllerUserInteractionEnabled = false
                #endif
            }))
        }

        // Add cancel action
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: {[unowned self] (sheet) in
            emulatorCore.setPauseEmulation(false)
            self.isShowingMenu = false
            #if os(tvOS)
                self.controllerUserInteractionEnabled = false
            #endif
        }))

        // Present
        self.present(actionSheet, animated: true) {
            PVControllerManager.shared().iCadeController?.refreshListener()
        }
    }
}

// Inherits the default behaviour
#if os(iOS)
extension PVEmulatorViewController : VolumeController {
    
}
#endif