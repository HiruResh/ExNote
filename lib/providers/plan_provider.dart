// lib/providers/plan_provider.dart (FIXED: Dependency Injection)

import 'package:flutter/material.dart';
import 'package:exnote/models/plan.dart';
import 'package:exnote/models/plan_item.dart';
import 'package:exnote/services/plan_service.dart';
import 'package:exnote/services/database_service.dart'; // Needed for the constructor argument

class PlanProvider with ChangeNotifier {
  // FIX 1: Change to late final or initialize in the constructor list
  final PlanService _planService;

  List<Plan> _allPlans = [];
  Plan? _activePlan;
  List<PlanItem> _activePlanItems = [];

  List<Plan> get allPlans => _allPlans;
  Plan? get activePlan => _activePlan;
  List<PlanItem> get activePlanItems => _activePlanItems;

  // FIX 2: Define a constructor that accepts DatabaseService and initializes the service
  PlanProvider(DatabaseService dbService)
    : _planService = PlanService(dbService) {
    // Assuming PlanService requires dbService
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    await _loadPlans();
    await _loadActivePlan();
  }

  Future<void> _loadPlans() async {
    _allPlans = await _planService.readAllPlans();
    notifyListeners();
  }

  Future<void> _loadActivePlan() async {
    _activePlan = await _planService.readActivePlan();
    if (_activePlan != null) {
      _activePlanItems = await _planService.readPlanItems(_activePlan!.id!);
    } else {
      _activePlanItems = [];
    }
    notifyListeners();
  }

  // --- Plan CRUD/Actions ---

  Future<void> addPlan(Plan plan, List<PlanItem> items) async {
    final planId = await _planService.createPlan(plan);
    for (var item in items) {
      await _planService.createPlanItem(item.copyWith(planId: planId));
    }
    await _loadPlans();
  }

  Future<void> deletePlan(int id) async {
    await _planService.deletePlan(id);
    await _loadPlans();
    if (_activePlan?.id == id) {
      _activePlan = null;
      _activePlanItems = [];
    }
    notifyListeners();
  }

  Future<void> updatePlan(Plan plan) async {
    await _planService.updatePlan(plan);
    await _loadPlans();
    // If the active plan was updated, reload active data
    if (_activePlan?.id == plan.id) {
      await _loadActivePlan();
    }
  }

  Future<void> activatePlan(Plan plan) async {
    // 1. Deactivate any currently active plan (database logic should handle this well)
    // For simplicity, we'll ensure only one is active at the provider level for now.
    final currentlyActive = _allPlans.firstWhere(
      (p) => p.isActive,
      orElse: () => plan.copyWith(
        isActive: false,
        id: -1,
      ), // Return a dummy, non-active plan if none found
    );

    if (currentlyActive.id != plan.id && currentlyActive.isActive) {
      await _planService.updatePlan(currentlyActive.copyWith(isActive: false));
    }

    // 2. Activate the new plan
    await _planService.updatePlan(plan.copyWith(isActive: true));
    await _loadAllData();
  }

  // --- PlanItem CRUD/Actions (Active Plan Only) ---

  Future<void> addPlanItem(PlanItem item) async {
    await _planService.createPlanItem(item);
    await _loadActivePlan();
  }

  Future<void> updatePlanItem(PlanItem item) async {
    await _planService.updatePlanItem(item);
    await _loadActivePlan();
  }

  Future<void> deletePlanItem(int id) async {
    await _planService.deletePlanItem(id);
    await _loadActivePlan();
  }

  Future<void> updateItemOrder(int planId, List<PlanItem> items) async {
    // Reorder and update displayOrder field
    for (int i = 0; i < items.length; i++) {
      await _planService.updatePlanItem(items[i].copyWith(displayOrder: i));
    }
    await _loadActivePlan();
  }
}
