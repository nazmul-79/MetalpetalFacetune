//
//  TuneOptionCollectionViewCell.swift
//  MultipleImageBlendUsingMetal
//
//  Created by BCL Device 8 on 14/8/25.
//

import UIKit

class TuneOptionCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var tuneOptionNameLabel: UILabel!
    
    static let cellID = "TuneOptionCollectionViewCell"
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    public func setName(name: String) {
        tuneOptionNameLabel.text = name
    }

}
