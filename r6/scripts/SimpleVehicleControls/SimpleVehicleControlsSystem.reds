// Simple Vehicle Controls: the settings, the hotkeys, the memory of which windows
// were put down (the game does not say) and which engines were switched off.
module SimpleVehicleControls

public class SVCSettings {
  @runtimeProperty("ModSettings.mod", "Simple Vehicle Controls")
  @runtimeProperty("ModSettings.category", "Key Bindings")
  @runtimeProperty("ModSettings.displayName", "Open vehicle controls")
  @runtimeProperty("ModSettings.description", "Opens the vehicle controls panel for the car you are in, or the one you are looking at. Press it again to close.")
  public let openKey: EInputKey = EInputKey.IK_NumPad5;

  // The keys below act on the car you are in, or the one you are looking at.
  // None are bound until you choose a key.
  @runtimeProperty("ModSettings.mod", "Simple Vehicle Controls")
  @runtimeProperty("ModSettings.category", "Key Bindings")
  @runtimeProperty("ModSettings.displayName", "Engine on / off")
  public let engineKey: EInputKey = EInputKey.IK_None;

  @runtimeProperty("ModSettings.mod", "Simple Vehicle Controls")
  @runtimeProperty("ModSettings.category", "Key Bindings")
  @runtimeProperty("ModSettings.displayName", "Driver door open / close")
  public let driverDoorKey: EInputKey = EInputKey.IK_None;

  @runtimeProperty("ModSettings.mod", "Simple Vehicle Controls")
  @runtimeProperty("ModSettings.category", "Key Bindings")
  @runtimeProperty("ModSettings.displayName", "Passenger door open / close")
  public let passengerDoorKey: EInputKey = EInputKey.IK_None;

  @runtimeProperty("ModSettings.mod", "Simple Vehicle Controls")
  @runtimeProperty("ModSettings.category", "Key Bindings")
  @runtimeProperty("ModSettings.displayName", "Driver window down")
  public let driverWindowDownKey: EInputKey = EInputKey.IK_None;

  @runtimeProperty("ModSettings.mod", "Simple Vehicle Controls")
  @runtimeProperty("ModSettings.category", "Key Bindings")
  @runtimeProperty("ModSettings.displayName", "Driver window up")
  public let driverWindowUpKey: EInputKey = EInputKey.IK_None;

  @runtimeProperty("ModSettings.mod", "Simple Vehicle Controls")
  @runtimeProperty("ModSettings.category", "Key Bindings")
  @runtimeProperty("ModSettings.displayName", "Passenger window down")
  public let passengerWindowDownKey: EInputKey = EInputKey.IK_None;

  @runtimeProperty("ModSettings.mod", "Simple Vehicle Controls")
  @runtimeProperty("ModSettings.category", "Key Bindings")
  @runtimeProperty("ModSettings.displayName", "Passenger window up")
  public let passengerWindowUpKey: EInputKey = EInputKey.IK_None;

  @runtimeProperty("ModSettings.mod", "Simple Vehicle Controls")
  @runtimeProperty("ModSettings.category", "Key Bindings")
  @runtimeProperty("ModSettings.displayName", "Hood open / close")
  public let hoodKey: EInputKey = EInputKey.IK_None;

  @runtimeProperty("ModSettings.mod", "Simple Vehicle Controls")
  @runtimeProperty("ModSettings.category", "Key Bindings")
  @runtimeProperty("ModSettings.displayName", "Trunk open / close")
  public let trunkKey: EInputKey = EInputKey.IK_None;

  @runtimeProperty("ModSettings.mod", "Simple Vehicle Controls")
  @runtimeProperty("ModSettings.category", "Engine")
  @runtimeProperty("ModSettings.displayName", "Keep the engine off")
  @runtimeProperty("ModSettings.description", "When you switch an engine off here, switch it off again if something else turns it back on, until you turn it on here.")
  public let keepEngineOff: Bool = true;

  @runtimeProperty("ModSettings.mod", "Simple Vehicle Controls")
  @runtimeProperty("ModSettings.category", "Engine")
  @runtimeProperty("ModSettings.displayName", "Keep the engine running when you get out")
  @runtimeProperty("ModSettings.description", "A running engine stays running when you leave the car.")
  public let keepRunningOnExit: Bool = true;

  @runtimeProperty("ModSettings.mod", "Simple Vehicle Controls")
  @runtimeProperty("ModSettings.category", "Engine")
  @runtimeProperty("ModSettings.displayName", "Quiet start-up when held off")
  @runtimeProperty("ModSettings.description", "Gets rid of the engine start-up sound when you get into a car whose engine you switched off.")
  public let quietStart: Bool = true;

  @runtimeProperty("ModSettings.mod", "Simple Vehicle Controls")
  @runtimeProperty("ModSettings.category", "Debug")
  @runtimeProperty("ModSettings.displayName", "Debug logging")
  @runtimeProperty("ModSettings.description", "Writes extra lines to the Cyber Engine Tweaks log.")
  public let debug: Bool = false;
}

// Switches an engine off again, a few times in quick succession, because the
// game can start it more than once while the player gets in.
public class SVCEngineOffCallback extends DelayCallback {
  public let vehicle: wref<VehicleObject>;
  public let system: wref<SVCSystem>;
  public let repeats: Int32;
  public let interval: Float;

  public func Call() -> Void {
    if !IsDefined(this.vehicle) || !IsDefined(this.system) { return; }
    this.system.EngineOffIfHeld(this.vehicle);
    if this.repeats > 1 {
      let next: ref<SVCEngineOffCallback> = new SVCEngineOffCallback();
      next.vehicle = this.vehicle;
      next.system = this.system;
      next.repeats = this.repeats - 1;
      next.interval = this.interval;
      GameInstance.GetDelaySystem(this.vehicle.GetGame()).DelayCallback(next, this.interval, false);
    }
  }
}

// Puts remembered windows back down after the player gets in.
public class SVCWindowCallback extends DelayCallback {
  public let vehicle: wref<VehicleObject>;
  public let system: wref<SVCSystem>;

  public func Call() -> Void {
    if IsDefined(this.vehicle) && IsDefined(this.system) {
      this.system.ReapplyWindows(this.vehicle);
    }
  }
}

// Starts an engine again, if it should still be running.
public class SVCEngineOnCallback extends DelayCallback {
  public let vehicle: wref<VehicleObject>;
  public let system: wref<SVCSystem>;

  public func Call() -> Void {
    if IsDefined(this.vehicle) && IsDefined(this.system) {
      this.system.RestartIfLeft(this.vehicle);
    }
  }
}

// Keep the in-game menu controller, which the popup needs to show itself.
@wrapMethod(gameuiInGameMenuGameController)
private final func RegisterInputListenersForPlayer(playerPuppet: ref<GameObject>) {
  wrappedMethod(playerPuppet);
  let system: ref<SVCSystem> = SVCSystem.Get(playerPuppet.GetGame());
  if IsDefined(system) {
    system.m_requester = this;
  }
}

// Note when the player is leaving a vehicle, before the game switches anything off.
@wrapMethod(VehicleObject)
protected cb func OnUnmountingEvent(evt: ref<UnmountingEvent>) -> Bool {
  let child: ref<GameObject> = GameInstance.FindEntityByID(this.GetGame(), evt.request.lowLevelMountingInfo.childId) as GameObject;
  if IsDefined(child) && child.IsPlayer() {
    let system: ref<SVCSystem> = SVCSystem.Get(this.GetGame());
    if IsDefined(system) {
      system.PlayerLeaving(this);
    }
  }
  return wrappedMethod(evt);
}

// The first sign that the player is getting in, ahead of the game starting the engine.
@wrapMethod(VehicleComponent)
protected cb func OnVehicleStartedMountingEvent(evt: ref<VehicleStartedMountingEvent>) -> Bool {
  let vehicle: ref<VehicleObject> = this.GetVehicle();
  let entering: Bool = IsDefined(vehicle) && evt.isMounting && IsDefined(evt.character) && evt.character.IsPlayer();
  let system: ref<SVCSystem>;
  if entering {
    system = SVCSystem.Get(vehicle.GetGame());
    if IsDefined(system) {
      system.PlayerEntering(vehicle);
    }
  }
  let result: Bool = wrappedMethod(evt);
  if entering && IsDefined(system) {
    system.PlayerEntering(vehicle);
  }
  return result;
}

// Tell the mod whenever an engine stops, so one that stopped only because the
// player got out can be started again.
@addMethod(VehicleObject)
protected cb func SVCOnEngineTurnedOff(evt: ref<EngineTurnedOffEvent>) -> Bool {
  let system: ref<SVCSystem> = SVCSystem.Get(this.GetGame());
  if IsDefined(system) {
    system.EngineStopped(this);
  }
  return true;
}

// Tell the mod whenever an engine starts, so a held-off engine can be switched off again.
@addMethod(VehicleObject)
protected cb func SVCOnEngineTurnedOn(evt: ref<EngineTurnedOnEvent>) -> Bool {
  let system: ref<SVCSystem> = SVCSystem.Get(this.GetGame());
  if IsDefined(system) {
    system.EngineStarted(this);
  }
  return true;
}

public class SVCSystem extends ScriptableSystem {
  private let m_settings: ref<SVCSettings>;
  // Saved with the game, keyed by vehicle model (the record), so a car you switched
  // off or put the windows down on is still that way after loading.
  private persistent let m_heldOff: array<TweakDBID>;
  private persistent let m_driverWindowsDown: array<TweakDBID>;
  private persistent let m_passengerWindowsDown: array<TweakDBID>;
  private let m_listeners: array<ref<SVCListener>>;
  private let m_popup: wref<SVCPopup>;
  private let m_bypass: Bool;
  private let m_leavingId: EntityID;
  private let m_leavingTime: Float;
  private let m_leavingWasOn: Bool;
  public let m_requester: wref<inkGameController>;

  public static func Get(game: GameInstance) -> ref<SVCSystem> {
    return GameInstance.GetScriptableSystemsContainer(game).Get(n"SimpleVehicleControls.SVCSystem") as SVCSystem;
  }

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

  public func Log(message: String) -> Void {
    if this.m_settings.debug {
      FTLog("[SimpleVehicleControls] " + message);
    }
  }

  // --- Keys ---------------------------------------------------------------

  protected cb func OnKeyInput(event: ref<KeyInputEvent>) -> Void {
    if !Equals(event.GetAction(), EInputAction.IACT_Press) { return; }
    let key: EInputKey = event.GetKey();
    if Equals(key, EInputKey.IK_None) { return; }
    let game: GameInstance = this.GetGameInstance();
    if Equals(key, this.m_settings.openKey) {
      this.TogglePopup(game);
      return;
    }
    if GameInstance.GetTimeSystem(game).IsPausedState() { return; }
    let s: ref<SVCSettings> = this.m_settings;
    let known: Bool = Equals(key, s.engineKey) || Equals(key, s.driverDoorKey) || Equals(key, s.passengerDoorKey)
      || Equals(key, s.driverWindowDownKey) || Equals(key, s.driverWindowUpKey)
      || Equals(key, s.passengerWindowDownKey) || Equals(key, s.passengerWindowUpKey)
      || Equals(key, s.hoodKey) || Equals(key, s.trunkKey);
    if !known { return; }
    let vehicle: ref<VehicleObject> = SVCActions.FindVehicle(game);
    if !IsDefined(vehicle) { return; }
    if Equals(key, s.engineKey) {
      this.SetEngine(vehicle, !vehicle.IsEngineTurnedOn());
    }
    if Equals(key, s.driverDoorKey) {
      SVCActions.SetDoor(vehicle, n"seat_front_left", !SVCActions.IsDoorOpen(vehicle, EVehicleDoor.seat_front_left));
    }
    if Equals(key, s.passengerDoorKey) {
      SVCActions.SetDoor(vehicle, n"seat_front_right", !SVCActions.IsDoorOpen(vehicle, EVehicleDoor.seat_front_right));
    }
    if Equals(key, s.hoodKey) {
      SVCActions.SetDoor(vehicle, n"hood", !SVCActions.IsDoorOpen(vehicle, EVehicleDoor.hood));
    }
    if Equals(key, s.trunkKey) {
      SVCActions.SetDoor(vehicle, n"trunk", !SVCActions.IsDoorOpen(vehicle, EVehicleDoor.trunk));
    }
    if Equals(key, s.driverWindowDownKey) { this.SetWindowDown(vehicle, true, true); }
    if Equals(key, s.driverWindowUpKey) { this.SetWindowDown(vehicle, true, false); }
    if Equals(key, s.passengerWindowDownKey) { this.SetWindowDown(vehicle, false, true); }
    if Equals(key, s.passengerWindowUpKey) { this.SetWindowDown(vehicle, false, false); }
  }

  private func TogglePopup(game: GameInstance) -> Void {
    if IsDefined(this.m_popup) {
      this.m_popup.Close();
      return;
    }
    if !IsDefined(this.m_requester) || GameInstance.GetTimeSystem(game).IsPausedState() { return; }
    let vehicle: ref<VehicleObject> = SVCActions.FindVehicle(game);
    if !IsDefined(vehicle) {
      this.Log("no vehicle to control");
      return;
    }
    let popup: ref<SVCPopup> = new SVCPopup();
    popup.Setup(this, vehicle);
    this.m_popup = popup;
    this.Log("opening panel");
    popup.Open(this.m_requester);
  }

  public func PopupClosed() -> Void {
    this.m_popup = null;
  }

  // --- Engine -------------------------------------------------------------

  // Switching an engine off here holds it off until it is switched on here.
  public func SetEngine(vehicle: ref<VehicleObject>, on: Bool) -> Void {
    let id: TweakDBID = vehicle.GetRecordID();
    if on {
      ArrayRemove(this.m_heldOff, id);
    } else if !ArrayContains(this.m_heldOff, id) {
      ArrayPush(this.m_heldOff, id);
    }
    for listener in this.m_listeners {
      listener.OnEngineHoldChanged(vehicle, !on);
    }
    if on {
      this.QuietStart(vehicle, false);
    }
    this.m_bypass = true;
    SVCActions.SetEngine(vehicle, on);
    this.m_bypass = false;
  }

  public func PlayerLeaving(vehicle: ref<VehicleObject>) -> Void {
    this.m_leavingId = vehicle.GetEntityID();
    this.m_leavingTime = this.Now();
    this.m_leavingWasOn = vehicle.IsEngineTurnedOn();
    this.QuietStart(vehicle, false);
    this.Log("player leaving, engine on: " + ToString(this.m_leavingWasOn));
    this.ScheduleRestart(vehicle, 0.3);
    this.ScheduleRestart(vehicle, 1.0);
  }

  // Getting into a car whose engine is held off: switch it off before the game gets
  // going, and keep doing so for a moment.
  public func PlayerEntering(vehicle: ref<VehicleObject>) -> Void {
    this.Log("player entering");
    this.ScheduleWindows(vehicle);
    this.QuietStart(vehicle, this.IsEngineHeldOff(vehicle));
    if !this.IsEngineHeldOff(vehicle) { return; }
    this.EngineOffIfHeld(vehicle);
    this.ScheduleOff(vehicle, 0.02, 12, 0.03);
    this.ScheduleOff(vehicle, 0.5, 8, 0.25);
  }

  private func ScheduleWindows(vehicle: ref<VehicleObject>) -> Void {
    let callback: ref<SVCWindowCallback> = new SVCWindowCallback();
    callback.vehicle = vehicle;
    callback.system = this;
    GameInstance.GetDelaySystem(this.GetGameInstance()).DelayCallback(callback, 1.5, false);
  }

  private func QuietStart(vehicle: ref<VehicleObject>, quiet: Bool) -> Void {
    let audio: ref<SVCAudio> = SVCAudio.Get();
    if IsDefined(audio) {
      this.Log(audio.SetQuietStart(vehicle, quiet && this.m_settings.quietStart));
    }
  }

  // For a car whose engine is held off: engine off, and the headlights off too,
  // since the game (or an auto-headlights mod) may switch them on as it starts.
  public func EngineOffIfHeld(vehicle: ref<VehicleObject>) -> Void {
    if !this.IsEngineHeldOff(vehicle) { return; }
    if vehicle.IsEngineTurnedOn() {
      this.Log("engine switched back off");
      this.m_bypass = true;
      SVCActions.SetEngine(vehicle, false);
      this.m_bypass = false;
    }
    SVCActions.HeadlightsOff(vehicle);
  }

  private func Now() -> Float {
    return EngineTime.ToFloat(GameInstance.GetSimTime(this.GetGameInstance()));
  }

  private func JustLeft(vehicle: ref<VehicleObject>) -> Bool {
    return Equals(this.m_leavingId, vehicle.GetEntityID()) && this.Now() - this.m_leavingTime < 2.5;
  }

  private func ScheduleRestart(vehicle: ref<VehicleObject>, delay: Float) -> Void {
    let callback: ref<SVCEngineOnCallback> = new SVCEngineOnCallback();
    callback.vehicle = vehicle;
    callback.system = this;
    GameInstance.GetDelaySystem(this.GetGameInstance()).DelayCallback(callback, delay, false);
  }

  private func ScheduleOff(vehicle: ref<VehicleObject>, delay: Float, repeats: Int32, interval: Float) -> Void {
    let callback: ref<SVCEngineOffCallback> = new SVCEngineOffCallback();
    callback.vehicle = vehicle;
    callback.system = this;
    callback.repeats = repeats;
    callback.interval = interval;
    GameInstance.GetDelaySystem(this.GetGameInstance()).DelayCallback(callback, delay, false);
  }

  public func EngineStopped(vehicle: ref<VehicleObject>) -> Void {
    if this.m_bypass || !this.JustLeft(vehicle) { return; }
    this.Log("engine stopped as the player left");
    this.ScheduleRestart(vehicle, 0.05);
  }

  // The engine was running when the player got out and has stopped since.
  public func RestartIfLeft(vehicle: ref<VehicleObject>) -> Void {
    if !this.m_settings.keepRunningOnExit || !this.m_leavingWasOn || !this.JustLeft(vehicle) { return; }
    if this.IsEngineHeldOff(vehicle) || vehicle.IsEngineTurnedOn() { return; }
    this.Log("engine started again after the player left");
    this.m_bypass = true;
    SVCActions.SetEngine(vehicle, true);
    this.m_bypass = false;
  }

  public func IsEngineHeldOff(vehicle: ref<VehicleObject>) -> Bool {
    return this.m_settings.keepEngineOff && ArrayContains(this.m_heldOff, vehicle.GetRecordID());
  }

  public func EngineStarted(vehicle: ref<VehicleObject>) -> Void {
    if !this.IsEngineHeldOff(vehicle) { return; }
    this.ScheduleOff(vehicle, 0.0, 1, 0.0);
  }

  // --- Windows ------------------------------------------------------------

  public func IsWindowDown(vehicle: ref<VehicleObject>, driver: Bool) -> Bool {
    let id: TweakDBID = vehicle.GetRecordID();
    return driver ? ArrayContains(this.m_driverWindowsDown, id) : ArrayContains(this.m_passengerWindowsDown, id);
  }

  public func SetWindowDown(vehicle: ref<VehicleObject>, driver: Bool, down: Bool) -> Void {
    let id: TweakDBID = vehicle.GetRecordID();
    if driver {
      if down && !ArrayContains(this.m_driverWindowsDown, id) { ArrayPush(this.m_driverWindowsDown, id); }
      if !down { ArrayRemove(this.m_driverWindowsDown, id); }
    } else {
      if down && !ArrayContains(this.m_passengerWindowsDown, id) { ArrayPush(this.m_passengerWindowsDown, id); }
      if !down { ArrayRemove(this.m_passengerWindowsDown, id); }
    }
    SVCActions.SetWindow(vehicle, driver ? n"seat_front_left_window" : n"seat_front_right_window", down);
    for listener in this.m_listeners {
      listener.OnWindowChanged(vehicle, driver, down);
    }
  }

  // Put remembered windows back down once a car has spawned and been entered.
  public func ReapplyWindows(vehicle: ref<VehicleObject>) -> Void {
    if this.IsWindowDown(vehicle, true) {
      SVCActions.SetWindow(vehicle, n"seat_front_left_window", true);
    }
    if this.IsWindowDown(vehicle, false) {
      SVCActions.SetWindow(vehicle, n"seat_front_right_window", true);
    }
  }

  // --- For other mods -----------------------------------------------------

  public func AddListener(listener: ref<SVCListener>) -> Void {
    if IsDefined(listener) && !ArrayContains(this.m_listeners, listener) {
      ArrayPush(this.m_listeners, listener);
    }
  }

  public func RemoveListener(listener: ref<SVCListener>) -> Void {
    ArrayRemove(this.m_listeners, listener);
  }
}

// What other mods can call. They need only
//   @if(ModuleExists("SimpleVehicleControls")) import SimpleVehicleControls.*
// and every call does nothing, or answers false, when this mod is not installed
// and the call sits behind that same @if.
public abstract class SVCApi {
  public static func IsEngineHeldOff(vehicle: ref<VehicleObject>) -> Bool {
    let system: ref<SVCSystem> = SVCSystem.Get(vehicle.GetGame());
    return IsDefined(system) && system.IsEngineHeldOff(vehicle);
  }

  // Switches the engine, and remembers it: off is held off, on releases the hold.
  public static func SetEngine(vehicle: ref<VehicleObject>, on: Bool) -> Void {
    let system: ref<SVCSystem> = SVCSystem.Get(vehicle.GetGame());
    if IsDefined(system) { system.SetEngine(vehicle, on); }
  }

  public static func IsWindowDown(vehicle: ref<VehicleObject>, driver: Bool) -> Bool {
    let system: ref<SVCSystem> = SVCSystem.Get(vehicle.GetGame());
    return IsDefined(system) && system.IsWindowDown(vehicle, driver);
  }

  public static func SetWindowDown(vehicle: ref<VehicleObject>, driver: Bool, down: Bool) -> Void {
    let system: ref<SVCSystem> = SVCSystem.Get(vehicle.GetGame());
    if IsDefined(system) { system.SetWindowDown(vehicle, driver, down); }
  }

  public static func AddListener(game: GameInstance, listener: ref<SVCListener>) -> Void {
    let system: ref<SVCSystem> = SVCSystem.Get(game);
    if IsDefined(system) { system.AddListener(listener); }
  }

  public static func RemoveListener(game: GameInstance, listener: ref<SVCListener>) -> Void {
    let system: ref<SVCSystem> = SVCSystem.Get(game);
    if IsDefined(system) { system.RemoveListener(listener); }
  }
}

// Extend this and override what you want to hear about, then pass it to SVCApi.AddListener.
public class SVCListener {
  public func OnEngineHoldChanged(vehicle: ref<VehicleObject>, heldOff: Bool) -> Void {}
  public func OnWindowChanged(vehicle: ref<VehicleObject>, driver: Bool, down: Bool) -> Void {}
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
