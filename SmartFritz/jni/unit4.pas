{Hint: save all files to location: /jni }
unit unit4;

{$mode delphi}

interface

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Classes, SysUtils, AndroidWidget, Laz_And_Controls, expandablelistview;
  
type

  { TAndroidModule4 }

  TAndroidModule4 = class(jForm)
    lv: jExpandableListView;
    jPanel1: jPanel;
    jlblInfos: jTextView;
  private
    {private declarations}
  public
    {public declarations}
  end;

var
  AndroidModule4: TAndroidModule4;

implementation
  
{$R *.lfm}
  

end.
