// Die Angaben

// {$IFDEF ANDROID}
// {$ENDIF ANDROID}

// {$IFDEF Linux}
// {$ENDIF Linux}

// sollen nur die wichtigsten Unterschiede zum Code für Linux/Windows zeigen
// und sind nicht vollständig.
// Der Code lässt sich nicht immer 1:1 von Android für Linux übernehmen.

unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ComCtrls,
  ExtCtrls, XMLPropStorage, Menus, ECSwitch, laz2_XMLRead, laz2_DOM, fritzbox,
  BlowFish, base64;

type

  { TForm1 }

  TForm1 = class(TForm)
    btnConnect: TButton;
    Button1: TButton;
    btnCallList: TButton;
    btnExternalIP: TButton;
    chkSavePassword: TCheckBox;
    chkShowPassword: TCheckBox;
    chkDebug: TCheckBox;
    ECSwitch1: TECSwitch;
    edtPassword: TEdit;
    edtURL: TEdit;
    edtUserName: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Memo1: TMemo;
    Memo2: TMemo;
    mnuExpand: TMenuItem;
    mnuCollapse: TMenuItem;
    PageControl1: TPageControl;
    Panel1: TPanel;
    Panel2: TPanel;
    TreePop: TPopupMenu;
    ScrollBox1: TScrollBox;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    TabSheet3: TTabSheet;
    TabSheet4: TTabSheet;
    TreeView1: TTreeView;
    XMLPropStorage1: TXMLPropStorage;
    procedure btnCallListClick(Sender: TObject);
    procedure btnConnectClick(Sender: TObject);
    procedure btnExternalIPClick(Sender: TObject);
    procedure chkShowPasswordClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure aSwitchSwitch(Sender: TObject);
    procedure FBReadData(response:String);
    procedure mnuCollapseClick(Sender: TObject);
    procedure mnuExpandClick(Sender: TObject);
    Procedure WriteMessages();
    Procedure Connect;


    {$IFDEF ANDROID}
    procedure AddControls(num:Integer;SwitchName, State,Present:String);
    procedure ClearSwitchPanel();
    {$ENDIF ANDROID}
    {$IFDEF Linux}
    procedure ClearScrollbox();
    procedure XMLPropStorage1RestoreProperties(Sender: TObject);
    procedure XMLPropStorage1SaveProperties(Sender: TObject);
    {$ENDIF Linux}
           {$IFDEF Windows}
    procedure ClearScrollbox();
    procedure XMLPropStorage1RestoreProperties(Sender: TObject);
    procedure XMLPropStorage1SaveProperties(Sender: TObject);
           {$ENDIF Windows}
           {$IFDEF Windows}

           {$ENDIF Windows}
  private
    procedure Logger2(Sender: TObject; EMessage: String);
  public
    procedure Logger(msg:String);
    procedure ToogleSwitch(AIN: String;Command:String);
  end;

type
  // Record für die Werte der SmartHome-Schalter
  TSmartData = record
    Name: String;
    AIN: String;
    Present: STring;
    State: String;
    HasSwitch:Integer;
    Celsius:String;
    Power:String;
    Productname:String;
    HasTemperature:Integer;
    functionbitmask:String;
    SollTemperatur:String;
    IsComet:Integer;   //Comet Dect, wird nicht ausgewertet
    IsLamp:Integer; //Lampen
  end;
var
  Form1: TForm1;
  TheSid:String;
  FBOXURL:String;
  Username:String;
  Password:String;
  DeviceList: Array of TSmartData;
  FBox:TFritzBox;
  Messages: TStringList;

implementation

{$R *.lfm}

{ TForm1 }


// Veschlüsselung für Passwort
// Diese einfache Veschlüsselung verbirgt das Passwort
// in der Konfigurationsdatei vor den Augen unbefugter Personen
// und erfüllte keine geltenden Sicherheitsstandards.
function EncryptString(aString:string):string;
var Key:string;
    EncrytpStream:TBlowFishEncryptStream;
    StringStream:TStringStream;
    EncryptedString:RawByteString;
    B64String: String;
begin
  if aString ='' Then Exit;
  Key := 's6v9y$B&E)H@McQfTjWnZq4t7w!z%C*F';  //sollte geändert werden
  StringStream := TStringStream.Create('');
  EncrytpStream := TBlowFishEncryptStream.Create(Key,StringStream);
  try
   EncrytpStream.WriteAnsiString(aString);
   EncrytpStream.Flush;
   EncryptedString := StringStream.DataString;
   B64String := EncodeStringBase64(EncryptedString);
  finally
    EncrytpStream.Free;
    StringStream.Free;
  end;
  EncryptString := B64String;
end;
// Passwort entschlüsseln
function DecryptString(aString:string):string;
var Key:string;
    DecrytpStream:TBlowFishDeCryptStream;
    StringStream:TStringStream;
    DecryptedString:string;
    B64String: RawByteString;
begin
  if aString ='' Then Exit;
  Key := 's6v9y$B&E)H@McQfTjWnZq4t7w!z%C*F';  //sollte geändert werden, gleicher Schlüssel wie oben
  B64String := DecodeStringBase64(aString, False);
  StringStream := TStringStream.Create(B64String);
  try
    DecrytpStream := TBlowfishDecryptStream.Create(key, StringStream);
    DecryptedString := DecrytpStream.ReadAnsiString;
  finally
    DecrytpStream.Free;
    StringStream.Free;
  end;
  DecryptString := DecryptedString;
end;
//Hier startet die Abfrage der Fritzbox, SmartHome
procedure TForm1.Connect;
begin
{$IFDEF Linux}
 FBOXURL:=Trim(edtURL.Text);
 if (LeftStr(FBOXURL,7) <> 'http://') AND (LeftStr(FBOXURL,8) <> 'https://')then
 FBOXURL:='http://' + FBOXURL;
 edtURL.Text:=FBOXURL;
 Username:=Trim(edtUserName.Text);
 Password:=Trim(edtPassword.Text);
 Memo1.Clear;
 btnCallList.Enabled:=False;
 PageControl1.ActivePageIndex:=0;
 FBox.OnLogMsg:=@Logger2;

{$ENDIF Linux}
{$IFDEF Windows}
//ShowMessage('Con');

FBOXURL:=Trim(edtURL.Text);
if (LeftStr(FBOXURL,7) <> 'http://') AND (LeftStr(FBOXURL,8) <> 'https://')then
FBOXURL:='http://' + FBOXURL;
edtURL.Text:=FBOXURL;
Username:=Trim(edtUserName.Text);
Password:=Trim(edtPassword.Text);
Memo1.Clear;
btnCallList.Enabled:=False;
PageControl1.ActivePageIndex:=0;
FBox.OnLogMsg:=@Logger2;

{$ENDIF Windows}
{$IFDEF ANDROID}
 FBox.OnLogMsg:=Logger2; //delphi mode
{$ENDIF ANDROID}
 Messages.Clear;
 // die URL der Fritzbox wie konfiguriert
 Fbox.FBOXURL:=FBOXURL;
 FBox.OnLogMsg:=@Logger2;  //Ereignis für Meldungen
 btnConnect.Enabled:=False;
 Application.ProcessMessages;

 try
 FBox.LogIn(Username, Password);  //Anmelden

 If Fbox.State<>200 Then
 begin
   Logger('Fehler : ' + IntToStr(FBox.State));
    ShowMessage(TheSid);
   Exit;
 end;

 TheSid:=FBox.SID;
 Logger('Status Anmeldung: ' + IntToStr(FBox.State));
 Logger('Fritzbox-Antwort : ' + FBox.Response);
 Logger('Fritzbox-Status : ' +  IntToStr(FBox.State));

 WriteMessages;
  // Anmeldung blockert?
 if Fbox.BlockTime <> '0' Then
   begin
    ShowMessage('Die Anmeldung ist noch blockiert für: ' + Fbox.BlockTime + ' Sekunden.');
   end
   else
   begin

 If TheSid<>'0000000000000000' Then   // Bei erfolgreicher Anmeldung
 begin
 {$IFDEF Linux}
    btnCallList.Enabled := True;
 {$ENDIF Linux}
 {$IFDEF Windows}
    btnCallList.Enabled := True;
 {$ENDIF Windows}
 // Die Service-URL für SmartHome
 FBox.ServiceURL:=FBOXURL + '/webservices/homeautoswitch.lua?sid=' +
   FBox.SID + '&switchcmd=getdevicelistinfos';

 FBox.FboxGetURL();

 if FBox.State = 200 Then  // erfolgreich
 begin
 Logger('Antwort DeviceList: ' + FBox.Response);
 FBReadData(FBox.Response);
   {$IFDEF ANDROID}
    AndroidModule5.btnGetCallList.Enabled := True;
    AndroidModule1.pnlSwitches.Visible:=True;
  {$ENDIF ANDROID}
  end
  else
  begin
  // keine DeviceList, keine Smarthome-Funktion
  // SID OK daher CallList (AndroidModule5) möglich
  Logger('Keine Smarthomefunktion vorhanden oder URL nicht gefunden, Fehler: ' + IntToStr(FBox.State));
  ShowMessage('Keine Smarthomefunktion vorhanden oder URL nicht gefunden, Fehler: ' + IntToStr(FBox.State));
  end;
 end
 else
 begin
   ShowMessage('Fehler: Konnte keine Verbindung herstellen. Fehlercode: ' + IntToStr(FBox.State));
 end;
end;
 finally
    btnConnect.Enabled:=True;
 end;

end;


procedure TForm1.btnConnectClick(Sender: TObject);
begin
Connect;
end;
//Meldungen in Memo1 ausgeben
procedure TForm1.WriteMessages();
var
   I:Integer;
begin
{$IFDEF ANDROID}
AndroidModule3.edtLog.Text:='';
{$ENDIF ANDROID}
  If Messages.Count>0 Then
  begin

    For I:=0 To Messages.Count -1 do
    begin
     {$IFDEF ANDROID}
     AndroidModule3.edtLog.AppendLn(Messages.Strings[I]);
     {$ENDIF ANDROID}
     {$IFDEF Linux}
     Memo1.Lines.Add(Messages.Strings[I]);
     {$ENDIF Linux}
     {$IFDEF Windows}
     Memo1.Lines.Add(Messages.Strings[I]);
     {$ENDIF Windows}

    end;
end;

end;
// Öffentliche IP-Adresse ermitteln (nur im lokalen Netzwerk)
// Dafür ist keine Anmeldung bei der Fritzbox erforderlich
procedure TForm1.btnExternalIPClick(Sender: TObject);
begin
Memo2.Clear;
 FBOXURL:=Trim(edtURL.Text);
 FBox.OnLogMsg:=@Logger2;
 FBox.ServiceURL:=FBOXURL +':49000/igdupnp/control/WANIPConn1' ;
 FBox.FboxGetExternalIP();
 WriteMessages;
 If FBox.ExternalIP='' Then
 Memo2.Text:='Konnte öffentliche IP nicht ermitteln'
 else
 Memo2.Text:='Externe IP: '+ FBox.ExternalIP;
end;
procedure TForm1.chkShowPasswordClick(Sender: TObject);
begin

 if chkShowPassword.Checked Then
   edtPassword.PasswordChar:=#0
 else
  edtPassword.PasswordChar:='*';
end;
//Anruferliste abfragen
procedure TForm1.btnCallListClick(Sender: TObject);
begin
 Memo2.Clear;
 FBox.LogIn(Username, Password);
 TheSid:=FBox.SID;
 FBox.ServiceURL:=FBOXURL + '/fon_num/foncalls_list.lua?sid=' + TheSID + '&csv=';
 FBox.FboxGetURL();
 Memo2.text:= FBox.Response;
end;
//Programme beenden, Objekte freigeben
procedure TForm1.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  XMLPropStorage1.Save;
  Messages.Free;
  FBox.Free;
end;
//
procedure TForm1.FormCreate(Sender: TObject);
var
   AIN,Command: String;
begin
  TheSID:='0000000000000000';
  FBox:=TFritzBox.Create;
  Messages:=TStringList.Create;
  PageControl1.ActivePageIndex:=0;

  //command line usage
  If Application.HasOption('h','help') Then begin
   Form1.WindowState:=wsMinimized;
   ShowMessage('Hilfe: ' + Chr(13) +
      '-s AIN' + Chr(13) +
      '-c Command [on|off|toggle]' + Chr(13) + Chr(13) +
      'Beispiel: SmartFritzSchalter -s 12345 6789000 -c on' + Chr(13) +
      'schaltet Schalter mit der AIN 12345 6789000 ein'
      );
    Application.Terminate;
   end;
   If Application.HasOption('s','') Then begin
     AIN:=Application.GetOptionValue('s','');
       If Application.HasOption('c','') Then begin
         Command:=Application.GetOptionValue('c','');
         Form1.WindowState:=wsMinimized;
         XMLPropStorage1.Restore;
         Connect;

         if Command='on' Then
           ToogleSwitch(AIN, 'setswitchon');
         if Command='off' Then
           ToogleSwitch(AIN, 'setswitchoff');
         if Command='toggle' Then
          ToogleSwitch(AIN, 'setswitchtoggle');
         Application.Terminate;
       end;
   end;
end;
//Schalter ermitteln und dann umschalten
procedure TForm1.aSwitchSwitch(Sender: TObject);
var
AIN:String;
Index: Integer;
begin
 Index:=TEcSwitch(Sender).tag;
 AIN:=DeviceList[Index].AIN;
 Application.ProcessMessages;
 ToogleSwitch(AIN, 'setswitchtoggle');
 Logger(AIN + ' umschalten');
end;
//Schalter schalten
procedure TForm1.ToogleSwitch(AIN: String; Command: String);
begin
 Fbox.FBOXURL:=FBOXURL;
 FBox.LogIn(Username, Password);
 TheSid:=FBox.SID;
 FBox.ServiceURL:=FBOXURL + '/webservices/homeautoswitch.lua' + '?sid=' + FBox.SID + '&ain=' + AIN + '&switchcmd=' + Command;
 FBox.FboxGetURL();

end;

//Daten der Schalter einlesen
procedure TForm1.FBReadData(response:String);
var
 Doc:TXMLDocument;
 I:Integer;
 Stream : TStringStream;
 numDevices:Integer;
 iNode:TDOMNode;
 SwitchData:TSmartData;
 has_switch, has_temperatur: Boolean;
 is_lamp, is_han_fun,is_han_fun_unit, is_color_unit:Boolean;
{$IFDEF Linux}
aSwitch: TECSwitch;
 Item0 : TTreeNode;
 Item1 : TTreeNode;
 Item2 : TTreeNode;
{$ENDIF Linux}
{$IFDEF Windows}
aSwitch: TECSwitch;
 Item0 : TTreeNode;
 Item1 : TTreeNode;
 Item2 : TTreeNode;
{$ENDIF Windows}
{$IFDEF ANDROID}
 aSwitch:JSwitchButton;
 LVItems:String;
 mySwitch: JSwitchButton;
 myTextView: JTextView;
{$ENDIF ANDROID}
    // XML-Datei auswerten
  procedure ProcessNode(Node: TDOMNode);
  var
  cNode: TDOMNode;
  tmpNode: TDOMNode;
  aktTemp:Extended;
  aktPower:Extended;
  BitMask: integer;

  begin
   if Node = nil then Exit;
      with Node do
     begin
      if NodeName='name' then
        begin
        //Logger(NodeName);
        SwitchData.Name:=Node.FirstChild.NodeValue;
        end;

        if NodeName='device' then
        begin
          SwitchData.AIN:=Attributes.GetNamedItem('identifier').NodeValue;
          SwitchData.functionbitmask:=Attributes.GetNamedItem('functionbitmask').NodeValue;
          BitMask := StrToInt(SwitchData.functionbitmask);
          has_switch:=BitMask AND (1 shl 9) <> 0;
          has_temperatur := BitMask AND (1 shl 8) <> 0;
          is_lamp:=BitMask AND (1 shl 2) <>0;
          is_han_fun:=BitMask AND (1 shl 0) <>0;
          is_han_fun_unit:=BitMask AND (1 shl 13) <>0;
          is_color_unit:=BitMask AND (1 shl 17) <>0;

          if has_switch then
           SwitchData.HasSwitch:=1
          Else
           SwitchData.HasSwitch:=0;

          if has_temperatur then
           SwitchData.HasTemperature:=1
          Else
           SwitchData.HasTemperature:=0;

            If is_lamp Then
             SwitchData.IsLamp:=1
          Else
             SwitchData.IsLamp:=0;


          SwitchData.Productname:=Attributes.GetNamedItem('productname').NodeValue;


        end;


        if NodeName='state' then
        begin
          tmpNode:=Node.FirstChild;
          if tmpNode <> nil Then
          begin
          if tmpNode.NodeValue<>'' then
          begin
            SwitchData.State:=tmpNode.NodeValue;
          end;
        end;
        end;


        if NodeName='celsius' then
        begin
          tmpNode:=Node.FirstChild;
          if tmpNode <> nil Then
          begin
          if tmpNode.NodeValue<>'' then
          begin
            aktTemp:=StrToFloat(tmpNode.NodeValue)/10;
            SwitchData.Celsius:=FloatToStrF(aktTemp,ffFixed,2,1,formatSettings);
          end;
        end;
        end;


        //Beispiel für Comet Dect
        //if NodeName='tsoll' then
        //begin
        //tmpNode:=Node.FirstChild;
        //if tmpNode <> nil Then
        //begin
        //  if tmpNode.NodeValue<>'' then
        //  begin
        //    if tmpNode.NodeValue='254' then
        //    begin
        //      SwitchData.SollTemperatur:='ein';
        //    end
        //    Else if tmpNode.NodeValue='253' then
        //    begin
        //      SwitchData.SollTemperatur:='aus';
        //      Exit;
        //    end
        //    Else
        //    begin
        //    aktTemp:=StrToFloat(tmpNode.NodeValue)*0.5;
        //    SwitchData.SollTemperatur:=FloatToStrF(aktTemp,ffNumber,18,1,formatSettings);
        //    end;
        //  end;
        //end;
        //end;

        if NodeName='power' then
        begin
        tmpNode:=Node.FirstChild;
        if tmpNode <> nil Then
        begin
         if tmpNode.NodeValue<>'' then
         begin
          aktPower:=StrToFloat(tmpNode.NodeValue)/1000;
          Str(aktPower:6:2, SwitchData.Power);
         end;
        end;
        end;

        if NodeName='present' then
        begin
        tmpNode:=Node.FirstChild;
        if tmpNode<> nil Then
        begin
        if tmpNode.NodeValue<> '' then
          SwitchData.Present:=tmpNode.NodeValue;
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
  // Alles zuvor generierten Schalter entfernen
 ClearScrollbox;
 {$ENDIF Linux}
 {$IFDEF Windows}
 Treeview1.Items.Clear;
 // Alles zuvor generierten Schalter entfernen
ClearScrollbox;
 {$ENDIF Windows}
 {$IFDEF ANDROID}
   ClearSwitchPanel;
 {$ENDIF ANDROID}
   SetLength(DeviceList,0);
    // Verbindung erfolgreich?
    If TheSID <> '0000000000000000' Then
    begin
     {$IFDEF ANDROID}
    jsFloatingButton1.BackgroundColor:=colbrDarkSeaGreen;
      {$ENDIF ANDROID}
       Stream:= TStringStream.Create(response);
      try
      ReadXMLFile(Doc,Stream); //XML-Daten einlesen
      i:=0;
      numDevices:=Doc.DocumentElement.ChildNodes.Count;
      Logger('Geräte gefunden: ' + IntToSTr(numDevices));
      If  numDevices=0 Then
      begin
        Logger('Fehler: Konnte Geräteliste nicht von der Fritzbox laden.');
        ShowMessage('Fehler: Konnte Geräteliste nicht von der Fritzbox laden.');
        Exit;
      end;

      SetLength(DeviceList,numDevices);
      iNode:=Doc.DocumentElement.FirstChild;
      while iNode <> nil do
       begin
        Logger('=============');

        ProcessNode(iNode);

        DeviceList[i]:=SwitchData;
        Logger('Name: ' + SwitchData.name + ' AIN: ' +SwitchData.AIN);
        Logger('Verbunden: '+ SwitchData.Present);
        Logger('Ist Schalter: '+ IntToStr(SwitchData.HasSwitch));
        Logger('Ist Lampe: '+ IntToStr(SwitchData.IsLamp));
        if SwitchData.State <> '' Then
        Logger('Status ist: '+ SwitchData.State);
        Logger('Liefert Temperatur: ' + IntToStr(SwitchData.HasTemperature));

        //Schalter in ScrollBox1 einbauen
        If (SwitchData.HasSwitch=1) OR (SwitchData.IsLamp=1) Then
        begin
           {$IFDEF Linux}
          aSwitch := TECSwitch.Create(Self);
          aSwitch.Height:=25;
          aSwitch.Top:= 1 + i*30;
          aSwitch.Tag:=i;
          aSwitch.Name:='Switch'+IntToStr(i);
          aSwitch.Caption:=SwitchData.name;

          if SwitchData.State = '0' then
            aSwitch.Checked := False;
          if SwitchData.State = '1' then
            aSwitch.Checked := True;

          aSwitch.OnClick := @aSwitchSwitch;
          aSwitch.Parent:=ScrollBox1;
          //inc(J);
          If SwitchData.Present='0' then aSwitch.Enabled:=False;
          {$ENDIF Linux}
           {$IFDEF Windows}
           aSwitch := TECSwitch.Create(Self);
           aSwitch.Height:=25;
           aSwitch.Top:= 1 + i*30;
           aSwitch.Tag:=i;
           aSwitch.Name:='Switch'+IntToStr(i);
           aSwitch.Caption:=SwitchData.name;

           if SwitchData.State = '0' then
             aSwitch.Checked := False;
           if SwitchData.State = '1' then
             aSwitch.Checked := True;

           aSwitch.OnClick := @aSwitchSwitch;
           aSwitch.Parent:=ScrollBox1;
           If SwitchData.Present='0' then aSwitch.Enabled:=False;
           {$ENDIF Windows}
          {$IFDEF ANDROID}
          AddControls(I,SwitchData.Name,SwitchData.State,SwitchData.Present);
          {$ENDIF ANDROID}
        inc(i);
        end;
        {$IFDEF ANDROID}
        //AndroidModule5.lv.
        LVItems:= 'Modell: ' +SwitchData.Productname;
        If SwitchData.HasTemperature=1 Then
        begin
          LVItems:=LVItems + ';Temperatur: ' + SwitchData.Celsius + ' °C';
        end;
        if SwitchData.Power<>'' Then
        begin
         LVItems:=LVItems + ';Aktuelle Leistung: ' + SwitchData.Power +' Watt';
        end;
        if SwitchData.State = '0' Then
          LVItems:=LVItems + ';Schalter-Status: Aus'
        else
          LVItems:=LVItems + ';Schalter-Status: An';


        AndroidModule4.lv.Add(SwitchData.Name, LVItems);
        //Logger(LVItems);
         {$ENDIF ANDROID}

        {$IFDEF Linux}
         // Detail-Infos für die Liste TreeView1
        Item0:=TreeView1.Items.Add(nil,'Fritzbox');
        Item1:=TreeView1.Items.AddChild(item0,'');
        Item1.Text:=SwitchData.Name;
        Item2:=TreeView1.Items.AddChild(item1,'');
        Item2.Text := 'Modell: ' + SwitchData.Productname;

        If SwitchData.HasTemperature=1 Then
                    begin
                    If SwitchData.Celsius <>'' Then
                      begin
                      Item2:=TreeView1.Items.AddChild(item1,'');
                      Item2.Text := 'Temperatur: ' + SwitchData.Celsius + ' °C';
                      end;
                    end;

                     if SwitchData.SollTemperatur<>'' then
                     begin
                      Item2:=TreeView1.Items.AddChild(item1,'');
                      If SwitchData.SollTemperatur ='aus' Then
                      Item2.Text := 'Soll-Temperatur: ' + SwitchData.SollTemperatur
                      Else If
                      SwitchData.SollTemperatur ='ein' Then
                        Item2.Text := 'Soll-Temperatur: ' + SwitchData.SollTemperatur
                      Else
                       Item2.Text := 'Soll-Temperatur: ' + SwitchData.SollTemperatur + ' °C';

                      end;
                      if SwitchData.Power<>'' Then
                      begin
                        Item2:=TreeView1.Items.AddChild(item1,'');
                        Item2.Text := 'Aktuelle Leistung: ' + SwitchData.Power +' Watt';

                      end;

                      if SwitchData.Present='0' Then
                      begin
                        Item2:=TreeView1.Items.AddChild(item1,'');
                        Item2.Text := 'Verbunden: Nein';

                      end;
                      if SwitchData.Present='1' Then
                      begin
                        Item2:=TreeView1.Items.AddChild(item1,'');
                        Item2.Text := 'Verbunden: Ja';

                      end;
           {$ENDIF Linux}
         {$IFDEF Windows}
         // Detail-Infos für die Liste TreeView1
        Item0:=TreeView1.Items.Add(nil,'Fritzbox');
        Item1:=TreeView1.Items.AddChild(item0,'');
        Item1.Text:=SwitchData.Name;
        Item2:=TreeView1.Items.AddChild(item1,'');
        Item2.Text := 'Modell: ' + SwitchData.Productname;
        Item2:=TreeView1.Items.AddChild(item1,'');
        Item2.Text := 'AIN: ' + SwitchData.AIN;


        If SwitchData.HasTemperature=1 Then
                    begin
                    If SwitchData.Celsius <>'' Then
                      begin
                      Item2:=TreeView1.Items.AddChild(item1,'');
                      Item2.Text := 'Temperatur: ' + SwitchData.Celsius + ' °C';
                      end;
                    end;

                     if SwitchData.SollTemperatur<>'' then
                     begin
                      Item2:=TreeView1.Items.AddChild(item1,'');
                      If SwitchData.SollTemperatur ='aus' Then
                      Item2.Text := 'Soll-Temperatur: ' + SwitchData.SollTemperatur
                      Else If
                      SwitchData.SollTemperatur ='ein' Then
                        Item2.Text := 'Soll-Temperatur: ' + SwitchData.SollTemperatur
                      Else
                       Item2.Text := 'Soll-Temperatur: ' + SwitchData.SollTemperatur + ' °C';

                      end;
                      if SwitchData.Power<>'' Then
                      begin
                        Item2:=TreeView1.Items.AddChild(item1,'');
                        Item2.Text := 'Aktuelle Leistung: ' + SwitchData.Power +' Watt';

                      end;

                      if SwitchData.Present='0' Then
                      begin
                        Item2:=TreeView1.Items.AddChild(item1,'');
                        Item2.Text := 'Verbunden: Nein';

                      end;
                      if SwitchData.Present='1' Then
                      begin
                        Item2:=TreeView1.Items.AddChild(item1,'');
                        Item2.Text := 'Verbunden: Ja';

                      end;
         {$ENDIF Windows}

        // Alte Daten löschen
        SwitchData.Name:='';
        SwitchData.AIN:='';
        SwitchData.Present:='';
        SwitchData.State:='';
        SwitchData.HasSwitch:=0;
        SwitchData.HasTemperature:=0;
        SwitchData.functionbitmask:='';
        SwitchData.Celsius:='';
        SwitchData.Power:='';
        SwitchData.Productname:='';
        SwitchData.SollTemperatur:='';
        SwitchData.IsComet:=0;
        SwitchData.IsLamp:=0;
        iNode:=iNode.NextSibling;
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

procedure TForm1.mnuCollapseClick(Sender: TObject);
begin
TreeView1.FullCollapse;
end;

procedure TForm1.mnuExpandClick(Sender: TObject);
begin
TreeView1.FullExpand;
end;

{$IFDEF ANDROID}
// Schalter entfernen
procedure TAndroidModule1.ClearSwitchPanel();
var
  I:Integer;
begin
For I:= Length(DeviceList) -1 downto 0 do
begin
 If DeviceList[i].HasSwitch=1 Then
 (AndroidModule1.FindComponent('SwitchPanel' + IntToStr(i)) As jPanel).free;
end;
{$ENDIF ANDROID}

// Schalter entfernen
procedure TForm1.ClearScrollbox();
var
I:Integer;
begin
For I := 0 to Scrollbox1.ControlCount -1 do
  begin
  (Form1.FindComponent('Switch' + IntToStr(i)) As TECSwitch).free;
  end;
end;
{$IFDEF ANDROID}
//Schalter hinzufügen
procedure TForm1.AddControls(num: Integer; SwitchName, State, Present: String);
var
   ajTextView:jTextView;
   myjTextView:jTextView;
   ajPanel:JPanel;
   myjPanel:JPanel;
   ajSwitch: jSwitchButton;
   aSwitch: jSwitchButton;


begin

  ajPanel:=jPanel.Create(self);
  ajPanel.Parent:=pnlSwitches;
  ajPanel.LayoutParamHeight:=lpWrapContent;
  ajPanel.LayoutParamWidth:=lpMatchParent;

  If num=0 Then
  begin
  ajPanel.PosRelativeToParent:=[rpTop];
  end
  else
    begin
     myjPanel:=(AndroidModule1.FindComponent('SwitchPanel' + IntToStr(num-1)) As JPanel);
     ajPanel.Anchor:=myjPanel;
     ajPanel.PosRelativeToAnchor:=[raBelow];
    end;
  ajPanel.Name:='SwitchPanel' + IntToStr(num);
  ajPanel.SetMarginLeftTopRightBottom(10,25,25,25);
  ajPanel.Init(gApp);


  myjPanel:=(AndroidModule1.FindComponent('SwitchPanel' + IntToStr(num)) As JPanel);


  ajTextView:=jTextView.Create(Self);
  ajTextView.Parent:=myjPanel;


   if num=0 Then
      ajTextView.PosRelativeToParent:=[rpTop,rpLeft]

   else
   begin
   myjTextView:=(AndroidModule1.FindComponent('lblSwitch' + IntToStr(num-1)) As JTextView);
   ajTextView.Anchor:=myjTextView;
   ajTextView.PosRelativeToAnchor:=[raBelow];
   ajTextView.PosRelativeToParent:=[rpLeft];
   end;

   if Present = '0' then
     ajTextView.Text := SwitchName + ' (nicht verbunden)'
   else
     ajTextView.Text:=SwitchName;

   ajTextView.Name:='lblSwitch'+ IntToStr(num);
   ajTextView.FontSize:=16;
   ajTextView.MarginLeft:=10;
   ajTextView.MarginRight:=50;
   ajTextView.Init(gApp);

   myjTextView:=(AndroidModule1.FindComponent('lblSwitch' + IntToStr(num)) As JTextView);

  ajSwitch :=  jSwitchButton.Create(self);
  ajSwitch.Parent:=myjPanel;
  ajSwitch.Name:='mySwitch' + IntToStr(num);

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
   ajSwitch.PosRelativeToParent:=[rpEnd];
   ajSwitch.Init(gApp);



end;
{$ENDIF ANDROID}


{$IFDEF Linux}
//Einstellungen einlesen
procedure TForm1.XMLPropStorage1RestoreProperties(Sender: TObject);
begin
  if chkSavePassword.Checked Then
    edtPassword.Text:=DecryptString(XMLPropStorage1.StoredValue['Password'])
  else
   edtPassword.Text:='';
end;
//Einstellungen speichern
procedure TForm1.XMLPropStorage1SaveProperties(Sender: TObject);
begin
  if chkSavePassword.Checked Then
   XMLPropStorage1.StoredValue['Password']:=EncryptString(edtPassword.Text)
  else
   XMLPropStorage1.StoredValue['Password']:='';
end;
{$ENDIF Linux}
{$IFDEF Windows}
//Einstellungen einlesen
procedure TForm1.XMLPropStorage1RestoreProperties(Sender: TObject);
begin
  if chkSavePassword.Checked Then
    edtPassword.Text:=DecryptString(XMLPropStorage1.StoredValue['Password'])
  else
   edtPassword.Text:='';
end;
//Einstellungen speichern
procedure TForm1.XMLPropStorage1SaveProperties(Sender: TObject);
begin
  if chkSavePassword.Checked Then
   XMLPropStorage1.StoredValue['Password']:=EncryptString(edtPassword.Text)
  else
   XMLPropStorage1.StoredValue['Password']:='';
end;
{$ENDIF Windows}
//Fehler protokollieren
procedure TForm1.Logger2(Sender: TObject; EMessage: String);
begin
 Logger( EMessage );
end;
//Log-Meldungen
procedure TForm1.Logger(msg:String);
begin

If chkDebug.Checked Then
begin
 Messages.Add(msg);
 {$IFDEF ANDROID}
  //edtLog.AppendLn(msg);
  //Messages.Add(msg);
 {$ENDIF ANDROID}
 {$IFDEF Linux}
  Memo1.Lines.Add(msg);
 {$ENDIF Linux}
  {$IFDEF Windows}
  Memo1.Lines.Add(msg);
 {$ENDIF Windows}
end;
end;
end.

