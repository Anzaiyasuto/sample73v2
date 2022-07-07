//
//  InfoViewController.swift
//  sample73v2
//
//  Created by AnzaiYasuto al18011 on 2022/07/07.
//


import UIKit
class InfoViewController: UIView {
    var view : UIView!

    @IBOutlet weak var UILabel1: UILabel!

    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    func loadView() -> InfoViewController{
        let seismographInfoView = Bundle.main.loadNibNamed("InfoView", owner: self, options: nil)?[0] as! InfoViewController
        return seismographInfoView
    }
    func infoViewText(text1: String){
        UILabel1.text =  text1
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
