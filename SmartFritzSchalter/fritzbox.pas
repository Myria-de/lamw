unit fritzbox;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fphttpclient, HlpIHash, HlpMD5, laz2_XMLRead,
  laz2_DOM, RegExpr, opensslsockets;

type
  TBoxInfo = record
    SID: string;
    Response: string;
    Status: integer;
    BlockTime: string;
    ExternalIP: string;
  end;

  TOnLogMsg = procedure(Sender: TObject; EMessage: string) of object;

  { TFritzBox }

  TFritzBox = class(TObject)
  private
          {$IFDEF Linux}
    ffHTTP: TFPHttpClient; // unter Linux: Standard-HTTP-Client
          {$ENDIF Linux}
           {$IFDEF Windows}
           {$ENDIF Windows}
          {$IFDEF Windows}
        ffHTTP: TFPHttpClient; // unter Linux: Standard-HTTP-Client
          {$ENDIF Windows}

          {$IFDEF ANDROID}
    ffHTTP: JHttpCLient;  // unter Android: JHttpCLient
          {$ENDIF ANDROID}
    fError: string;
    fBox: TBoxInfo;
    FFboxURL: string;
    FServiceURL: string;
    FOnLogMsg: TOnLogMsg;

    function GetExternalIP: string;
    function GetResponse: string;
    function GetSID: string;
    function GetState: integer;
    function GetBlockTime: string;
    procedure SetFBURL(AValue: string);
    procedure Logger(EMessage: string);
    procedure SetServiceURL(AValue: string);
    function GetNodeValue(HttpResultString, SearchString: string): string;
  public
    constructor Create;
    destructor Destroy; override;
    procedure LogIn(ABenutzername: string = ''; APassword: string = '');
    procedure Logout;
    procedure FboxGetURL();
    procedure FboxGetExternalIP();
    property SID: string read GetSID;
    property FBOXURL: string write SetFBURL;
    property ServiceURL: string write SetServiceURL;
    property OnLogMsg: TOnLogMsg read FOnLogMsg write FOnLogMsg;
    property Response: string read GetResponse;
    property State: integer read GetState;
    property BlockTime: string read GetBlockTime;
    property ExternalIP: string read GetExternalIP;
  end;


implementation

{ TFritzBox }

function TFritzBox.GetSID: string;
begin
  Result := FBox.SID;
end;

function TFritzBox.GetState: integer;
begin
  Result := FBox.Status;
end;

function TFritzBox.GetBlockTime: string;
begin
  Result := Fbox.BlockTime;
end;

function TFritzBox.GetResponse: string;
begin
  Result := FBox.Response;
end;

function TFritzBox.GetExternalIP: string;
begin
  Result := FBox.ExternalIP;
end;

procedure TFritzBox.SetFBURL(AValue: string);
begin
  FFBOXURL := AValue;
end;

procedure TFritzBox.SetServiceURL(AValue: string);
begin
  FServiceURL := AValue;
end;

// Protokoll/Log als Event
procedure TFritzBox.Logger(EMessage: string);
begin
  if Assigned(OnLogMsg) then
  begin
    OnLogMsg(self, EMessage);
  end;

end;
// Get-Abfrage an die Fritzbox senden
// Ergebnis in Fbox.Response speichern
procedure TFritzBox.FboxGetURL();
begin
  Fbox.Response := '';
  FBox.Status := 0;
  try
    Fbox.Response := ffHTTP.Get(FServiceURL);
        Logger('XXX ' + FServiceURL);
  except
    Logger('Fehler: Konnte ' + FServiceURL + ' nicht öffnen.');
  end;
  {$IFDEF Linux}
  FBox.Status := ffHTTP.ResponseStatusCode; // Rückgabe-Code von TFPHttpClient
  {$ENDIF Linux}
  {$IFDEF Windows}
  FBox.Status := ffHTTP.ResponseStatusCode; // Rückgabe-Code von TFPHttpClient
  {$ENDIF Windows}
  {$IFDEF ANDROID}
  FBox.Status := ffHTTP.GetResponseCode;
  // bei Android andere Eigenschaft, gleiches Ergebnis
  {$ENDIF ANDROID}
end;
// öffentliche/externe IP-Adresse der Fritzbox ermitteln, SOAP-Abfrage
// siehe https://avm.de/fileadmin/user_upload/Global/Service/Schnittstellen/wanipconnSCPD.pdf
procedure TFritzBox.FboxGetExternalIP();
var
  request: TStringList;
  stream, Result: TMemoryStream;
  RegexObj: TRegExpr;
  S: string;
  I: integer;
begin
  Fbox.Response := '';
  FBox.Status := 0;
  FBox.ExternalIP := '';

  ffHTTP.RequestHeaders.Add('Pragma: no-cache');
  ffHTTP.RequestHeaders.Add('Cache-Control: no-cache');
  ffHTTP.RequestHeaders.Add(
    'SoapAction:urn:schemas-upnp-org:service:WANIPConnection:1#GetExternalIPAddress');
  ffHTTP.RequestHeaders.Add('CONTENT-TYPE: text/xml; charset="utf-8"');
  request := TStringList.Create;
  request.Add('<?xml version="1.0" encoding="utf-8"?>');
  request.Add(
    '<s:Envelope s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/" xmlns:s="http://schemas.xmlsoap.org/soap/envelope/">');
  request.Add('  <s:Body>');
  request.Add(
    '   <u:GetExternalIPAddress xmlns:u="urn:schemas-upnp-org:service:WANIPConnection:1" />');

  request.Add('  </s:Body>');
  request.Add('</s:Envelope>');
  stream := TMemoryStream.Create;
  request.SaveToStream(stream);

  stream.Position := 0;
  request.Clear;

  ffHTTP.RequestHeaders.Add('Content-Length: ' + IntToStr(stream.Size));
  ffHTTP.RequestBody := stream;
  Result := TMemoryStream.Create;
  Logger('Post: ' + FServiceURL);

  try
    ffHTTP.Post(FServiceURL, Result);   //Post-Abfrage
  except
    Logger('Fehler: Konnte ' + FServiceURL + ' nicht öffnen');
  end;

  Result.Position := 0;
  request.LoadFromStream(Result);

  //IP-Adresse ermitteln
  RegexObj := TRegExpr.Create;
  try
    RegexObj.Expression := '(?si)<NewExternalIPAddress>(.*?)<\/NewExternalIPAddress>';
    S := '';
    for i := 0 to request.Count - 1 do
    begin
      Logger('SOAP Request: ' + request.Strings[i]);
      if RegexObj.Exec(request.Strings[i]) then
      begin
        S := RegexObj.Match[1];
      end;
    end;

    if S <> '' then
    begin
      Logger('Externe IP: ' + S);
      FBox.ExternalIP := S;
    end;

  finally
    RegexObj.Free;
  end;
  request.Free;
  stream.Free;
end;

constructor TFritzBox.Create;
begin
  {$IFDEF Linux}
  ffHTTP := TFPHttpClient.Create(nil);
  {$ENDIF Linux}
  {$IFDEF Windows}
  ffHTTP := TFPHttpClient.Create(nil);
  {$ENDIF Windows}
  Fbox.SID := '0000000000000000';
end;

destructor TFritzBox.Destroy;
begin
  ffHTTP.Free;
  inherited;
end;
// Bei der Fritzbox anmelden
// Zum Verfahren siehe
// https://avm.de/fileadmin/user_upload/Global/Service/Schnittstellen/Session-ID_deutsch_13Nov18.pdf
procedure TFritzBox.LogIn(ABenutzername: string = ''; APassword: string = '');
var
  TheChallenge, TheResponse, TheSid: string;
  UseOldSID: boolean;

  function InternalGetChallenge: string;
  var
    S: string;
  begin
    try
      Result := ffHTTP.Get(FFBoxURL + '/login_sid.lua');
    except
      on E: Exception do
      begin
        Logger('Fehler: ' + E.Message);
      end;

    end;

    Logger('Result: ' + Result);
    FBox.BlockTime := '0';

    fbox.Status := ffHTTP.ResponseStatusCode;

    S := GetNodeValue(Result, 'BlockTime');
    if S <> '0' then
    begin
      FBox.BlockTime := S;
    end
    else
    begin
      if Pos('<challenge>', LowerCase(Result)) = 0 then
        raise Exception.Create('Fehler beim Initialisieren der Verbindung.');

      Result := GetNodeValue(Result, 'Challenge');
    end;
  end;
  // MD5 erzeugen
  function InternalGetMD5: string;
  var
    MD5Hash: IHash;
    Bytes: TBytes;
    str: string;
    //i : Integer;
  begin
    Result := '';
    str := TheChallenge + '-' + APassword;
    MD5Hash := TMD5.Create();
    Bytes := TEncoding.Unicode.GetBytes(str);
    Result := LowerCase(MD5Hash.ComputeBytes(Bytes).ToString());
  end;
  // SID holen
  function InternalGetSid: string;
  var
    Params: string;
  begin
    Result := '';
    if Fbox.SID <> '0000000000000000' then
      Params := ('?sid=' + Fbox.SID)
    else
      Params := ('?username=' + ABenutzername + '&response=' +
        TheChallenge + '-' + TheResponse);
    Result := ffHTTP.Get(FFBoxURL + '/login_sid.lua' + Params);
    fbox.Status := ffHTTP.ResponseStatusCode;
    Logger(Result);
    if Pos('<sid>', LowerCase(Result)) = 0 then
      raise Exception.Create('Fehler beim Generieren der Sitzungs-ID.');

    Result := GetNodeValue(Result, 'SID');
  end;

begin
  Fbox.Response := '';
  FBox.Status := 0;
{$IFDEF Linux}
  ffHTTP.AllowRedirect := True; //muss nicht sein, aber zur Sicherheit
{$ENDIF Linux}
{$IFDEF Windows}
ffHTTP.AllowRedirect := True; //muss nicht sein, aber zur Sicherheit
{$ENDIF Windows}
  UseOldSID := False;
  Logger('Starte Verbindung zu: ' + FFBoxURL);
  try
    if Fbox.SID <> '0000000000000000' then
      if InternalGetSid = FBox.SID then
      begin
        UseOldSID := True;
        Logger('Verwende bisherige SID: ' + FBox.SID);
      end;

    if UseOldSID = False then
    begin
      TheChallenge := InternalGetChallenge;
      if fBox.BlockTime <> '0' then
      begin
        FBox.SID := '0000000000000000';
      end
      else
      begin
        Logger('Challenge: ' + TheChallenge);
        TheResponse := InternalGetMD5;
        Logger('MD5: ' + TheResponse);
        TheSid := InternalGetSid;
        Logger('Neue SID: ' + TheSid);
        FBox.SID := TheSid;
      end;
    end;
  except
    on E: Exception do
      fError := E.Message;
  end;
end;
//Abmelden, bei Bedarf
procedure TFritzBox.Logout;
begin
  ffHTTP.AllowRedirect := True;
  ffHTTP.Get(FFBoxURL + '/login_sid.lua?logout=0&sid=' + FBox.SID);
  fbox.Status := ffHTTP.ResponseStatusCode;
  fBox.Response := '';
  fBox.SID := '0000000000000000';
end;
// SessionInfo im XML-String finden
function TFritzBox.GetNodeValue(HttpResultString, SearchString: string): string;
var
  Doc: TXMLDocument;
  Stream: TStringStream;
  ChildNode, SearchNode: TDOMNode;
begin
  Result := '';
  Stream := TStringStream.Create(HttpResultString);
  ReadXMLFile(Doc, Stream);
  try
    ChildNode := Doc.FindNode('SessionInfo');
    if ChildNode <> nil then
    begin
      if ChildNode.HasChildNodes then
      begin
        SearchNode := ChildNode.findNode(SearchString);
        if SearchNode <> nil then
        begin
          if SearchNode.HasChildNodes then
          begin
            Result := SearchNode.FirstChild.NodeValue;
          end;
        end;
      end;
    end;
  finally
    Doc.Free;
    Stream.Free;
  end;
end;


end.
