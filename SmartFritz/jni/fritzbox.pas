unit fritzbox;

///{$mode objfpc}{$H+}
{$mode delphi}
interface

uses
  Classes, SysUtils, {$IFDEF Linux} fphttpclient,
  {$ENDIF Linux} {$IFDEF ANDROID}Laz_And_Controls,{$ENDIF ANDROID}HlpIHash, HlpMD5,
  laz2_XMLRead, laz2_DOM,RegExpr,{$IFDEF Linux}fphttpclient, httpdefs,httpprotocol,  {$ENDIF Linux} opensslsockets;

type
      TBoxInfo = record
        SID : String;
        Response:String;
        Status:Integer;
        BlockTime:String;
        ExternalIP:String;
      end;

      TOnLogMsg = procedure(Sender: TObject; EMessage: string) of
          object;

      { TFritzBox }

      TFritzBox = class(TObject)
        private
          {$IFDEF Linux}
          ffHTTP: TFPHttpClient;
          {$ENDIF Linux}
          {$IFDEF ANDROID}
          //ffHTTP: TFPHttpClient;
          ffHTTP: JHttpCLient;
          {$ENDIF ANDROID}
          fError : String;
          fBox : TBoxInfo;
          FFboxURL:String;
          FServiceURL:String;
          FOnLogMsg:TOnLogMsg;

          function GetExternalIP: String;
          function GetBlockTime: String;
          function GetResponse: String;
          function GetSID : String;
          function GetState: Integer;
          procedure SetFBURL(AValue: String);
          procedure Logger(EMessage:String);
          procedure SetServiceURL(AValue: String);
          function GetNodeValue(HttpResultString, SearchString: String): String;
        public
          constructor Create;
          destructor Destroy; override;
          Procedure LogIn(ABenutzername: string = ''; APassword: string = '');
          procedure Logout;
          procedure FboxGetURL();
          procedure FboxGetExternalIP();
          property SID : String read GetSID;
          property FBOXURL: String write SetFBURL;
          property ServiceURL: String write SetServiceURL;
          property OnLogMsg: TOnLogMsg read FOnLogMsg write FOnLogMsg;
          property Response: String read GetResponse;
          property State: Integer read GetState;
          property BlockTime: String read GetBlockTime;
          property ExternalIP: String read GetExternalIP;

      end;


implementation

{$IFDEF ANDROID}
uses unit1;
{$ENDIF ANDROID}

{ TFritzBox }

function TFritzBox.GetSID: String;
begin
 Result:=FBox.SID;
end;

function TFritzBox.GetState: Integer;
begin
  Result:=FBox.Status;
end;

function TFritzBox.GetResponse: String;
begin
  Result:=FBox.Response;
end;

function TFritzBox.GetExternalIP: String;
begin
  Result:=FBox.ExternalIP;
end;

function TFritzBox.GetBlockTime: String;
begin
  Result:=Fbox.BlockTime;
end;

procedure TFritzBox.SetFBURL(AValue: String);
begin
 FFBOXURL:=AValue;
end;

procedure TFritzBox.Logger(EMessage: String);
begin
  if Assigned(OnLogMsg) then
     begin
       OnLogMsg(self,EMessage);
     end;
end;

procedure TFritzBox.FboxGetURL();
begin
  Fbox.Response:='';
  try
   Fbox.Response:=ffHTTP.Get(FServiceURL);
  except
    //NOP ignore
  end;
  {$IFDEF Linux}
  FBox.Status:=ffHTTP.ResponseStatusCode;
  {$ENDIF Linux}
  {$IFDEF ANDROID}
  FBox.Status:=ffHTTP.GetResponseCode;
  {$ENDIF ANDROID}
end;

procedure TFritzBox.SetServiceURL(AValue: String);
begin
FServiceURL:=AValue;
end;


constructor TFritzBox.Create;
begin
  {$IFDEF Linux}
  ffHTTP := TFPHttpClient.Create(nil);
  {$ENDIF Linux}
  {$IFDEF ANDROID}
  // Unter Android verwenden wir
  // jHttpClient1 von AndroidModule1.
  // Es funktiomiert zurzeit nicht stabil, die Komponenten
  // dynamisch zu erzeugen.
  // TFPHttpClient sollte eigentlich auf funktionieren, lauft aber nicht stabil.
  ffHTTP:=AndroidModule1.jHttpClient1;


  //defaults jHttpClient Android
  //ffHTTP.AuthenticationMode:=autNone;
  //ffHTTP.CharSet:='UTF-8';
  //ffHTTP.ConnectionTimeout:=15000;
  //ffHTTP.ResponseTimeout:=15000;
  //ffHTTP.UploadFormName:='lamwFormUpload';


  {$ENDIF ANDROID}
  Fbox.SID:='0000000000000000';
end;

destructor TFritzBox.Destroy;
begin
   {$IFDEF Linux}
  ffHTTP.Free;
    {$ENDIF Linux}
  inherited;
end;
// Bei der Fritzbox anmelden
// Zum Verfahren siehe
// https://avm.de/fileadmin/user_upload/Global/Service/Schnittstellen/Session-ID_deutsch_13Nov18.pdf
procedure TFritzBox.LogIn(ABenutzername: string = ''; APassword: string = '');
var
  TheChallenge,TheResponse,TheSid : String;
  UseOldSID:Boolean;

  function InternalGetChallenge : String;
  var
    S:String;
  begin
    Logger('Hole Challenge');
    try
    Result := ffHTTP.Get(FFBoxURL + '/login_sid.lua');
    except on E:Exception do
     Logger(e.Message);
    end;
    Logger('Challenge-Result: ' + Result);
    Logger('Response-Code: ' + IntToStr(ffHTTP.GetResponseCode()));

  {$IFDEF ANDROID}
  fbox.Status:=ffHTTP.GetResponseCode();
  {$ENDIF ANDROID}
  {$IFDEF Linux}
  fbox.Status:=ffHTTP.ResponseStatusCode;
  {$ENDIF Linux}
     FBox.BlockTime:='0';
     S:=GetNodeValue(Result,'BlockTime');
     If S <>'0' Then
        begin
         FBox.BlockTime:=S;
         Logger('BlockTime: ' + S);
        end
     else
     begin
      if Pos('<challenge>',LowerCase(Result))=0 then
        raise Exception.Create('Fehler beim Initialisieren der Verbindung.');

      Result:=GetNodeValue(Result,'Challenge');
     end;

  end;
  // MD5 erzeugen
  function InternalGetMD5 : String;
  var
    MD5Hash:IHash;
    Bytes: TBytes;
    str : String;

  begin
    Result := '';
    str := TheChallenge+'-'+APassword;
    MD5Hash := TMD5.Create();
    Bytes:=TEncoding.Unicode.GetBytes(str);
    Result:=LowerCase(MD5Hash.ComputeBytes(Bytes).ToString());
  end;
  // SID holen
  function InternalGetSid : String;
  var
    Params :String;
  begin
    Result := '';
    if Fbox.SID <> '0000000000000000' then
        Params:=('?sid=' + Fbox.SID)
    else
        Params:=('?username=' + ABenutzername + '&response=' + TheChallenge + '-' + TheResponse);
    try
     Result := ffHTTP.Get(FFBoxURL + '/login_sid.lua' + Params);
    except on E:Exception do
     Logger(e.Message);
    end;

     {$IFDEF ANDROID}
     fbox.Status:=ffHTTP.GetResponseCode();
     {$ENDIF ANDROID}
     {$IFDEF Linux}
    fbox.Status:=ffHTTP.ResponseStatusCode;
    {$ENDIF Linux}

    Logger(Result);
    if Pos('<sid>',LowerCase(Result))=0 then
       raise Exception.Create('Fehler beim Generieren der Sitzungs-ID.');

    Result:=GetNodeValue(Result,'SID');
  end;

begin
  {$IFDEF Linux}
  ffHTTP.AllowRedirect:=True;
 {$ENDIF Linux}

  UseOldSID:=false;
   Logger('Starte Verbindung zu: ' + FFBoxURL);
    try
      if Fbox.SID <> '0000000000000000' then
        if InternalGetSid=FBox.SID Then
          begin
            UseOldSID:=True;
            Logger('Verwende bisherige SID: ' + FBox.SID);
          end;

      If UseOldSID=false Then
        begin

        TheChallenge := InternalGetChallenge;

       if fBox.BlockTime <> '0' Then
        begin
         FBox.SID:='0000000000000000';
        end
      else
      begin
      Logger('Challenge: ' + TheChallenge);
      TheResponse := InternalGetMD5;
      Logger('MD5: ' + TheResponse);
      TheSid:= InternalGetSid;
      Logger('Neue SID: ' + TheSid);
      FBox.SID := TheSid;
      end;
      end;

    except
      on E:Exception do fError := E.Message;
    end;
end;
//bei der Fritzbox abmelden
procedure TFritzBox.Logout;
begin
  {$IFDEF Linux}
  ffHTTP.AllowRedirect:=True;
  {$ENDIF Linux}
  ffHTTP.Get(FFBoxURL + '/login_sid.lua?logout=0&sid=' + FBox.SID);
       {$IFDEF ANDROID}
     fbox.Status:=ffHTTP.GetResponseCode();
     {$ENDIF ANDROID}
     {$IFDEF Linux}
    fbox.Status:=ffHTTP.ResponseStatusCode;
    {$ENDIF Linux}
  fBox.SID := '0000000000000000';
end;
// SessionInfo im XML-String finden
function TFritzBox.GetNodeValue(HttpResultString, SearchString: String): String;
var
Doc: TXMLDocument;
Stream : TStringStream;
ChildNode, SearchNode: TDOMNode;
begin
 Result:='';
 Stream:= TStringStream.Create(HttpResultString);
 ReadXMLFile(Doc,Stream);
 try
 ChildNode := Doc.FindNode('SessionInfo');
 If ChildNode<> nil then
  begin
     If ChildNode.HasChildNodes Then
      begin
         SearchNode:=ChildNode.findNode(SearchString);
         If SearchNode <> nil then
          begin
            If SearchNode.HasChildNodes Then
             begin
              Result:=SearchNode.FirstChild.NodeValue;
             end;
          end
          end;
         end;
 finally
   Doc.Free;
   Stream.Free;
 end;
end;
// Öffentliche IP-Adresse ermitteln
// siehe https://avm.de/fileadmin/user_upload/Global/Service/Schnittstellen/wanipconnSCPD.pdf
procedure TFritzBox.FboxGetExternalIP();
var
{$IFDEF Linux}
request: TStringList;
stream, result: TMemoryStream;
RegexObj: TRegExpr;
S:String;
{$ENDIF Linux}
{$IFDEF ANDROID}

content:String;

{$ENDIF ANDROID}
begin
 Fbox.Response:='';
 FBox.Status:=0;
 FBox.ExternalIP:='';
 Logger('Starte Abfrage öffentliche IP');

  {$IFDEF ANDROID}
 content:='<?xml version="1.0" encoding="utf-8"?>'#13#10
 + '<s:Envelope s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/" xmlns:s="http://schemas.xmlsoap.org/soap/envelope/">'
 + '  <s:Body>'
 + '   <u:GetExternalIPAddress xmlns:u="urn:schemas-upnp-org:service:WANIPConnection:1" />'
 + '  </s:Body>'
 + '</s:Envelope>';

 ffHTTP.CharSet:='UTF-8';
 ffHTTP.ConnectionTimeout:=15000;
 ffHTTP.ResponseTimeout:=15000;
 ffHTTP.ClearNameValueData;
 ffHTTP.SetUnvaluedNameData('BODY'); //disregard nameData 'BODY'
 ffHTTP.SetEncodeValueData(False);  //not encode ValueData
 ffHTTP.AddClientHeader('Pragma', 'no-cache');
 ffHTTP.AddClientHeader('Cache-Control', 'no-cache');
 ffHTTP.AddClientHeader('SoapAction', 'urn:schemas-upnp-org:service:WANIPConnection:1#GetExternalIPAddress');
 ffHTTP.AddClientHeader('Content-Type','text/xml; charset=utf-8');
 ffHTTP.AddNameValueData('BODY',content);
 Logger('Service-URL:' +FServiceURL);
 // Die SOAP-Abfgrage funktioniert mit dem JhttpClient nur ansynchron
 // Die Events werden in AndroidModule1 ausgelöst
 // procedure jHttpClient1CodeResult(Sender: TObject; code: integer);
 // procedure jHttpClient1ContentResult(Sender: TObject; content: string);

 ffHTTP.PostNameValueDataAsync(FServiceURL);

 {$ENDIF ANDROID}

  {$IFDEF Linux}
 ffHTTP.RequestHeaders.Add('Pragma: no-cache');
 ffHTTP.RequestHeaders.Add('Cache-Control: no-cache');
 ffHTTP.RequestHeaders.Add('SoapAction:urn:schemas-upnp-org:service:WANIPConnection:1#GetExternalIPAddress');
 ffHTTP.RequestHeaders.Add('CONTENT-TYPE: text/xml; charset="utf-8"');
 request := TStringList.Create;
 request.Add('<?xml version="1.0" encoding="utf-8"?>');
 request.Add('<s:Envelope s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/" xmlns:s="http://schemas.xmlsoap.org/soap/envelope/">');
 request.Add('  <s:Body>');
 request.Add('   <u:GetExternalIPAddress xmlns:u="urn:schemas-upnp-org:service:WANIPConnection:1" />');

 request.Add('  </s:Body>');
 request.Add('</s:Envelope>');
 stream := TMemoryStream.Create;
 request.SaveToStream(stream);

 stream.Position := 0;
 request.Clear;



 ffHTTP.RequestHeaders.Add('Content-Length: '+IntToStr(stream.Size));
 ffHTTP.RequestBody := stream;
 result := TMemoryStream.Create;
 Logger('Post: '+FServiceURL);
 ffHTTP.Post(FServiceURL, result);
 result.Position := 0;
 request.LoadFromStream(result);


  RegexObj := TRegExpr.Create;
  try
  RegexObj.Expression :='(?si)<NewExternalIPAddress>(.*?)<\/NewExternalIPAddress>';
  S:='';
  for i:=0 to request.Count-1 do
    begin
    Logger('SOAP Request: ' + request.Strings[i]);
    If RegexObj.Exec(request.Strings[i]) Then
      begin
       S:=RegexObj.Match[1];

      end;
    end;

    If S<> '' Then
       Logger('Externe IP: ' + S);
       FBox.ExternalIP:=S;

    finally
    RegexObj.Free;
    end;
  request.Free;
  stream.Free;
  {$ENDIF Linux}
end;

end.

