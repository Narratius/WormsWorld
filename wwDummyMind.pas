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
  NewHead: TPoint;
  TargetDir, NewDir: TwwDirection;
  LegalDirs: TwwDirections;
//  B: Boolean;
begin
 l_W:= Thing as TwwWorm;
 TargetDir:= CalcDir(l_W.Head.Position, l_W.Target.Head.Position, l_W.Favorite);
 if (TargetDir = l_W.ToNeck) then
 begin
  if l_W.Favorite = ftVertical then
   TargetDir:= CalcDir(l_W.Head.Position, l_W.Target.Head.Position, ftHorizontal)
  else
   TargetDir:= CalcDir(l_W.Head.Position, l_W.Target.Head.Position, ftVertical)
 end;
 NewDir:= TargetDir;
 MovePoint(l_W.Head.Position, NewDir, NewHead);
 LegalDirs:= MoveDirs;
 if IsBusy(NewHead) then
 begin
  Exclude(LegalDirs, TargetDir);
  //Exclude(LegalDirs, l_W.ToNeck);
  if IsMe(NewHead) then
  begin
   NewDir:= l_W.ToTail(NewHead);
   Exclude(LegalDirs, InvertDir(NewDir));
   repeat
    if not CheckPoint(l_W.Head.Position, NewDir) then
    begin
     Exclude(LegalDirs, NewDir);
     if LegalDirs <> [] then
     begin
      NewDir:= ShiftDir(NewDir);
     end
     else
     begin
      NewDir:= dtStop;
      break;
     end;
    end
    else
     break
   until False;
  end
  else
  repeat
    if not CheckPoint(l_W.Head.Position, NewDir) then
    begin
     Exclude(LegalDirs, NewDir);
     if LegalDirs <> [] then
     begin
      NewDir:= ShiftDir(NewDir);
     end
     else
     begin
      NewDir:= dtStop;
      break;
     end;
    end
    else
     break
   until False;
 end;
// B:= CheckPoint(l_W.Head.Position, NewDir);
 Result:= NewDir;
end;

end.
