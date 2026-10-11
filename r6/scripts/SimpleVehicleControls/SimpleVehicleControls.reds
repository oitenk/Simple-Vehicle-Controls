// Simple Vehicle Controls: one key each for the doors, windows, hood and trunk of
// the car you are in, or the one you are looking at. The keys are set in Mod Settings.
module SimpleVehicleControls

public class SVCSettings {
  @runtimeProperty("ModSettings.mod", "Simple Vehicle Controls")
  @runtimeProperty("ModSettings.category", "Key Bindings")
  @runtimeProperty("ModSettings.displayName", "Hood open / close")
  public let hoodKey: EInputKey = EInputKey.IK_NumPad8;

  @runtimeProperty("ModSettings.mod", "Simple Vehicle Controls")
  @runtimeProperty("ModSettings.category", "Key Bindings")
  @runtimeProperty("ModSettings.displayName", "Trunk open / close")
  public let trunkKey: EInputKey = EInputKey.IK_NumPad5;

  @runtimeProperty("ModSettings.mod", "Simple Vehicle Controls")
  @runtimeProperty("ModSettings.category", "Key Bindings")
  @runtimeProperty("ModSettings.displayName", "Left door open / close")
  public let leftDoorKey: EInputKey = EInputKey.IK_NumPad4;

  @runtimeProperty("ModSettings.mod", "Simple Vehicle Controls")
  @runtimeProperty("ModSettings.category", "Key Bindings")
  @runtimeProperty("ModSettings.displayName", "Right door open / close")
  public let rightDoorKey: EInputKey = EInputKey.IK_NumPad6;

  @runtimeProperty("ModSettings.mod", "Simple Vehicle Controls")
  @runtimeProperty("ModSettings.category", "Key Bindings")
  @runtimeProperty("ModSettings.displayName", "Left window up / down")
  public let leftWindowKey: EInputKey = EInputKey.IK_NumPad7;

  @runtimeProperty("ModSettings.mod", "Simple Vehicle Controls")
  @runtimeProperty("ModSettings.category", "Key Bindings")
  @runtimeProperty("ModSettings.displayName", "Right window up / down")
  public let rightWindowKey: EInputKey = EInputKey.IK_NumPad9;
}

public class SVCSystem extends ScriptableSystem {
  private let m_settings: ref<SVCSettings>;
  // The game does not say where a window is, so the ones put down are remembered here.
  private let m_leftWindowsDown: array<EntityID>;
  private let m_rightWindowsDown: array<EntityID>;

  private func OnAttach() -> Void {
    this.m_settings = new SVCSettings();
    SVC_RegisterSettings(this.m_settings);
    GameInstance.GetCallbackSystem()
      .RegisterCallback(n"Input/Key", this, n"OnKeyInput")
      .SetLifetime(CallbackLifetime.Forever);
  }

  private func OnDetach() -> Void {
    SVC_UnregisterSettings(this.m_settings);
  }

  protected cb func OnKeyInput(event: ref<KeyInputEvent>) -> Void {
    if !Equals(event.GetAction(), EInputAction.IACT_Press) { return; }
    let key: EInputKey = event.GetKey();
    if Equals(key, EInputKey.IK_None) { return; }
    let s: ref<SVCSettings> = this.m_settings;
    if !Equals(key, s.hoodKey) && !Equals(key, s.trunkKey) && !Equals(key, s.leftDoorKey)
        && !Equals(key, s.rightDoorKey) && !Equals(key, s.leftWindowKey) && !Equals(key, s.rightWindowKey) {
      return;
    }
    let game: GameInstance = this.GetGameInstance();
    if this.IsInMenu(game) { return; }
    let vehicle: ref<VehicleObject> = this.FindVehicle(game);
    if !IsDefined(vehicle) { return; }

    if Equals(key, s.hoodKey) { this.ToggleDoor(vehicle, EVehicleDoor.hood, n"hood"); }
    if Equals(key, s.trunkKey) { this.ToggleDoor(vehicle, EVehicleDoor.trunk, n"trunk"); }
    if Equals(key, s.leftDoorKey) { this.ToggleDoor(vehicle, EVehicleDoor.seat_front_left, n"seat_front_left"); }
    if Equals(key, s.rightDoorKey) { this.ToggleDoor(vehicle, EVehicleDoor.seat_front_right, n"seat_front_right"); }
    if Equals(key, s.leftWindowKey) { this.ToggleWindow(vehicle, true); }
    if Equals(key, s.rightWindowKey) { this.ToggleWindow(vehicle, false); }
  }

  // Not while a menu or photo mode is up, so typing in a menu does nothing to the car.
  private func IsInMenu(game: GameInstance) -> Bool {
    let defs: ref<AllBlackboardDefinitions> = GetAllBlackboardDefs();
    let boards: ref<BlackboardSystem> = GameInstance.GetBlackboardSystem(game);
    let ui: ref<IBlackboard> = boards.Get(defs.UI_System);
    if IsDefined(ui) && ui.GetBool(defs.UI_System.IsInMenu) { return true; }
    let photo: ref<IBlackboard> = boards.Get(defs.PhotoMode);
    return IsDefined(photo) && photo.GetBool(defs.PhotoMode.IsActive);
  }

  // The vehicle the player is in, or failing that the one they are looking at.
  private func FindVehicle(game: GameInstance) -> ref<VehicleObject> {
    let player: ref<PlayerPuppet> = GetPlayer(game);
    if !IsDefined(player) { return null; }
    let mounted: ref<VehicleObject> = GetMountedVehicle(player);
    if IsDefined(mounted) { return mounted; }
    return GameInstance.GetTargetingSystem(game).GetLookAtObject(player, true, false) as VehicleObject;
  }

  private func ToggleDoor(vehicle: ref<VehicleObject>, door: EVehicleDoor, slot: CName) -> Void {
    let ps: ref<VehicleComponentPS> = vehicle.GetVehiclePS();
    if !IsDefined(ps) { return; }
    if Equals(ps.GetDoorState(door), VehicleDoorState.Open) {
      let component: ref<VehicleComponent> = vehicle.GetVehicleComponent();
      if !IsDefined(component) { return; }
      let evt: ref<VehicleDoorClose> = new VehicleDoorClose();
      evt.slotID = slot;
      GameInstance.GetPersistencySystem(vehicle.GetGame()).QueuePSEvent(ps.GetID(), ps.GetClassName(), evt);
    } else {
      let slotID: MountingSlotId;
      slotID.id = slot;
      VehicleComponent.OpenDoor(vehicle, slotID);
    }
  }

  // Windows are a part animation: state 1 puts the window down, 3 puts it up.
  private func ToggleWindow(vehicle: ref<VehicleObject>, left: Bool) -> Void {
    let id: EntityID = vehicle.GetEntityID();
    let down: Bool;
    if left {
      down = !ArrayContains(this.m_leftWindowsDown, id);
      if down { ArrayPush(this.m_leftWindowsDown, id); } else { ArrayRemove(this.m_leftWindowsDown, id); }
    } else {
      down = !ArrayContains(this.m_rightWindowsDown, id);
      if down { ArrayPush(this.m_rightWindowsDown, id); } else { ArrayRemove(this.m_rightWindowsDown, id); }
    }
    let animFeature: ref<AnimFeature_PartData> = new AnimFeature_PartData();
    animFeature.state = down ? 1 : 3;
    animFeature.duration = 1.3;
    AnimationControllerComponent.ApplyFeatureToReplicate(vehicle, left ? n"seat_front_left_window" : n"seat_front_right_window", animFeature);
  }
}

@if(ModuleExists("ModSettingsModule"))
func SVC_RegisterSettings(settings: ref<SVCSettings>) -> Void {
  ModSettings.RegisterListenerToClass(settings);
}

@if(!ModuleExists("ModSettingsModule"))
func SVC_RegisterSettings(settings: ref<SVCSettings>) -> Void {}

@if(ModuleExists("ModSettingsModule"))
func SVC_UnregisterSettings(settings: ref<SVCSettings>) -> Void {
  ModSettings.UnregisterListenerToClass(settings);
}

@if(!ModuleExists("ModSettingsModule"))
func SVC_UnregisterSettings(settings: ref<SVCSettings>) -> Void {}
