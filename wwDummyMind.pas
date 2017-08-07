unit wwDummyMind;

interface

Uses
 wwMinds, wwTypes, wwClasses;

type
  TDummyMind = class (TwwMind)
  protected
    function GetCaption: string; override;
    function GetEnglishCaption: string; override;
    function Thinking: TwwDirection; override;
  public
    function FindTarget(aThing: TwwThing): TwwThing; override;
  end;

implementation

Uses
 Types,
 wwWorms, wwUtils, WormsWorld;

{ TDummyMind }

{
********************************** TDummyMind **********************************
}
function TDummyMind.FindTarget(aThing: TwwThing): TwwThing;
begin
  Result:= TWormsField(aThing.World).NearestTarget(aThing.Head.Position);
end;

function TDummyMind.GetCaption: string;
begin
  Result:= 'Глупый';
end;

function TDummyMind.GetEnglishCaption: string;
begin
  Result:= 'Dummy';
end;

function TDummyMind.Thinking: TwwDirection;
var
  l_W: TwwWorm;
  l_NewHead: TPoint;
  l_TargetDir, l_NewDir: TwwDirection;
  l_LegalDirs: TwwDirections;
begin
 l_W:= Thing as TwwWorm;
 l_TargetDir:= CalcDir(l_W.Head.Position, l_W.Target.Head.Position, l_W.Favorite);
 if (l_TargetDir = l_W.ToNeck) then
 begin
  if l_W.Favorite = ftVertical then
   l_TargetDir:= CalcDir(l_W.Head.Position, l_W.Target.Head.Position, ftHorizontal)
  else
   l_TargetDir:= CalcDir(l_W.Head.Position, l_W.Target.Head.Position, ftVertical)
 end;
 l_NewDir:= l_TargetDir;
 MovePoint(l_W.Head.Position, l_NewDir, l_NewHead);
 if IsBusy(l_NewHead) then
 begin
  l_LegalDirs:= MoveDirs;
  Exclude(l_LegalDirs, l_TargetDir);
  if IsMe(l_NewHead) then
  begin
   l_NewDir:= l_W.ToTail(l_NewHead);
   Exclude(l_LegalDirs, InvertDir(l_NewDir));
   repeat
    if not CheckPoint(l_W.Head.Position, l_NewDir) then
    begin
     Exclude(l_LegalDirs, l_NewDir);
     if l_LegalDirs <> [] then
      l_NewDir:= ShiftDir(l_NewDir)
     else
     begin
      l_NewDir:= dtStop;
      break;
     end;
    end
    else
     break
   until False;
  end
  else
  repeat
    if not CheckPoint(l_W.Head.Position, l_NewDir) then
    begin
     Exclude(l_LegalDirs, l_NewDir);
     if l_LegalDirs <> [] then
     begin
      l_NewDir:= ShiftDir(l_NewDir);
     end
     else
     begin
      l_NewDir:= dtStop;
      break;
     end;
    end
    else
     break
  until False;
 end;
 Result:= l_NewDir;
end;

end.
