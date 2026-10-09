// Simple Vehicle Controls: a quiet start-up for engines that are held off.
//
// Each vehicle model has audio metadata that names the sound played when its
// engine starts. When the player gets into a car whose engine is held off, the
// name is blanked for that model so the game's own start-up plays nothing, and
// it is put back when the player gets out or switches the engine on.
module SimpleVehicleControls

public class SVCAudio extends ScriptableService {
  private let m_names: array<CName>;
  private let m_entries: array<ref<audioVehicleMetadata>>;
  private let m_originals: array<CName>;

  public static func Get() -> ref<SVCAudio> {
    return GameInstance.GetScriptableServiceContainer().GetService(n"SimpleVehicleControls.SVCAudio") as SVCAudio;
  }

  private cb func OnLoad() {
    GameInstance.GetCallbackSystem()
      .RegisterCallback(n"Resource/Ready", this, n"OnAudioMetadataLoad")
      .AddTarget(ResourceTarget.Path(r"base\\sound\\metadata\\cooked_metadata.audio_metadata"));
  }

  // Remember every vehicle's own start-up sound as the metadata loads.
  private cb func OnAudioMetadataLoad(event: ref<ResourceEvent>) {
    let cooked: ref<audioCookedMetadataResource> = event.GetResource() as audioCookedMetadataResource;
    if !IsDefined(cooked) { return; }
    ArrayClear(this.m_names);
    ArrayClear(this.m_entries);
    ArrayClear(this.m_originals);
    for entry in cooked.entries {
      let vehicleAudio: ref<audioVehicleMetadata> = entry as audioVehicleMetadata;
      if IsDefined(vehicleAudio) {
        ArrayPush(this.m_names, vehicleAudio.name);
        ArrayPush(this.m_entries, vehicleAudio);
        ArrayPush(this.m_originals, vehicleAudio.generalData.ignitionStartEvent);
      }
    }
  }

  // quiet = true blanks the start-up sound for this vehicle's model, false restores it.
  // Returns a short description of what was done, for the log.
  public func SetQuietStart(vehicle: ref<VehicleObject>, quiet: Bool) -> String {
    let audioName: CName = TweakDBInterface.GetCName(vehicle.GetRecordID() + t".player_audio_resource", n"");
    let i: Int32 = 0;
    while i < ArraySize(this.m_names) {
      if Equals(this.m_names[i], audioName) {
        this.m_entries[i].generalData.ignitionStartEvent = quiet ? n"" : this.m_originals[i];
        return NameToString(audioName) + (quiet ? " start sound blanked, was " : " start sound restored to ") + NameToString(this.m_originals[i]);
      }
      i += 1;
    }
    return "no audio entry for " + NameToString(audioName) + " (" + ToString(ArraySize(this.m_names)) + " entries known)";
  }
}
