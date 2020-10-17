//
//  ViewController.swift
//  taskapp
//
//  Created by Hiromichi Aoki on 10/10/20.
//

import UIKit
import RealmSwift
import UserNotifications

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {


    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    
    var task: Task!
    
    // Realmインスタンスを取得する
        let realm = try! Realm()  // ←追加
        // DB内のタスクが格納されるリスト。
        // 日付の近い順でソート：昇順
        // 以降内容をアップデートするとリスト内は自動的に更新される。
        var taskArray = try! Realm().objects(Task.self).sorted(byKeyPath: "date", ascending: true)  // ←追加

  
    

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        searchBar.delegate = self
    }

    // segue で画面遷移する時に呼ばれる
        override func prepare(for segue: UIStoryboardSegue, sender: Any?){
            let inputViewController:InputViewController = segue.destination as! InputViewController

            if segue.identifier == "cellSegue" {
                let indexPath = self.tableView.indexPathForSelectedRow
                inputViewController.task = taskArray[indexPath!.row]
            } else {
                let task = Task()

                let allTasks = realm.objects(Task.self)
                if allTasks.count != 0 {
                    task.id = allTasks.max(ofProperty: "id")! + 1
                }

                inputViewController.task = task
            }
        }
    
    // 入力画面から戻ってきた時に TableView を更新させる
        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            tableView.reloadData()
        }
    
    
    // データの数（＝セルの数）を返すメソッド
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return taskArray.count
        }

        // 各セルの内容を返すメソッド
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            // 再利用可能な cell を得る
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            
            // Cellに値を設定する.
                   let task = taskArray[indexPath.row]
            cell.textLabel?.text = task.title
                   let formatter = DateFormatter()
                   formatter.dateFormat = "yyyy-MM-dd HH:mm"
                   let dateString:String = formatter.string(from: task.date)
                   cell.detailTextLabel?.text = dateString
            
            return cell
        }

        // 各セルを選択した時に実行されるメソッド
        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            performSegue(withIdentifier: "cellSegue",sender: nil)
        }

        // セルが削除が可能なことを伝えるメソッド
        func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath)-> UITableViewCell.EditingStyle {
            return .delete
        }

        // Delete ボタンが押された時に呼ばれるメソッド
        func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
            
            if editingStyle == .delete {
                // 削除するタスクを取得する
                            let task = self.taskArray[indexPath.row]

                            // ローカル通知をキャンセルする
                            let center = UNUserNotificationCenter.current()
                            center.removePendingNotificationRequests(withIdentifiers: [String(task.id)])
                       // データベースから削除する
                       try! realm.write {
                           self.realm.delete(task)
                           tableView.deleteRows(at: [indexPath], with: .fade)
                       }
                // 未通知のローカル通知一覧をログ出力
                            center.getPendingNotificationRequests { (requests: [UNNotificationRequest]) in
                                for request in requests {
                                    print("/---------------")
                                    print(request)
                                    print("---------------/")
                                }
                            }
                        }
                   }
    
    //MARK: Search Bar Config
        
    // 検索バー編集開始時にキャンセルボタン有効化
        func searchBarTextDidBeginEditing(_ searchBar: UISearchBar){
            searchBar.setShowsCancelButton(true, animated: true)
        }
    
    // キャンセルボタンでキャセルボタン非表示
       func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
           searchBar.resignFirstResponder()
           searchBar.setShowsCancelButton(false, animated: true)
        taskArray = realm.objects(Task.self)
        tableView.reloadData()
       }
        
    // エンターキーで検索
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar){
        searchBar.resignFirstResponder()
                searchBar.setShowsCancelButton(false, animated: true)
        
        let searchText = searchBar.text!
        
        //Search all the items.
        let predicate = NSPredicate(format: "category BEGINSWITH %@", searchText)
        let results = realm.objects(Task.self).filter(predicate).sorted(byKeyPath: "date", ascending: true)
         
        // 検索結果の件数を取得します。
           let count = results.count
           if (count == 0) {
               // 検索結果が0件の場合
            taskArray = realm.objects(Task.self)
           } else {
               // 検索データがある場合
            taskArray = results
           }
        tableView.reloadData()
}
    
    // 入力された文字出力
        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            print(searchText)
            if searchText == "" {
                    print("UISearchBar.text cleared!")
                taskArray = realm.objects(Task.self)
                tableView.reloadData()
                }
            
        }
    
        }
