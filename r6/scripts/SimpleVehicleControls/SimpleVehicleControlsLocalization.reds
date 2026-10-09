// Simple Vehicle Controls: text shown by the mod, registered with Codeware's
// localization system so it can be translated.
//
// To add a language, copy SVCLanguageEnglish into a new class (in a file of its own),
// translate the second string of every line and leave the first alone, then return
// the new class for that language from SVCLocalizationProvider.GetPackage below.
// The Mod Settings page is written in English only.
module SimpleVehicleControls

import Codeware.Localization.*

public class SVCLocalizationProvider extends ModLocalizationProvider {
  public func GetPackage(language: CName) -> ref<ModLocalizationPackage> {
    switch language {
      // case n"fr-fr": return new SVCLanguageFrench();
      default: return new SVCLanguageEnglish();
    }
  }

  public func GetFallback() -> CName {
    return n"en-us";
  }
}

public class SVCLanguageEnglish extends ModLocalizationPackage {
  protected func DefineTexts() -> Void {
    this.Text("SVC-Title", "Vehicle Controls");
    this.Text("SVC-Fluff", "SVC");
    this.Text("SVC-Footer", "Click a part of the car");
    this.Text("SVC-Engine", "Engine");
    this.Text("SVC-Hood", "Hood");
    this.Text("SVC-Trunk", "Trunk");
    this.Text("SVC-DriverDoor", "Driver door");
    this.Text("SVC-PassengerDoor", "Passenger door");
    this.Text("SVC-DriverWindow", "Driver window");
    this.Text("SVC-PassengerWindow", "Passenger window");
    this.Text("SVC-On", "On");
    this.Text("SVC-Off", "Off");
    this.Text("SVC-Open", "Open");
    this.Text("SVC-Closed", "Closed");
    this.Text("SVC-Down", "Down");
    this.Text("SVC-Up", "Up");
  }
}
