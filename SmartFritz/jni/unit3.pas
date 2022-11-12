{Hint: save all files to location: /home/te/fpcupdeluxe/projects/LAMWProjects/SmartFritz/jni }
unit unit3;

{$mode delphi}

interface

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Classes, SysUtils, AndroidWidget, Laz_And_Controls;
  
type

  { TAndroidModule3 }

  TAndroidModule3 = class(jForm)
    edtLog: jEditText;
    jPanel1: jPanel;
    jTextView1: jTextView;
    procedure AndroidModule3JNIPrompt(Sender: TObject);
  private
    {private declarations}
  public
    {public declarations}
  end;

var
  AndroidModule3: TAndroidModule3;

implementation

  
{$R *.lfm}
  

{ TAndroidModule3 }

procedure TAndroidModule3.AndroidModule3JNIPrompt(Sender: TObject);
begin
//
end;


end.
