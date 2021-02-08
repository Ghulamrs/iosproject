//
//  MemberViewCell.swift
//  Explorer
//
//  Created by Home on 3/19/20.
//  Copyright © 2020 Home. All rights reserved.
//

import UIKit

class MemberViewCell: UITableViewCell {
    lazy var backView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: 50))
        return view
    }()
    lazy var icons: UIImageView = {
        let view = UIImageView(frame: CGRect(x: 15, y: 10, width: 30, height: 30))
        view.contentMode = .scaleAspectFit
        return view
    }()
    lazy var label: UILabel = {
        let view = UILabel(frame: CGRect(x: 60, y: 10, width: self.frame.width-80, height: 30))
        view.font = UIFont.preferredFont(forTextStyle: .title2)
        return view
    }()
    lazy var option: UILabel = {
        let view = UILabel(frame: CGRect(x: self.frame.width-50, y: 10, width: 50, height: 30))
        view.font = UIFont.preferredFont(forTextStyle: .footnote)
        view.textColor = UIColor(red: 0.85, green: 0, blue: 0, alpha: 1)
        return view
    }()

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        addSubview(backView)
        backView.addSubview(icons)
        backView.addSubview(label)
        backView.addSubview(option)
    }
}
