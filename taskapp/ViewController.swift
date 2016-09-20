//
//  ViewController.swift
//  taskapp
//
//  Created by MASATO YOSHIDA on 2016/09/14.
//  Copyright © 2016年 ThanksThankyou. All rights reserved.
//

import UIKit
import RealmSwift

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    // Realmインスタンスを取得する
    let realm = try! Realm() // ←追加
    
    // DB内のタスクが格納されるリスト。
    // 日付近い順でソート:降順
    // 以降内容をアップデートするとリスト内は自動的に更新される
    let taskArray = try! Realm().objects(Task).sorted("date", ascending: false) // ←追加
    
    var searchResult: Results<Task>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // デリゲート先を自分に設定する
        searchBar.delegate = self
        
        // 何も入力されていないくてもReturnキーを押せるようにする
        searchBar.enablesReturnKeyAutomatically = false
        
        // 検索結果配列にデータをコピーする
        searchResult = taskArray
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // 検索ボタン押下時の呼び出しメソッド
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        searchBar.endEditing(true)
        
        if(searchBar.text == "") {
            // 検索文字列が空の場合は全てを表示する
            searchResult = taskArray
            
        } else {
            // 検索文字列を含むデータを検索結果配列に追加する
            searchResult = realm.objects(Task).filter("category CONTAINS[c] '\(searchBar.text!)'")
            
        }
        
        print("\(searchResult)")
        
        // テーブルビューを再読み込みする
        tableView.reloadData()
    }
    
    // MARK: UITableViewDataSourceプロトコルのメソッド
    // データの数（=セルの数）を返すメソッド
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResult!.count  // ←追加する
    }
    
    // 各セルの内容を返すメソッド
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        // 再利用可能なcellを得る
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
        
        // Cellに値を設定する
        let titleLabel = cell.viewWithTag(100) as! UILabel
        let subtitleLabel = cell.viewWithTag(101) as! UILabel
        let categoryLabel = cell.viewWithTag(102) as! UILabel

        let task = searchResult![indexPath.row]
        titleLabel.text = task.title
        
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"

        let dateString:String = formatter.stringFromDate(task.date)
        subtitleLabel.text = dateString
        
        categoryLabel.text = task.category
        
        return cell
    }
    
    // MARK: UITableViewDelegateプロトコルのメソッド
    // 各セルを選択した時に実行されるメソッド
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        performSegueWithIdentifier("cellSegue", sender: nil) // ←追加する
    }
    
    // セルが削除可能なことを伝えるメソッド
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return UITableViewCellEditingStyle.Delete
    }
    
    // Deleteボタンが押された時に呼ばれるメソッド
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == UITableViewCellEditingStyle.Delete {
        
            // ローカル通知をキャンセルする
            let task = searchResult![indexPath.row]
            
            for notification in UIApplication.sharedApplication().scheduledLocalNotifications! {
                if notification.userInfo!["id"] as! Int == task.id {
                    UIApplication.sharedApplication().cancelLocalNotification(notification)
                    break
                }
            }
            
            // データベースから削除する
            try! realm.write {
                self.realm.delete(self.searchResult![indexPath.row])
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Fade)
            }
        }
    }
    
    // segueで画面遷移する時に呼ばれる
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let inputViewController:InputViewController = segue.destinationViewController as! InputViewController
        
        if segue.identifier == "cellSegue" {
            let indexPath = self.tableView.indexPathForSelectedRow
            inputViewController.task = searchResult![indexPath!.row]
        } else {
            let task = Task()
            task.date = NSDate()
            
            if taskArray.count != 0 {
                task.id = taskArray.max("id")!+1
            }
            
            inputViewController.task = task
        }
    }

    // 入力画面から戻ってきた時にTableViewを更新させる
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
}