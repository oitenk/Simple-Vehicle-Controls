// Simple Vehicle Controls: what the buttons do to the vehicle.
module SimpleVehicleControls

// Text from the mod's localization, in the language the game is set to.
func SVC_Text(key: String) -> String {
  let text: String = GetLocalizedTextByKey(StringToName(key));
  return Equals(text, "") || Equals(text, key) ? key : text;
}

public abstract class SVCActions {
  public static func IsDoorOpen(vehicle: ref<VehicleObject>, door: EVehicleDoor) -> Bool {
    let ps: ref<VehicleComponentPS> = vehicle.GetVehiclePS();
    return IsDefined(ps) && Equals(ps.GetDoorState(door), VehicleDoorState.Open);
  }

  public static func SetDoor(vehicle: ref<VehicleObject>, slot: CName, open: Bool) -> Void {
    if !IsDefined(vehicle) { return; }
    if open {
      let slotID: MountingSlotId;
      slotID.id = slot;
      VehicleComponent.OpenDoor(vehicle, slotID);
    } else {
      let vc: ref<VehicleComponent> = vehicle.GetVehicleComponent();
      if !IsDefined(vc) { return; }
      let ps: ref<VehicleComponentPS> = vc.GetPS();
      if !IsDefined(ps) { return; }
      let evt: ref<VehicleDoorClose> = new VehicleDoorClose();
      evt.slotID = slot;
      GameInstance.GetPersistencySystem(vehicle.GetGame()).QueuePSEvent(ps.GetID(), ps.GetClassName(), evt);
    }
  }

  // Windows are a part animation: state 1 opens, 3 closes.
  public static func SetWindow(vehicle: ref<VehicleObject>, slot: CName, down: Bool) -> Void {
    if !IsDefined(vehicle) { return; }
    let animFeature: ref<AnimFeature_PartData> = new AnimFeature_PartData();
    animFeature.state = down ? 1 : 3;
    animFeature.duration = 1.3;
    AnimationControllerComponent.ApplyFeatureToReplicate(vehicle, slot, animFeature);
  }

  public static func SetEngine(vehicle: ref<VehicleObject>, on: Bool) -> Void {
    if IsDefined(vehicle) {
      vehicle.TurnEngineOn(on);
    }
  }

  // The engine start can switch the headlights on; put them back off.
  public static func HeadlightsOff(vehicle: ref<VehicleObject>) -> Void {
    let component: ref<VehicleComponent> = vehicle.GetVehicleComponent();
    if !IsDefined(component) { return; }
    let ctrlPS: ref<vehicleControllerPS> = component.GetVehicleControllerPS();
    let controller: ref<vehicleController> = component.GetVehicleController();
    if IsDefined(ctrlPS) {
      ctrlPS.SetHeadLightMode(vehicleELightMode.Off);
    }
    if IsDefined(controller) {
      controller.ToggleLights(false, vehicleELightType.Head);
    }
  }

  // The vehicle the player is in, or failing that the one they are looking at.
  public static func FindVehicle(game: GameInstance) -> ref<VehicleObject> {
    let player: ref<PlayerPuppet> = GetPlayer(game);
    if !IsDefined(player) { return null; }
    let mounted: ref<VehicleObject> = GetMountedVehicle(player);
    if IsDefined(mounted) { return mounted; }
    return GameInstance.GetTargetingSystem(game).GetLookAtObject(player, true, false) as VehicleObject;
  }
}
