{Hint: save all files to location: /home/[user]/fpcupdeluxe/projects/LAMWProjects/SmartFritz/jni }
// Die Angaben

// {$IFDEF ANDROID}
// {$ENDIF ANDROID}

// {$IFDEF Linux}
// {$ENDIF Linux}

// sollen nur die wichtigsten Unterschiede zum Code für Linux/Windows zeigen
// und sind nicht vollständig.
// Der Code lässt sich nicht immer 1:1 von Android für Linux übernehmen.

unit unit1;

{$mode delphi}

interface

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Classes, SysUtils, AndroidWidget, sdrawerlayout, snavigationview,
  Laz_And_Controls, stoolbar, sfloatingbutton, switchbutton,
  preferences, sbottomnavigationview, unit2, unit3, unit4, unit5, fritzbox,
  laz2_XMLRead, laz2_DOM,{$IFDEF Linux} fphttpclient,
  httpdefs, httpprotocol,{$ENDIF Linux} BlowFish, base64, RegExpr;

// Record für die Werte der SmartHome-Schalter
type
  TSmartData = record
    Name: string;
    AIN: string;
    Present: string;
    State: string;
    HasSwitch: integer;
    Celsius: string;
    Power: string;
    Productname: string;
    HasTemperature: integer;
    functionbitmask: string;
    SollTemperatur: string;
    IsComet: integer;  //Comet Dect, wird nicht ausgewertet
  end;

type

  { TAndroidModule1 }

  TAndroidModule1 = class(jForm)
    jHttpClient1: jHttpClient;
    jPanel1: jPanel;
    jPanel2: jPanel;
    jPanel3: jPanel;
    jsBottomNavigationView1: jsBottomNavigationView;
    jsFloatingButton1: jsFloatingButton;
    jSwitchButton1: jSwitchButton;
    pnlSwitches: jPanel;
    jPreferences1: jPreferences;
    jsDrawerLayout1: jsDrawerLayout;
    jsNavigationView1: jsNavigationView;
    jsToolbar1: jsToolbar;
    jTextView1: jTextView;

    procedure SaveSettings();
    procedure LoadSettings();
    procedure Logger(msg: string);
    procedure ToogleSwitch(AIN: string; Command: string);
    procedure FBReadData(response: string);
    procedure WriteMessages();
    {$IFDEF ANDROID}
    procedure AndroidModule1Close(Sender: TObject);
    procedure AndroidModule1Create(Sender: TObject);
    procedure AndroidModule1JNIPrompt(Sender: TObject);
    procedure AndroidModule1SpecialKeyDown(Sender: TObject; keyChar: char;
      keyCode: integer; keyCodeString: string; var mute: boolean);
    procedure jHttpClient1CodeResult(Sender: TObject; code: integer);
    procedure jHttpClient1ContentResult(Sender: TObject; content: string);
    procedure jPanel2FlingGesture(Sender: TObject; flingGesture: TFlingGesture);
    procedure jsBottomNavigationView1ClickItem(Sender: TObject;
      itemId: integer; itemCaption: string);
    procedure jsFloatingButton1Click(Sender: TObject);
    procedure jsNavigationView1ClickItem(Sender: TObject; itemId: integer;
      itemCaption: string);
    procedure jsToolbar1ClickNavigationIcon(Sender: TObject);
    procedure AddControls(num: integer; SwitchName, State, Present: string);
    procedure ClearSwitchPanel();
    procedure aSwitchSwitch(Sender: TObject; state: boolean);
    procedure Navigate(itemID: integer);
    procedure SetAnimMode(Module: string; ItemID: integer);
    procedure CreateForms;
    procedure InitPanels;
     {$ENDIF ANDROID}

    {$IFDEF Linux}
    procedure aSwitchSwitch(Sender: TObject);
    {$ENDIF Linux}
    procedure GetExternalIP();

  private
    {private declarations}

    ActivePage: integer;
    procedure Logger2(Sender: TObject; EMessage: string);

  public
    {public declarations}
  var
    TheSid: string;
    FBOXURL: string;
    Username: string;
    Password: string;
    SavePassword: boolean;
    DebugLog: boolean;
    DeviceList: array of TSmartData;
    FBox: TFritzBox;
    Messages: TStringList;
    FormsCreated: boolean;
    PanelsInit: boolean;
  end;

var
  AndroidModule1: TAndroidModule1;

implementation

{$R *.lfm}


{ TAndroidModule1 }

// Veschlüsselung für Passwort
// Diese einfache Veschlüsselung verbirgt das Passwort
// in der Konfigurationsdatei vor den Augen unbefugter Personen
// und erfüllte keine geltenden Sicherheitsstandards.
function EncryptString(aString: string): string;
var
  Key: string;
  EncrytpStream: TBlowFishEncryptStream;
  StringStream: TStringStream;
  EncryptedString: RawByteString;
  B64String: string;
begin
  if aString = '' then
    Exit;
  Key := 's6v9y$B&E)H@McQfTjWnZq4t7w!z%C*F';  //sollte geändert werden
  StringStream := TStringStream.Create('');
  EncrytpStream := TBlowFishEncryptStream.Create(Key, StringStream);
  EncrytpStream.WriteAnsiString(aString);
  EncrytpStream.Flush;
  EncryptedString := StringStream.DataString;
  B64String := EncodeStringBase64(EncryptedString);
  EncrytpStream.Free;
  StringStream.Free;
  EncryptString := B64String;
end;
// Passwort entschlüsseln
function DecryptString(aString: string): string;
var
  Key: string;
  DecrytpStream: TBlowFishDeCryptStream;
  StringStream: TStringStream;
  DecryptedString: string;
  B64String: RawByteString;
begin
  if aString = '' then
    Exit;
  Key := 's6v9y$B&E)H@McQfTjWnZq4t7w!z%C*F';
  //sollte geändert werden, gleicher Schlüssel wie oben
  B64String := DecodeStringBase64(aString, False);
  StringStream := TStringStream.Create(B64String);
  DecrytpStream := TBlowfishDecryptStream.Create(key, StringStream);
  DecryptedString := DecrytpStream.ReadAnsiString;
  DecrytpStream.Free;
  StringStream.Free;
  DecryptString := DecryptedString;
end;
// Initialisierung, wird beim Start der App ausgeführt
procedure TAndroidModule1.AndroidModule1JNIPrompt(Sender: TObject);
var
  myMenu: jObjectRef;
  navigationMenu: jObjectRef;
  //aForm:jForm;
begin
  FormsCreated := False;
  PanelsInit := False;
  //die App-Leiste
  jsToolbar1.SetFitsSystemWindows(True);
  jsToolbar1.SetBackgroundToPrimaryColor();   // in "...\res\values\style.xml"
  jsToolbar1.NavigationIconIdentifier := 'ic_menu_white_36dp';
  jsToolbar1.SetTitleTextColor(colbrWhite);
  jsToolbar1.SetTitle('SmartFritz');
  jsToolbar1.SetSubtitleTextColor(colbrWhite);
  jsToolbar1.SetSubtitle('Fritzbox steuern');

  // das Menü
  jsNavigationView1.AddHeaderView('bg_material', 'ic_fritzbox',
    'Smarthome|Fritzbox steuern', 180);
  myMenu := jsNavigationView1.AddMenu('Fritzbox'); // Menü-Gruppe erstellen
  jsNavigationView1.AddItem(myMenu, 101, 'Steuerung', 'ic_fritzbox_icon');
  jsNavigationView1.AddItem(myMenu, 102, 'Einstellungen', 'ic_settings_icon');
  jsNavigationView1.AddItem(myMenu, 103, 'Log-Meldungen', 'ic_log_icon');
  jsNavigationView1.AddItem(myMenu, 104, 'Status-Infos', 'ic_state_icon');
  jsNavigationView1.AddItem(myMenu, 105, 'Anrufliste', 'ic_call_icon');

  // links/rechts blättern
  navigationMenu := jsBottomNavigationView1.GetMenu();
  jsBottomNavigationView1.AddItem(navigationMenu, 102, 'Links',
    'ic_chevron_left_black_48dp');
  jsBottomNavigationView1.AddItem(navigationMenu, 101, 'Rechts',
    'ic_chevron_right_black_48dp');

  ActivePage := 101;
  LoadSettings(); // Einstellungen laden
  TheSID := '0000000000000000';
  // Klasse TFritzBox initialisieren
  // Diese enthält alle Funktionen für die Fritzbox
  FBox := TFritzBox.Create;

end;
// Beim Schließen Objekt freigeben
procedure TAndroidModule1.AndroidModule1Close(Sender: TObject);
begin
  FBox.Free;
  Messages.Free;
end;

procedure TAndroidModule1.AndroidModule1Create(Sender: TObject);
begin
  Messages := TStringList.Create; // Speicher für LOG-Meldungen
end;
//Zurückblättern. Auf der Startseite App beenden.
procedure TAndroidModule1.AndroidModule1SpecialKeyDown(Sender: TObject;
  keyChar: char; keyCode: integer; keyCodeString: string; var mute: boolean);
begin
  if keyCode = 4 then  //KEYCODE_BACK
  begin
    if ActivePage <> 101 then
    begin
      ActivePage := 101;
      Self.jPanel3.BringToFront();
      mute := True; // App nicht schließen
    end;
  end;
end;
// Untere Navigation /Rechts/Links blättern
procedure TAndroidModule1.jsBottomNavigationView1ClickItem(Sender: TObject;
  itemId: integer; itemCaption: string);
begin

  if itemId = 101 then //Schaltfläche Rechts
  begin
    if ActivePage < 105 then
      jsNavigationView1ClickItem(jsNavigationView1, ActivePage + 1, '');
  end;

  if itemId = 102 then   //Schaltfläche Links
  begin
    if ActivePage > 101 then
      jsNavigationView1ClickItem(jsNavigationView1, ActivePage - 1, '');
  end;
end;
// Wisch-Gesten Rechts/Links blättern
procedure TAndroidModule1.jPanel2FlingGesture(Sender: TObject;
  flingGesture: TFlingGesture);
begin

  case flingGesture of
    fliLeftToRight:
    begin
      if ActivePage > 101 then
        jsBottomNavigationView1ClickItem(nil,102,''); //nach links
    end;

    fliRightToLeft:
    begin
      if ActivePage < 105 then
      jsBottomNavigationView1ClickItem(nil,101,''); // nach rechts
    end;

  end;
end;
// etwas Kosmetik
// Animation der Panels je nach Richtung einstellen
// siehe auch "AnimationDurationIn" (Geschwindigkeit der Animation)
// bei den Panels
procedure TAndroidModule1.SetAnimMode(Module: string; ItemID: integer);
var
  aForm: jForm;
  aPanel: JPanel;
begin
  //das jeweilige Modul suchen
  aForm := (gApp.FindComponent(Module) as jForm);

  // das jeweilige Panel suchen
  if ItemID = 101 then
  begin
    aPanel := (aForm.FindComponent('jPanel3') as JPanel);

  end
  else
  begin
    aPanel := (aForm.FindComponent('jPanel1') as JPanel);
  end;

  // Anmimation ändern von Rchts oder Links einblenden
  if ActivePage < ItemID then
    aPanel.AnimationMode := animRightToLeft
  else
  aPanel.AnimationMode := animLeftToRight;
  // aktive Seite ist jetzt die aktuelle Seite
  ActivePage := itemID;
  // Focus auf das Panel setzen
  aPanel.BringToFront();
end;
// Formulare erstellen AndroidModule2 bis AndroidModule5
// Das muss nur einmal geschehen,
// was durch dei Variable FormsCreated gesteuert wird
procedure TAndroidModule1.CreateForms;
begin
  if FormsCreated = True then   // bereits erledigt, also raus hier
    Exit;

  if AndroidModule2 = nil then
  begin
    // Anmerkung wg. actEasel werden die Formulare zunächst nicht angezeigt
    gApp.CreateForm(TAndroidModule2, AndroidModule2);
    AndroidModule2.Init(gApp);
  end;

  if AndroidModule3 = nil then
  begin
    gApp.CreateForm(TAndroidModule3, AndroidModule3);
    AndroidModule3.Init(gApp);
  end;
  if AndroidModule4 = nil then
  begin
    gApp.CreateForm(TAndroidModule4, AndroidModule4);
    AndroidModule4.Init(gApp);
  end;

  if AndroidModule5 = nil then
  begin
    gApp.CreateForm(TAndroidModule5, AndroidModule5);
    AndroidModule5.Init(gApp);
  end;
  FormsCreated := True;
end;

procedure TAndroidModule1.InitPanels;
begin
// Die Formular werden nicht direkt angezeigt.
// Stattdessen wird das Panel jPanel1 des jeweiligen Formulars
// ins Panel2 von AndroidModule1 geladen (Self.jPanel2)
// Diese Zuweisung *darf* nur einmal geschehen, was
// durch die Variable PanelsInit gesteuert wird.
// Ansonsten erhalten die Panel nicht immer den Focus.
  if PanelsInit = True then
    Exit;
  AndroidModule2.jPanel1.Parent := Self.jPanel2;
  AndroidModule2.jPanel1.SetViewParent(Self.jPanel2.View);

  AndroidModule3.jPanel1.Parent := Self.jPanel2;
  AndroidModule3.jPanel1.SetViewParent(Self.jPanel2.View);

  AndroidModule4.jPanel1.Parent := Self.jPanel2;
  AndroidModule4.jPanel1.SetViewParent(Self.jPanel2.View);

  AndroidModule5.jPanel1.Parent := Self.jPanel2;
  AndroidModule5.jPanel1.SetViewParent(Self.jPanel2.View);

  PanelsInit := True;
end;

// Navigation zur nächsten/vorherigen Seite/Modul
procedure TAndroidModule1.Navigate(itemID: integer);
begin
  // Die Formulare/Module werden erst jetzt geladen.
  // Das beschleunigt den Programmstart.
  CreateForms();
  // Panel1 der Formulare soll in Panel2 von AndroidModule1 erscheinen
  InitPanels();

  // Je nach ID anderes Modul/Formular laden
  if itemID = 101 then
  begin
    ActivePage := itemID;
    SetAnimMode('AndroidModule1', itemID);
  end;

  if itemID = 102 then
  begin
    AndroidModule2.LoadSettings; //Einstellungen in die Formularfelder laden
    SetAnimMode('AndroidModule2', itemID);
  end;

  if itemID = 103 then
  begin
    SetAnimMode('AndroidModule3', itemID);
  end;

  if itemID = 104 then
  begin
    SetAnimMode('AndroidModule4', itemID);
  end;

  if itemID = 105 then
  begin
    SetAnimMode('AndroidModule5', itemID);
  end;
  // das Menü schließen
  jsDrawerLayout1.CloseDrawers();
end;
//Rückgabe-Code einer SOAP-Abfrage z.B. für "Öffentliche IP ermitteln)
procedure TAndroidModule1.jHttpClient1CodeResult(Sender: TObject; code: integer);
begin
  Logger('Code: ' + IntToStr(code));
  WriteMessages;
end;
//Inhaltsergebnis einer SOAP-Abfrage z.B. für "Öffentliche IP ermitteln)
procedure TAndroidModule1.jHttpClient1ContentResult(Sender: TObject; content: string);
var
  RegexObj: TRegExpr;
  S: string;
begin
  Logger('SOAP-Content: ' + content);
  WriteMessages;

  if content <> '' then
  begin
    // NewExternalIPAddress auslesen
    RegexObj := TRegExpr.Create;
    try
      RegexObj.Expression := '(?si)<NewExternalIPAddress>(.*?)<\/NewExternalIPAddress>';
      S := '';
      if RegexObj.Exec(content) then
      begin
        S := RegexObj.Match[1];
      end;
      if S <> '' then
        Logger('Öffentliche IP: ' + S);
      WriteMessages;
      ShowMessage('Öffentliche IP: ' + S + ' (siehe log)');
    finally
      RegexObj.Free;
    end;
  end;
end;

// Öffentliche IP-Adresse ermitteln
// Dafür ist keine Anmeldung bei der Fritzbox erforderlich
procedure TAndroidModule1.GetExternalIP();
begin
{$IFDEF ANDROID}
  CreateForms();
  FBox.OnLogMsg := Logger2;
  FBox.ServiceURL := FBOXURL + ':49000/igdupnp/control/WANIPConn1';
  FBox.FboxGetExternalIP();
  //WriteMessages;
{$ENDIF ANDROID}

{$IFDEF Linux}
  Memo2.Clear;
  FBOXURL := Trim(edtURL.Text);
  FBox.OnLogMsg := @Logger2;
  FBox.ServiceURL := FBOXURL + ':49000/igdupnp/control/WANIPConn1';
  FBox.FboxGetExternalIP();
  Memo2.Text := 'Externe IP: ' + FBox.ExternalIP;
 {$ENDIF Linux}
end;
// Zu einer Seite blättern
procedure TAndroidModule1.jsNavigationView1ClickItem(Sender: TObject;
  itemId: integer; itemCaption: string);
begin
  Navigate(itemID);
end;
// Menü über das Icon links oben öffnen
procedure TAndroidModule1.jsToolbar1ClickNavigationIcon(Sender: TObject);
begin
  jsDrawerLayout1.OpenDrawer();
end;
// Einstellungen speichern
procedure TAndroidModule1.SaveSettings();
begin

  if (LeftStr(FBOXURL, 7) <> 'http://') and (LeftStr(FBOXURL, 8) <> 'https://') then
    FBOXURL := 'http://' + FBOXURL;
  jPreferences1.SetStringData('FritzboxURL', FBOXURL);
  jPreferences1.SetStringData('User', Username);
  if SavePassword = True then
  begin
    //Passwort unverschlüsselt speichern
    //jPreferences1.SetStringData('Password', Password)

    //Passwort verschlüsselt speichern
    jPreferences1.SetStringData('Password', EncryptString(Password));
  end
  else
    jPreferences1.SetStringData('Password', ''); //Passwort löschen

  jPreferences1.SetBoolData('SavePassword', SavePassword);
  jPreferences1.SetBoolData('DebugLog', DebugLog);
end;
// Einstellungen laden
procedure TAndroidModule1.LoadSettings();
begin
  FBOXURL := jPreferences1.GetStringData('FritzboxURL', '');
  if (LeftStr(FBOXURL, 7) <> 'http://') and (LeftStr(FBOXURL, 8) <> 'https://') then
    FBOXURL := 'http://' + FBOXURL;

  Username := jPreferences1.GetStringData('User', '');
  SavePassword := jPreferences1.GetBoolData('SavePassword', False);
  if SavePassword = True then
    Password := DecryptString(jPreferences1.GetStringData('Password', ''));
  //Password := jPreferences1.GetStringData('Password', '');

  DebugLog := jPreferences1.GetBoolData('DebugLog', False);
end;
//Hier startet die Abfrage der Fritzbox
procedure TAndroidModule1.jsFloatingButton1Click(Sender: TObject);

begin
  {$IFDEF Linux}
  FBOXURL := Trim(edtURL.Text);
  if (LeftStr(FBOXURL, 7) <> 'http://') and (LeftStr(FBOXURL, 8) <> 'https://') then
    FBOXURL := 'http://' + FBOXURL;
  edtURL.Text := FBOXURL;

  Username := Trim(edtUserName.Text);
  Password := Trim(edtPassword.Text);
  Memo1.Clear;

  FBox.OnLogMsg := @Logger2;
{$ENDIF Linux}
{$IFDEF ANDROID}
  // Die anderen Module müssen geladen sein.
  // Sonst lässen sich die Formularelemente nicht füllen
  CreateForms();
  // Zurück zur Startseite
  if ActivePage <> 101 then
    Navigate(101);
  //Den Logger-Event festlegen
  FBox.OnLogMsg := Logger2;
  // Alte Log-Meldungen löschen
  Messages.Clear;

  AndroidModule5.btnGetCallList.Enabled := False;
  // Listenelemente löschen
  AndroidModule4.lv.Clear();
  // Panel vorübergehend ausblenden (anti-flackern)
  pnlSwitches.Visible := False;


{$ENDIF ANDROID}
  // dei URL der Fritzbox wie konfiguriert
  Fbox.FBOXURL := FBOXURL;
  try
    FBox.LogIn(Username, Password);  //Anmelden
  except
    on E: Exception do
      Logger(e.Message);

  end;
  TheSid := FBox.SID;

  // Anmeldung blockert?
  if Fbox.BlockTime <> '0' then
  begin
    ShowMessage('Die Anmeldung ist noch blockiert für: ' + Fbox.BlockTime +
      ' Sekunden.');
  end
  else
  begin
    if TheSid <> '0000000000000000' then  // Bei erfolgreicher Anmeldung
    begin

   {$IFDEF Linux}
      btnCallList.Enabled := True;
  {$ENDIF Linux}
      // Die Service-URL für SmartHome
      FBox.ServiceURL := FBOXURL + '/webservices/homeautoswitch.lua?sid=' +
        FBox.SID + '&switchcmd=getdevicelistinfos';

      FBox.FboxGetURL();
      if FBox.State = 200 then  // erfolgreich
      begin
        Logger('Antwort DeviceList: ' + FBox.Response);
        FBReadData(FBox.Response);
        {$IFDEF ANDROID}
        AndroidModule5.btnGetCallList.Enabled := True;
        AndroidModule1.pnlSwitches.Visible := True;
        {$ENDIF ANDROID}
      end
      else
      begin
         {$IFDEF ANDROID}
        // keine DeviceList, keine Smarthome-Funktion
        // SID OK daher CallList (AndroidModule5) möglich
        AndroidModule5.btnGetCallList.Enabled := True;
        jTextView1.Text := 'Keine Smarthome-Funktion vorhanden? Siehe log.';
        ShowMessage('Keine Smarthome-Funktion vorhanden? Siehe log.');
         {$ENDIF ANDROID}
        Logger('Keine Smarthome-Funktion vorhanden oder URL nicht gefunden, Fehler: '
          + IntToStr(FBox.State));
      end;
    end
    else
    begin
      Logger('Fehler: Konnte keine Verbindung herstellen. Fehlercode: ' +
        IntToStr(FBox.State));
      ShowMessage('Fehler: Konnte keine Verbindung herstellen. Fehlercode: ' +
        IntToStr(FBox.State));
    end;
  end;
  WriteMessages;
end;
// Schalter umschalten
procedure TAndroidModule1.aSwitchSwitch(Sender: TObject; state: boolean);
var
  AIN: string;
  Index: integer;
begin
  Index := jSwitchButton(Sender).Tag;
  AIN := DeviceList[Index].AIN;
  ToogleSwitch(AIN, 'setswitchtoggle');
end;


{$IFDEF Linux}
procedure TAndroidModule1.aSwitchSwitch(Sender: TObject);
var
  AIN: string;
  Index: integer;
begin
  Index := TEcSwitch(Sender).tag;
  AIN := DeviceList[Index].AIN;
  Application.ProcessMessages;
  ToogleSwitch(AIN, 'setswitchtoggle');
  Logger(AIN + ' umschalten');
end;

{$ENDIF Linux}
//Daten der Schalter einlesen
procedure TAndroidModule1.FBReadData(response: string);
var
  Doc: TXMLDocument;
  I, J: integer;
  Stream: TStringStream;
  numDevices: integer;
  iNode: TDOMNode;
  SwitchData: TSmartData;
  has_switch, has_temperatur: boolean;
{$IFDEF Linux}
  aSwitch: TECSwitch;
  Item0: TTreeNode;
  Item1: TTreeNode;
  Item2: TTreeNode;
  Item3: TTreeNode;
{$ENDIF Linux}
{$IFDEF ANDROID}
  LVItems: string;
{$ENDIF ANDROID}
  // XML-Datei auswerten
  procedure ProcessNode(Node: TDOMNode);
  var
    cNode: TDOMNode;
    tmpNode: TDOMNode;
    aktTemp: extended;
    aktPower: extended;
    BitMask: integer;
  begin
    if Node = nil then
      Exit;
    with Node do
    begin
      if NodeName = 'name' then
      begin
        SwitchData.Name := Node.FirstChild.NodeValue;
      end;

      if NodeName = 'device' then
      begin
        SwitchData.AIN := Attributes.GetNamedItem('identifier').NodeValue;
        SwitchData.functionbitmask :=
          Attributes.GetNamedItem('functionbitmask').NodeValue;
        BitMask := StrToInt(SwitchData.functionbitmask);
        has_switch := BitMask and (1 shl 9) <> 0;
        has_temperatur := BitMask and (1 shl 8) <> 0;

        if has_switch then
          SwitchData.HasSwitch := 1
        else
          SwitchData.HasSwitch := 0;

        if has_temperatur then
          SwitchData.HasTemperature := 1
        else
          SwitchData.HasTemperature := 0;
        SwitchData.Productname := Attributes.GetNamedItem('productname').NodeValue;
      end;


      if NodeName = 'state' then
      begin
        tmpNode := Node.FirstChild;
        if tmpNode <> nil then
        begin
          if tmpNode.NodeValue <> '' then
          begin

            SwitchData.State := tmpNode.NodeValue;
          end;
        end;
      end;


      if NodeName = 'celsius' then
      begin
        tmpNode := Node.FirstChild;
        if tmpNode <> nil then
        begin
          if tmpNode.NodeValue <> '' then
          begin
            aktTemp := StrToFloat(tmpNode.NodeValue) / 10;
            SwitchData.Celsius := FloatToStrF(aktTemp, ffFixed, 2, 1, formatSettings);
          end;
        end;
      end;

      if NodeName = 'tsoll' then
      begin
        tmpNode := Node.FirstChild;
        if tmpNode <> nil then
        begin
          if tmpNode.NodeValue <> '' then
          begin
            if tmpNode.NodeValue = '254' then
            begin
              SwitchData.SollTemperatur := 'ein';
            end
            else if tmpNode.NodeValue = '253' then
            begin
              SwitchData.SollTemperatur := 'aus';
              Exit;
            end
            else
            begin
              aktTemp := StrToFloat(tmpNode.NodeValue) * 0.5;
              SwitchData.SollTemperatur :=
                FloatToStrF(aktTemp, ffNumber, 18, 1, formatSettings);
            end;
          end;
        end;
      end;

      if NodeName = 'power' then
      begin
        tmpNode := Node.FirstChild;
        if tmpNode <> nil then
        begin
          if tmpNode.NodeValue <> '' then
          begin
            aktPower := StrToFloat(tmpNode.NodeValue) / 1000;
            Str(aktPower: 6: 2, SwitchData.Power);
          end;
        end;
      end;

      if NodeName = 'present' then
      begin
        tmpNode := Node.FirstChild;
        if tmpNode <> nil then
        begin
          if tmpNode.NodeValue <> '' then
            SwitchData.Present := tmpNode.NodeValue;
        end;
      end;

      cNode := Node.FirstChild;
      while cNode <> nil do
      begin
        ProcessNode(cNode);
        cNode := cNode.NextSibling;
      end;
    end;
  end;

begin
 {$IFDEF Linux}
  Treeview1.Items.Clear;
  ClearScrollbox;
 {$ENDIF Linux}
 {$IFDEF ANDROID}
  // Alles zuvor generierten Schalter entfernen
  ClearSwitchPanel;

 {$ENDIF ANDROID}
  SetLength(DeviceList, 0);
  // Verbindung erfolgreich?
  if TheSID <> '0000000000000000' then
  begin
     {$IFDEF ANDROID}
    jsFloatingButton1.BackgroundColor := colbrOliveDrab;
      {$ENDIF ANDROID}
    Stream := TStringStream.Create(response);
    try
      ReadXMLFile(Doc, Stream); //XML-Daten einlesen
      i := 0;
      J := 0;
      numDevices := Doc.DocumentElement.ChildNodes.Count;
      Logger('Geräte gefunden:' + IntToStr(numDevices));
      if numDevices = 0 then
      begin
        Logger('Fehler: Konnte Geräteliste nicht von der Fritzbox laden.');
        ShowMessage('Fehler: Konnte Geräteliste nicht von der Fritzbox laden.');
        Exit;
      end;

      SetLength(DeviceList, numDevices);
      iNode := Doc.DocumentElement.FirstChild;

      while iNode <> nil do
      begin
        Logger('=============');

        ProcessNode(iNode);

        DeviceList[i] := SwitchData;
        Logger('Name: ' + SwitchData.Name + ' AIN: ' + SwitchData.AIN);
        Logger('Verbunden: ' + SwitchData.Present);
        Logger('Ist Schalter: ' + IntToStr(SwitchData.HasSwitch));
        if SwitchData.State <> '' then
          Logger('Status ist: ' + SwitchData.State);
        Logger('Liefert Temperatur: ' + IntToStr(SwitchData.HasTemperature));

        if SwitchData.HasSwitch = 1 then
        begin
           {$IFDEF Linux}
          aSwitch := TECSwitch.Create(Self);
          aSwitch.Height := 25;
          aSwitch.Top := 1 + i * 30;
          aSwitch.Tag := i;
          aSwitch.Name := 'Switch' + IntToStr(i);
          aSwitch.Caption := SwitchData.Name;

          if SwitchData.State = '0' then
            aSwitch.Checked := False;
          if SwitchData.State = '1' then
            aSwitch.Checked := True;

          aSwitch.OnClick := @aSwitchSwitch;
          aSwitch.Parent := ScrollBox1;
          Inc(J);
          if SwitchData.Present = '0' then
            aSwitch.Enabled := False;
          {$ENDIF Linux}
          {$IFDEF ANDROID}
          // Schalter in pnlSwitches hinzufügen
          // Hinweis: Es muss sich ein Schalter (jSwitchButton)
          // auf dem Formular befinden, damit das funktioniert
          AddControls(I, SwitchData.Name, SwitchData.State, SwitchData.Present);

          {$ENDIF ANDROID}

        end;
        {$IFDEF ANDROID}
        // Detail-Infos für die Liste
        // in AndroidModule4
        LVItems := 'Modell: ' + SwitchData.Productname;
        if SwitchData.HasTemperature = 1 then
        begin
          LVItems := LVItems + ';Temperatur: ' + SwitchData.Celsius + ' °C';
        end;
        if SwitchData.Power <> '' then
        begin
          LVItems := LVItems + ';Aktuelle Leistung: ' + SwitchData.Power + ' Watt';
        end;
        if SwitchData.State = '0' then
          LVItems := LVItems + ';Schalter-Status: Aus'
        else
          LVItems := LVItems + ';Schalter-Status: An';

        // Infos hinzufügen
        AndroidModule4.lv.Add(SwitchData.Name, LVItems);
        //Logger(LVItems);
        {$ENDIF ANDROID}

        {$IFDEF Linux}
        Item0 := TreeView1.Items.Add(nil, 'Fritzbox');
        Item1 := TreeView1.Items.AddChild(item0, '');
        Item1.Text := SwitchData.Name;
        Item2 := TreeView1.Items.AddChild(item1, '');
        Item2.Text := 'Modell: ' + SwitchData.Productname;


        if SwitchData.HasTemperature = 1 then
        begin

          if SwitchData.Celsius <> '' then
          begin
            Item2 := TreeView1.Items.AddChild(item1, '');
            Item2.Text := 'Temperatur: ' + SwitchData.Celsius + ' °C';

          end;
        end;

        if SwitchData.SollTemperatur <> '' then
        begin
          Item2 := TreeView1.Items.AddChild(item1, '');
          if SwitchData.SollTemperatur = 'aus' then
            Item2.Text := 'Soll-Temperatur: ' + SwitchData.SollTemperatur
          else if SwitchData.SollTemperatur = 'ein' then
            Item2.Text := 'Soll-Temperatur: ' + SwitchData.SollTemperatur
          else
            Item2.Text :=
              'Soll-Temperatur: ' + SwitchData.SollTemperatur + ' °C';

        end;
        if SwitchData.Power <> '' then
        begin
          Item2 := TreeView1.Items.AddChild(item1, '');
          Item2.Text := 'Aktuelle Leistung: ' + SwitchData.Power + ' Watt';

        end;

        if SwitchData.Present = '0' then
        begin
          Item2 := TreeView1.Items.AddChild(item1, '');
          Item2.Text := 'Verbunden: Nein';

        end;
        if SwitchData.Present = '1' then
        begin
          Item2 := TreeView1.Items.AddChild(item1, '');
          Item2.Text := 'Verbunden: Ja';

        end;
           {$ENDIF Linux}

        Inc(i);
        // Alte Daten löschen
        SwitchData.Name := '';
        SwitchData.AIN := '';
        SwitchData.Present := '';
        SwitchData.State := '';
        SwitchData.HasSwitch := 0;
        SwitchData.HasTemperature := 0;
        SwitchData.functionbitmask := '';
        SwitchData.Celsius := '';
        SwitchData.Power := '';
        SwitchData.Productname := '';
        SwitchData.SollTemperatur := '';
        SwitchData.IsComet := 0;
        iNode := iNode.NextSibling;
      end;
    finally
      Stream.Free;
      Doc.Free;
    end;
  end
  else
  begin
    Logger('Konnte keine Verbindung herstellen');
  end;

end;
//Log-Meldungen ausgeben
procedure TAndroidModule1.WriteMessages();
var
  I: integer;
begin
{$IFDEF ANDROID}
  AndroidModule3.edtLog.Text := '';
{$ENDIF ANDROID}
  if Messages.Count > 0 then
  begin

    for I := 0 to Messages.Count - 1 do
    begin
     {$IFDEF ANDROID}
      AndroidModule3.edtLog.AppendLn(Messages.Strings[I]);
     {$ENDIF ANDROID}
     {$IFDEF Linux}
      Memo1.Lines.Add(Messages.Strings[I]);
     {$ENDIF Linux}

    end;
  end;
end;
// Schalter umschalten
procedure TAndroidModule1.ToogleSwitch(AIN: string; Command: string);
begin
  Fbox.FBOXURL := FBOXURL;
  FBox.LogIn(Username, Password);
  TheSid := FBox.SID;
  FBox.ServiceURL := FBOXURL + '/webservices/homeautoswitch.lua' +
    '?sid=' + FBox.SID + '&ain=' + AIN + '&switchcmd=' + Command;
  FBox.FboxGetURL();
end;
// Schalter und Beschriftungen hinzufügen
procedure TAndroidModule1.AddControls(num: integer; SwitchName, State, Present: string);
var
  ajTextView: jTextView;
  myjTextView: jTextView;
  ajPanel: JPanel;
  myjPanel: JPanel;
  ajSwitch: jSwitchButton;
begin
  ajPanel := jPanel.Create(self);
  ajPanel.Parent := pnlSwitches;
  ajPanel.LayoutParamHeight := lpWrapContent;
  ajPanel.LayoutParamWidth := lpMatchParent;

  if num = 0 then
  begin
    ajPanel.PosRelativeToParent := [rpTop];
  end

  else
  begin
    myjPanel := (AndroidModule1.FindComponent('SwitchPanel' + IntToStr(num - 1)) as JPanel);
    ajPanel.Anchor := myjPanel;
    ajPanel.PosRelativeToAnchor := [raBelow];
  end;
  ajPanel.Name := 'SwitchPanel' + IntToStr(num);
  ajPanel.SetMarginLeftTopRightBottom(10, 25, 25, 25);
  ajPanel.Init(gApp);

  myjPanel := (AndroidModule1.FindComponent('SwitchPanel' + IntToStr(num)) as JPanel);

  ajTextView := jTextView.Create(Self);
  ajTextView.Parent := myjPanel;


  if num = 0 then
    ajTextView.PosRelativeToParent := [rpTop, rpLeft]

  else
  begin
    myjTextView := (AndroidModule1.FindComponent('lblSwitch' + IntToStr(num - 1)) as
      JTextView);
    ajTextView.Anchor := myjTextView;
    ajTextView.PosRelativeToAnchor := [raBelow];
    ajTextView.PosRelativeToParent := [rpLeft];
  end;

  if Present = '0' then
    ajTextView.Text := SwitchName + ' (nicht verbunden)'
  else
    ajTextView.Text := SwitchName;

  ajTextView.Name := 'lblSwitch' + IntToStr(num);
  ajTextView.FontSize := 16;
  ajTextView.MarginLeft := 10;
  ajTextView.MarginRight := 50;


  ajTextView.Init(gApp);


  myjTextView := (AndroidModule1.FindComponent('lblSwitch' + IntToStr(num)) as JTextView);


  ajSwitch := jSwitchButton.Create(self);
  ajSwitch.Parent := myjPanel;

  ajSwitch.Name := 'mySwitch' + IntToStr(num);


  if Present = '1' then
    ajSwitch.Visible := True
  else
    ajSwitch.Visible := False;

  if State = '0' then
    ajSwitch.State := tsOff
  else
    ajSwitch.State := tsOn;

  ajSwitch.Tag := num;
  ajSwitch.OnToggle := aSwitchSwitch;
  ajSwitch.PosRelativeToParent := [rpEnd];

  ajSwitch.Init(gApp);

end;
// Schalter entfernen (vor der Neuverbindung)
procedure TAndroidModule1.ClearSwitchPanel();
var
  I: integer;
begin
  for I := Length(DeviceList) - 1 downto 0 do
  begin
    if DeviceList[i].HasSwitch = 1 then
      (AndroidModule1.FindComponent('SwitchPanel' + IntToStr(i)) as jPanel).Free;
  end;

end;
// Log-Meldungen speichern
procedure TAndroidModule1.Logger(msg: string);
begin
  if DebugLog = True then
  begin

 {$IFDEF ANDROID}
    Messages.Add(msg);
{$ENDIF ANDROID}
{$IFDEF Linux}
    Memo1.Lines.Add(msg);
{$ENDIF Linux}
  end;
end;
// Fehler loggen
procedure TAndroidModule1.Logger2(Sender: TObject; EMessage: string);
begin
  Logger(EMessage);
end;


end.
