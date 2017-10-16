//
//  ViewController.swift
//  TemplateLayoutDemo
//
//  Created by zhaodg on 11/26/15.
//  Copyright © 2015 zhaodg. All rights reserved.
//

import UIKit

class ViewController: UITableViewController {

    var feedList: [[DGFeedItem]] = []
    var jsonData: [DGFeedItem] = []

    @IBOutlet weak var cacheModeSegmentControl: UISegmentedControl!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.dg_debugLogEnabled = true

        self.cacheModeSegmentControl.selectedSegmentIndex = 1
        
        DispatchQueue.global().async {
            let path: String = Bundle.main.path(forResource: "Data", ofType: "json")!
            let data: NSData = NSData(contentsOfFile: path)!
            do {
                let dict = try JSONSerialization.jsonObject(with: data as Data, options: .allowFragments) as! [String: Any]
                let array: [AnyObject] = dict["feed"] as! [AnyObject]
                for item in array {
                    if let item = item as? NSDictionary {
                        self.jsonData.append(DGFeedItem(dict: item))
                    }
                }
            } catch {
                print("serialization failed!!!")
            }
            DispatchQueue.main.async {
                self.feedList.append(self.jsonData)
                self.tableView.reloadData()
            }
        }
    }
    
    func delay(delay: Double, closure: @escaping () -> ()) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            closure()
        }
    }

    @IBAction func refreshControlAction(sender: UIRefreshControl) {
        delay(delay: 1 * Double(NSEC_PER_SEC)) {
            self.feedList.removeAll()
            self.feedList.append(self.jsonData)
            self.tableView.reloadData()
            sender.endRefreshing()
        }
    }

    @IBAction func rightNavigationItemAction(sender: AnyObject) {
        let alert = UIAlertController(title: "Action", message: "message", preferredStyle: .actionSheet)
        alert.modalPresentationStyle = .popover
        let action1 = UIAlertAction(title: "Insert a row", style: .destructive) { action in
            self.inserRow()
        }
        let action2 = UIAlertAction(title: "Insert a section", style: .destructive) { action in
            self.insertSection()
        }
        let action3 = UIAlertAction(title: "Delete a section", style: .destructive) { action in
            self.deleteSection()
        }
        let action4 = UIAlertAction(title: "Insert Rows At Index Paths", style: .destructive) { action in
            self.insertRowsAtIndexPaths()
        }
        let action5 = UIAlertAction(title: "Delete Rows At Index Paths", style: .destructive) { action in
            self.deleteRowsAtIndexPaths()
        }

        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { action in

        }

        alert.addAction(cancel)
        alert.addAction(action1)
        alert.addAction(action2)
        alert.addAction(action3)
        alert.addAction(action4)
        alert.addAction(action5)

        self.present(alert, animated: true, completion: nil)
    }

    func randomItem() -> DGFeedItem {
        let randomNumber: Int = Int(arc4random_uniform(UInt32(self.jsonData.count)))
        var item: DGFeedItem = self.jsonData[randomNumber]
        countDGFeedItemIdentifier += 1
        item.identifier = "unique-id-\(countDGFeedItemIdentifier)"
        return item
    }

    func inserRow() {
        if self.feedList.count == 0 {
            self.insertSection()
        } else {
            self.feedList[0].insert(self.randomItem(), at: 0)
            let indexPath: IndexPath = IndexPath(row: 0, section: 0)
            self.tableView.insertRows(at: [indexPath], with: .automatic)
        }
    }

    func insertSection() {
        self.feedList.insert([self.randomItem()], at: 0)
        self.tableView.insertSections(IndexSet(integer: 0) as IndexSet, with: .automatic)
    }

    func deleteSection() {
        if self.feedList.count > 0 {
            self.feedList.remove(at: 0)
            self.tableView.deleteSections(IndexSet(integer: 0) as IndexSet, with: .automatic)
        }
    }

    func insertRowsAtIndexPaths() {
        // demo 以section 0 为例子
        let section = 0
        if self.feedList.count == 0 {
            self.feedList.append([])
        }
        let lastIndex = self.feedList[section].count
        let insertItems = [self.randomItem(), self.randomItem(), self.randomItem(), self.randomItem(), self.randomItem()]
        for item in insertItems {
            self.feedList[section].append(item)
        }

        var indexPaths: [IndexPath] = []
        for index in 0..<insertItems.count {
            indexPaths.append(IndexPath(row: lastIndex + index, section: section))
        }

        self.tableView.beginUpdates()
        if self.tableView.numberOfSections < section + 1 {
            self.tableView.insertSections(IndexSet(integer: section), with: .automatic)
        } else {
            self.tableView.insertRows(at: indexPaths as [IndexPath], with: .automatic)
        }
        self.tableView.endUpdates()
    }

    func deleteRowsAtIndexPaths() {
        // demo 以section 0 为例子
        let section = 0
        guard self.feedList.count > section + 1 && self.feedList[section].count > 0 else { return }

        let row = self.feedList[section].count - 1
        let indexPath = IndexPath(row: row, section: section)
        self.feedList[section].removeLast()

        guard self.tableView.numberOfSections > section + 1 else { return }

        self.tableView.beginUpdates()
        if self.tableView.numberOfRows(inSection: section) > 1 {
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
        } else {
            self.feedList.remove(at: section)
            self.tableView.deleteSections(IndexSet(integer: section), with: .automatic)
        }
        self.tableView.endUpdates()
    }
}

// MARK: - UITableViewDelegate
extension ViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.feedList.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: DGFeedCell = tableView.dequeueReusableCell(withIdentifier: "DGFeedCell", for: indexPath as IndexPath) as! DGFeedCell
        if indexPath.row % 2 == 0 {
            cell.accessoryType = UITableViewCellAccessoryType.disclosureIndicator
        } else {
            cell.accessoryType = UITableViewCellAccessoryType.checkmark
        }
        cell.loadData(item: self.feedList[indexPath.section][indexPath.row])
        cell.setNeedsUpdateConstraints()
        cell.updateConstraintsIfNeeded()
        return cell
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.feedList[section].count
    }
}

// MARK: - UITableViewDelegate
extension ViewController {
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let mode: Int = self.cacheModeSegmentControl.selectedSegmentIndex
        switch mode {
        case 0:
            return tableView.dg_heightForCellWithIdentifier(identifier: "DGFeedCell", configuration: { (cell) -> Void in
                let cell = cell as! DGFeedCell
                cell.loadData(item: self.feedList[indexPath.section][indexPath.row])
            })
        case 1:
            return tableView.dg_heightForCellWithIdentifier(identifier: "DGFeedCell", indexPath: indexPath, configuration: { (cell) in
                let cell = cell as! DGFeedCell
                cell.loadData(item: self.feedList[indexPath.section][indexPath.row])
            })
        case 2:
            return tableView.dg_heightForCellWithIdentifier(identifier: "DGFeedCell", key: self.feedList[indexPath.section][indexPath.row].identifier, configuration: { (cell) in
                let cell = cell as! DGFeedCell
                cell.loadData(item: self.feedList[indexPath.section][indexPath.row])
            })
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == UITableViewCellEditingStyle.delete {
            self.feedList[indexPath.section].remove(at: indexPath.row)
            self.tableView.deleteRows(at: [indexPath as IndexPath], with: .automatic)
        }
    }
}



