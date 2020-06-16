//
//  GoalsVc.swift
//  Goal Post
//
//  Created by Prabhat  on 15/06/20.
//  Copyright © 2020 Defenders. All rights reserved.
//

import UIKit
import CoreData

let appDelegate = UIApplication.shared.delegate as? AppDelegate


class GoalsVc: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var undoView: UIView!
    
    var goals: [Goal] = []
    var removedGoalDescription: String?
    var removeGoalType: String?
    var removedGoalCompletionValue: Int32?
    var removedGoalProgress: Int32?

    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.isHidden = false
        undoView.isHidden = true
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setUpTableView()
    }
    
    func setUpTableView() {
        fetchCoreDataObjects()
        tableView.reloadData()
    }
    
    func fetchCoreDataObjects() {
        self.fetch { (complete) in
            if complete {
                if goals.count >= 1 {
                    tableView.isHidden = false
                } else {
                    tableView.isHidden = true
                }
            }
        }
    }


    @IBAction func addGoalBtnWasPressed(_ sender: Any) {
        guard let createGoalVC = storyboard?.instantiateViewController(identifier: "CreateGoalVC") else {
            return }
        presentDetail(createGoalVC)
    }
    @IBAction func undoBtnWasPressed(_ sender: Any) {
        guard let managedContext = appDelegate?.persistentContainer.viewContext else {
            return
        }
        let oldGoal = Goal(context: managedContext)
        oldGoal.goalDescription = removedGoalDescription
        oldGoal.goalType = removeGoalType
        oldGoal.goalCompletionValue = removedGoalCompletionValue!
        oldGoal.goalProgress = removedGoalProgress!
        
        do {
            try managedContext.save()
            undoView.isHidden = true
            setUpTableView()
            print("Successfully undo'd")
        } catch  {
            debugPrint("Could not undo \(error.localizedDescription)")
        }
    }
}

extension GoalsVc: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return goals.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "goalCell") as? GoalCell else {return UITableViewCell() }
        let goal = goals[indexPath.row]
        cell.configureCell(goal: goal)
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return UITableViewCell.EditingStyle.none
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let deleteAction = UITableViewRowAction(style: .destructive, title: "Delete") { (rowAction, indexPath) in
            self.removeGoal(atIndexPath: indexPath)
            self.fetchCoreDataObjects()
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
        
        let addAction = UITableViewRowAction(style: .normal, title: "Add") { (rowAction, indexPath) in
            self.setProgress(atIndexPath: indexPath)
            tableView.reloadRows(at: [indexPath], with: .automatic)
        }
        
        deleteAction.backgroundColor = #colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 1)
        addAction.backgroundColor = #colorLiteral(red: 0.9529411793, green: 0.6862745285, blue: 0.1333333403, alpha: 1)
        
        return [deleteAction, addAction]
    }
    
    
}

extension GoalsVc {
    func setProgress(atIndexPath indexPath: IndexPath) {
        guard let managedContext = appDelegate?.persistentContainer.viewContext else {
            return
        }
        
        let chosenGoal = goals[indexPath.row]
        
        if chosenGoal.goalProgress < chosenGoal.goalCompletionValue {
            chosenGoal.goalProgress = chosenGoal.goalProgress + 1
        } else {
            return
        }
        
        do {
            try managedContext.save()
            print("Successfully set Progress")
        } catch {
            debugPrint("Could not set Progress \(error.localizedDescription)")
        }
    }
    
    func removeGoal(atIndexPath indexPath: IndexPath) {
        guard let managedContext = appDelegate?.persistentContainer.viewContext else {
            return
        }
        
        let delGoal = goals[indexPath.row]
        removedGoalDescription = delGoal.goalDescription
        removeGoalType = delGoal.goalType
        removedGoalCompletionValue = delGoal.goalCompletionValue
        removedGoalProgress = delGoal.goalProgress
        
        managedContext.delete(goals[indexPath.row])
        
        do {
            try managedContext.save()
            undoView.isHidden = false
            Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(hideLabel), userInfo: nil, repeats: false)
            print("Successfully removed goal!")
        } catch {
            debugPrint("Could not remove \(error.localizedDescription)")
        }
    }
    
    @objc func hideLabel() {
        undoView.isHidden = true
    }
    
    func fetch(completion: (_ Complete: Bool) -> ()) {
        guard let managedContext = appDelegate?.persistentContainer.viewContext else {
            return
        }
        
        let fetchRequest = NSFetchRequest<Goal>(entityName: "Goal")
        
        do {
            goals = try managedContext.fetch(fetchRequest)
            print("Successfully fetched data")
            completion(true)
        } catch {
            debugPrint("Could not fetch \(error.localizedDescription)")
            completion(false)
        }
    }
}

