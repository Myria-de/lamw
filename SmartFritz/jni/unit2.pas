{Hint: save all files to location: /jni }
unit unit2;

{$mode delphi}

interface

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Classes, SysUtils, AndroidWidget, Laz_And_Controls, preferences;
  
type

  { TAndroidModule2 }

  TAndroidModule2 = class(jForm)
    edtURL: jEditText;
    edtUserName: jEditText;
    edtPassword: jEditText;
    btnSaveSettings: jButton;
    chkShowPassword: jCheckBox;
    chkSavePassword: jCheckBox;
    chkDebugLog: jCheckBox;
    btnExternalIP: jButton;
    jPanel1: jPanel;
    lblURL: jTextView;
    lblUserName: jTextView;
    lblPassword: jTextView;
    procedure AndroidModule2JNIPrompt(Sender: TObject);
    procedure btnExternalIPClick(Sender: TObject);

    procedure btnSaveSettingsClick(Sender: TObject);
    procedure chkShowPasswordClick(Sender: TObject);
    procedure chkSavePasswordClick(Sender: TObject);
    procedure LoadSettings;
  private
    {private declarations}
  public
    {public declarations}
    Procedure SaveSettings();
  end;

var
  AndroidModule2: TAndroidModule2;

implementation

uses unit1;
  
{$R *.lfm}
  

{ TAndroidModule2 }

procedure TAndroidModule2.btnSaveSettingsClick(Sender: TObject);
begin
 SaveSettings;
end;

procedure TAndroidModule2.chkShowPasswordClick(Sender: TObject);
begin
 if chkShowPassword.Checked Then
 edtPassword.InputTypeEx:=itxText
 else
 edtPassword.InputTypeEx:=itxTextPassword;
end;

procedure TAndroidModule2.chkSavePasswordClick(Sender: TObject);
begin
  //
end;

procedure TAndroidModule2.AndroidModule2JNIPrompt(Sender: TObject);
begin
//LoadSettings;
end;

procedure TAndroidModule2.btnExternalIPClick(Sender: TObject);
begin
AndroidModule1.GetExternalIP();

end;



procedure TAndroidModule2.LoadSettings;
begin
edtURL.Text:=AndroidModule1.FBOXURL;
 if (LeftStr(edtURL.Text,7) <> 'http://') AND (LeftStr(edtURL.Text,8) <> 'https://')then
   edtURL.Text:='http://' + edtURL.Text;

 edtUserName.text:=AndroidModule1.Username;
 edtPassword.Text:=AndroidModule1.Password;
 chkSavePassword.Checked:=AndroidModule1.jPreferences1.GetBoolData('SavePassword',false);
 chkDebugLog.Checked:=AndroidModule1.jPreferences1.GetBoolData('DebugLog',false);

exit;
edtURL.Text:=AndroidModule1.jPreferences1.GetStringData('FritzboxURL','');
 if (LeftStr(edtURL.Text,7) <> 'http://') AND (LeftStr(edtURL.Text,8) <> 'https://')then
   edtURL.Text:='http://' + edtURL.Text;

 edtUserName.text:=AndroidModule1.jPreferences1.GetStringData('User','');
 edtPassword.Text:=AndroidModule1.jPreferences1.GetStringData('Password','');
 chkSavePassword.Checked:=AndroidModule1.jPreferences1.GetBoolData('SavePassword',false);
 chkDebugLog.Checked:=AndroidModule1.jPreferences1.GetBoolData('DebugLog',false);
end;

procedure TAndroidModule2.SaveSettings();
begin
 if (LeftStr(edtURL.Text,7) <> 'http://') AND (LeftStr(edtURL.Text,8) <> 'https://')then
   edtURL.Text:='http://' + edtURL.Text;
AndroidModule1.FBOXURL:=Trim(edtURL.Text);
AndroidModule1.Username:=Trim(edtUserName.text);
AndroidModule1.Password:=Trim(edtPassword.Text);
AndroidModule1.SavePassword:=chkSavePassword.Checked;
AndroidModule1.DebugLog:=chkDebugLog.Checked;
AndroidModule1.SaveSettings;
end;

end.
