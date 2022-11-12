{Hint: save all files to location: /jni }
unit unit5;

{$mode delphi}

interface

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Classes, SysUtils, AndroidWidget, Laz_And_Controls;
  
type

  { TAndroidModule5 }

  TAndroidModule5 = class(jForm)
    edtCall: jEditText;
    btnGetCallList: jButton;
    jPanel1: jPanel;
    lblCall: jTextView;
    procedure btnGetCallListClick(Sender: TObject);
  private
    {private declarations}
  public
    {public declarations}
  end;

var
  AndroidModule5: TAndroidModule5;

implementation
  
{$R *.lfm}
uses unit1;

{ TAndroidModule5 }

procedure TAndroidModule5.btnGetCallListClick(Sender: TObject);
begin
 edtCall.Text:='';
 AndroidModule1.FBox.LogIn(AndroidModule1.Username, AndroidModule1.Password);
 AndroidModule1.TheSid:=AndroidModule1.FBox.SID;
 AndroidModule1.FBox.ServiceURL:=AndroidModule1.FBOXURL + '/fon_num/foncalls_list.lua?sid=' + AndroidModule1.TheSID + '&csv=';
 AndroidModule1.FBox.FboxGetURL();
 edtCall.Text:= AndroidModule1.FBox.Response;
end;

end.
