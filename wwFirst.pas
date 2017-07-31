unit wwFirst;

interface

Uses
  wwMinds, wwTypes;

type
  TFirstMind = class (TwwMind)
  protected
    function GetCaption: string; override;
    function GetEnglishCaption: string; override;
    function Thinking: TwwDirection; override;
  end;

implementation

Uses
 Types,
 wwWorms, wwUtils;

{ TFirstMind }

function TFirstMind.GetCaption: string;
begin
  Result:= 'Первый';
end;

function TFirstMind.GetEnglishCaption: string;
begin
  Result:= 'First';
end;

function TFirstMind.Thinking: TwwDirection;
var
  l_W: TwwWorm;
  NewHead: TPoint;
  l_TargetDir, NewDir: TwwDirection;
  LegalDirs: TwwDirections;
//  B: Boolean;
begin
 l_W:= Thing as TwwWorm;
 Result:= CalcDir(l_W.Head.Position, l_W.Target.Head.Position, ftVertical);
 if not CheckPoint(l_W.Head.Position, Result) then
 begin
   Result:= ShiftDir(Result);
   if not CheckPoint(l_W.Head.Position, Result) then
   begin
     Result:= ShiftDir(Result);
     if not CheckPoint(l_W.Head.Position, Result) then
     begin
       Result:= ShiftDir(Result);
       if not CheckPoint(l_W.Head.Position, Result) then
         Result:= dtStop;
     end;
   end;
 end;
end;

end.
