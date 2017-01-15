program SmartWorms2;
{$R *.res}
{.$D SCRNSAVE Smart Worms Saver}

uses
  //GVShareMem,
  SysUtils, Windows,
  wwGVAdapter;

var
 A: TSmartWormGame;
 l_Run: Boolean;
 Dummy: Integer;
begin
 Randomize;
 if (ParamCount > 0) and (ParamStr(1)[1] in ['-','\','/']) then
 begin
  case Upcase(ParamStr(1)[2]) of
   'C': l_Run:= False; // ������������
   'P': l_Run:= True; // ������
   'A': l_Run:= False; // ������ ������
  end;
 end
 else
  l_Run:= True;
 if l_Run then
 begin
  A:= TSmartWormGame.Create('worm.rez');
  try
   SystemParametersInfo(spi_ScreenSaverRunning,1,@Dummy,0);
   A.Run;
   SystemParametersInfo(spi_ScreenSaverRunning,0,@Dummy,0);
  finally
   FreeAndNil(A);
  end;
 end;
end.
