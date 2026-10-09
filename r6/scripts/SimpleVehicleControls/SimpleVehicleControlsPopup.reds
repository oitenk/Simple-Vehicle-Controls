// Simple Vehicle Controls: the panel. A top-down car whose parts are clickable,
// plus buttons for the engine and the windows.
module SimpleVehicleControls

import Codeware.UI.*

// A flat rectangle that reacts to the mouse. Parts of the car and the plain
// buttons are both this; "active" marks a part that is open / on / down.
public class SVCPartButton extends CustomButton {
  protected let m_fill: wref<inkRectangle>;
  protected let m_active: Bool;

  protected func CreateWidgets() {
    let root: ref<inkCanvas> = new inkCanvas();
    root.SetName(n"part");
    root.SetSize(100.0, 100.0);
    root.SetInteractive(true);

    let fill: ref<inkRectangle> = new inkRectangle();
    fill.SetName(n"fill");
    fill.SetAnchor(inkEAnchor.Fill);
    fill.Reparent(root);

    let label: ref<inkText> = new inkText();
    label.SetName(n"label");
    label.SetFontFamily("base\\gameplay\\gui\\fonts\\raj\\raj.inkfontfamily");
    label.SetFontStyle(n"Medium");
    label.SetFontSize(30);
    label.SetLetterCase(textLetterCase.UpperCase);
    label.SetTintColor(new HDRColor(0.92, 0.96, 1.0, 1.0));
    label.SetAnchor(inkEAnchor.Fill);
    label.SetHorizontalAlignment(textHorizontalAlignment.Center);
    label.SetVerticalAlignment(textVerticalAlignment.Center);
    label.SetText("");
    label.Reparent(root);

    this.m_root = root;
    this.m_label = label;
    this.m_fill = fill;
    this.SetRootWidget(root);
    this.Refresh();
  }

  protected func ApplyDisabledState() { this.Refresh(); }
  protected func ApplyHoveredState() { this.Refresh(); }
  protected func ApplyPressedState() { this.Refresh(); }

  protected func Refresh() -> Void {
    if !IsDefined(this.m_fill) { return; }
    if this.m_active {
      this.m_fill.SetTintColor(this.m_isHovered ? new HDRColor(1.0, 0.42, 0.36, 1.0) : new HDRColor(0.80, 0.28, 0.24, 1.0));
    } else {
      this.m_fill.SetTintColor(this.m_isHovered ? new HDRColor(0.20, 0.42, 0.55, 1.0) : new HDRColor(0.09, 0.17, 0.24, 1.0));
    }
    this.m_fill.SetOpacity(this.m_isPressed ? 0.6 : 0.9);
  }

  public func SetActive(active: Bool) -> Void {
    this.m_active = active;
    this.Refresh();
  }

  public func Place(x: Float, y: Float, width: Float, height: Float) -> Void {
    this.m_root.SetSize(width, height);
    this.m_root.SetMargin(x, y, 0.0, 0.0);
  }

  public static func Create() -> ref<SVCPartButton> {
    let self: ref<SVCPartButton> = new SVCPartButton();
    self.CreateInstance();
    return self;
  }
}

public class SVCPopup extends InGamePopup {
  protected let m_system: wref<SVCSystem>;
  protected let m_vehicle: wref<VehicleObject>;

  protected let m_header: ref<InGamePopupHeader>;
  protected let m_footer: ref<InGamePopupFooter>;
  protected let m_content: ref<InGamePopupContent>;
  protected let m_canvas: ref<inkCanvas>;

  protected let m_engine: ref<SVCPartButton>;
  protected let m_hood: ref<SVCPartButton>;
  protected let m_trunk: ref<SVCPartButton>;
  protected let m_driverDoor: ref<SVCPartButton>;
  protected let m_passengerDoor: ref<SVCPartButton>;
  protected let m_driverWindow: ref<SVCPartButton>;
  protected let m_passengerWindow: ref<SVCPartButton>;
  protected let m_driverDoorText: wref<inkText>;
  protected let m_passengerDoorText: wref<inkText>;

  protected let m_engineOn: Bool;
  protected let m_hoodOpen: Bool;
  protected let m_trunkOpen: Bool;
  protected let m_driverDoorOpen: Bool;
  protected let m_passengerDoorOpen: Bool;
  protected let m_driverWindowDown: Bool;
  protected let m_passengerWindowDown: Bool;

  public func Setup(system: ref<SVCSystem>, vehicle: ref<VehicleObject>) -> Void {
    this.m_system = system;
    this.m_vehicle = vehicle;
  }

  public func UseCursor() -> Bool {
    return true;
  }

  protected cb func OnCreate() -> Void {
    super.OnCreate();

    this.m_container.SetSize(1550.0, 1000.0);

    this.m_header = InGamePopupHeader.Create();
    this.m_header.SetTitle(SVC_Text("SVC-Title"));
    this.m_header.SetFluffRight(SVC_Text("SVC-Fluff"));
    this.m_header.Reparent(this);

    this.m_footer = InGamePopupFooter.Create();
    this.m_footer.SetFluffIcon(n"fluff_triangle2");
    this.m_footer.SetFluffText(SVC_Text("SVC-Footer"));
    this.m_footer.Reparent(this);

    this.m_content = InGamePopupContent.Create();
    this.m_content.Reparent(this);

    let canvas: ref<inkCanvas> = new inkCanvas();
    canvas.SetName(n"carCanvas");
    canvas.SetAnchor(inkEAnchor.Fill);
    canvas.Reparent(this.m_content.GetRootCompoundWidget());
    this.m_canvas = canvas;

    this.BuildCar();
    this.ReadState();
    this.UpdateAll();
  }

  protected cb func OnHide() -> Void {
    super.OnHide();
    if IsDefined(this.m_system) {
      this.m_system.PopupClosed();
    }
  }

  // --- Drawing ------------------------------------------------------------

  protected func Decor(x: Float, y: Float, width: Float, height: Float, r: Float, g: Float, b: Float, opacity: Float) -> Void {
    let rect: ref<inkRectangle> = new inkRectangle();
    rect.SetSize(width, height);
    rect.SetMargin(x, y, 0.0, 0.0);
    rect.SetTintColor(new HDRColor(r, g, b, 1.0));
    rect.SetOpacity(opacity);
    rect.Reparent(this.m_canvas);
  }

  protected func Part(x: Float, y: Float, width: Float, height: Float, callback: CName) -> ref<SVCPartButton> {
    let button: ref<SVCPartButton> = SVCPartButton.Create();
    button.Place(x, y, width, height);
    button.Reparent(this.m_canvas);
    button.RegisterToCallback(n"OnBtnClick", this, callback);
    return button;
  }

  protected func Caption(x: Float, y: Float, width: Float, alignment: textHorizontalAlignment) -> ref<inkText> {
    let text: ref<inkText> = new inkText();
    text.SetFontFamily("base\\gameplay\\gui\\fonts\\raj\\raj.inkfontfamily");
    text.SetFontStyle(n"Medium");
    text.SetFontSize(34);
    text.SetLetterCase(textLetterCase.UpperCase);
    text.SetTintColor(new HDRColor(0.92, 0.96, 1.0, 1.0));
    text.SetSize(width, 50.0);
    text.SetMargin(x, y, 0.0, 0.0);
    text.SetHorizontalAlignment(alignment);
    text.SetVerticalAlignment(textVerticalAlignment.Center);
    text.Reparent(this.m_canvas);
    return text;
  }

  protected func BuildCar() -> Void {
    // Body and the parts that do nothing
    this.Decor(587.0, 20.0, 300.0, 700.0, 0.04, 0.07, 0.10, 0.9);
    this.Decor(617.0, 220.0, 240.0, 55.0, 0.30, 0.55, 0.65, 0.5);
    this.Decor(617.0, 275.0, 240.0, 160.0, 0.10, 0.16, 0.22, 0.9);
    this.Decor(617.0, 435.0, 240.0, 45.0, 0.30, 0.55, 0.65, 0.5);
    // Wheels
    this.Decor(556.0, 90.0, 30.0, 110.0, 0.02, 0.02, 0.03, 1.0);
    this.Decor(888.0, 90.0, 30.0, 110.0, 0.02, 0.02, 0.03, 1.0);
    this.Decor(556.0, 520.0, 30.0, 110.0, 0.02, 0.02, 0.03, 1.0);
    this.Decor(888.0, 520.0, 30.0, 110.0, 0.02, 0.02, 0.03, 1.0);

    // Clickable parts
    this.m_hood = this.Part(607.0, 40.0, 260.0, 170.0, n"OnHoodClick");
    this.m_trunk = this.Part(607.0, 500.0, 260.0, 200.0, n"OnTrunkClick");
    this.m_driverDoor = this.Part(530.0, 270.0, 56.0, 190.0, n"OnDriverDoorClick");
    this.m_passengerDoor = this.Part(888.0, 270.0, 56.0, 190.0, n"OnPassengerDoorClick");

    this.m_driverDoorText = this.Caption(60.0, 340.0, 450.0, textHorizontalAlignment.Right);
    this.m_passengerDoorText = this.Caption(964.0, 340.0, 450.0, textHorizontalAlignment.Left);

    // Buttons beside the car
    this.m_engine = this.Part(60.0, 20.0, 380.0, 90.0, n"OnEngineClick");
    this.m_driverWindow = this.Part(130.0, 560.0, 380.0, 90.0, n"OnDriverWindowClick");
    this.m_passengerWindow = this.Part(964.0, 560.0, 380.0, 90.0, n"OnPassengerWindowClick");
  }

  // --- State --------------------------------------------------------------

  protected func ReadState() -> Void {
    if !IsDefined(this.m_vehicle) { return; }
    this.m_engineOn = this.m_vehicle.IsEngineTurnedOn();
    this.m_hoodOpen = SVCActions.IsDoorOpen(this.m_vehicle, EVehicleDoor.hood);
    this.m_trunkOpen = SVCActions.IsDoorOpen(this.m_vehicle, EVehicleDoor.trunk);
    this.m_driverDoorOpen = SVCActions.IsDoorOpen(this.m_vehicle, EVehicleDoor.seat_front_left);
    this.m_passengerDoorOpen = SVCActions.IsDoorOpen(this.m_vehicle, EVehicleDoor.seat_front_right);
    this.m_driverWindowDown = this.m_system.IsWindowDown(this.m_vehicle, true);
    this.m_passengerWindowDown = this.m_system.IsWindowDown(this.m_vehicle, false);
  }

  protected func StateText(name: String, state: String) -> String {
    return SVC_Text(name) + ": " + SVC_Text(state);
  }

  protected func UpdateAll() -> Void {
    this.m_engine.SetText(this.StateText("SVC-Engine", this.m_engineOn ? "SVC-On" : "SVC-Off"));
    this.m_engine.SetActive(this.m_engineOn);
    this.m_hood.SetText(this.StateText("SVC-Hood", this.m_hoodOpen ? "SVC-Open" : "SVC-Closed"));
    this.m_hood.SetActive(this.m_hoodOpen);
    this.m_trunk.SetText(this.StateText("SVC-Trunk", this.m_trunkOpen ? "SVC-Open" : "SVC-Closed"));
    this.m_trunk.SetActive(this.m_trunkOpen);
    this.m_driverDoor.SetActive(this.m_driverDoorOpen);
    this.m_passengerDoor.SetActive(this.m_passengerDoorOpen);
    this.m_driverDoorText.SetText(this.StateText("SVC-DriverDoor", this.m_driverDoorOpen ? "SVC-Open" : "SVC-Closed"));
    this.m_passengerDoorText.SetText(this.StateText("SVC-PassengerDoor", this.m_passengerDoorOpen ? "SVC-Open" : "SVC-Closed"));
    this.m_driverWindow.SetText(this.StateText("SVC-DriverWindow", this.m_driverWindowDown ? "SVC-Down" : "SVC-Up"));
    this.m_driverWindow.SetActive(this.m_driverWindowDown);
    this.m_passengerWindow.SetText(this.StateText("SVC-PassengerWindow", this.m_passengerWindowDown ? "SVC-Down" : "SVC-Up"));
    this.m_passengerWindow.SetActive(this.m_passengerWindowDown);
  }

  // --- Clicks -------------------------------------------------------------

  protected cb func OnEngineClick(widget: wref<inkWidget>) -> Bool {
    this.m_engineOn = !this.m_engineOn;
    this.m_system.SetEngine(this.m_vehicle, this.m_engineOn);
    this.UpdateAll();
    return true;
  }

  protected cb func OnHoodClick(widget: wref<inkWidget>) -> Bool {
    this.m_hoodOpen = !this.m_hoodOpen;
    SVCActions.SetDoor(this.m_vehicle, n"hood", this.m_hoodOpen);
    this.UpdateAll();
    return true;
  }

  protected cb func OnTrunkClick(widget: wref<inkWidget>) -> Bool {
    this.m_trunkOpen = !this.m_trunkOpen;
    SVCActions.SetDoor(this.m_vehicle, n"trunk", this.m_trunkOpen);
    this.UpdateAll();
    return true;
  }

  protected cb func OnDriverDoorClick(widget: wref<inkWidget>) -> Bool {
    this.m_driverDoorOpen = !this.m_driverDoorOpen;
    SVCActions.SetDoor(this.m_vehicle, n"seat_front_left", this.m_driverDoorOpen);
    this.UpdateAll();
    return true;
  }

  protected cb func OnPassengerDoorClick(widget: wref<inkWidget>) -> Bool {
    this.m_passengerDoorOpen = !this.m_passengerDoorOpen;
    SVCActions.SetDoor(this.m_vehicle, n"seat_front_right", this.m_passengerDoorOpen);
    this.UpdateAll();
    return true;
  }

  protected cb func OnDriverWindowClick(widget: wref<inkWidget>) -> Bool {
    this.m_driverWindowDown = !this.m_driverWindowDown;
    this.m_system.SetWindowDown(this.m_vehicle, true, this.m_driverWindowDown);
    this.UpdateAll();
    return true;
  }

  protected cb func OnPassengerWindowClick(widget: wref<inkWidget>) -> Bool {
    this.m_passengerWindowDown = !this.m_passengerWindowDown;
    this.m_system.SetWindowDown(this.m_vehicle, false, this.m_passengerWindowDown);
    this.UpdateAll();
    return true;
  }
}
