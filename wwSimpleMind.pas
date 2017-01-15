unit wwSimpleMind;

interface
Uses
 wwMinds, wwTypes;

type
  TSimpletonMind = class (TwwMind)
  protected
    function GetCaption: string; override;
    function GetEnglishCaption: string; override;
    function Thinking: TwwDirection; override;
  end;
  
  TLazyMind = class (TSimpletonMind)
  protected
    function GetCaption: string; override;
    function GetEnglishCaption: string; override;
    function Thinking: TwwDirection; override;
  end;
  
  TGourmetMind = class (TSimpletonMind)
  protected
    function GetCaption: string; override;
    function GetEnglishCaption: string; override;
    function Thinking: TwwDirection; override;
  end;
  
implementation

Uses
 Types, wwUtils, wwWorms, WOrmsWorld;

{
******************************** TSimpletonMind ********************************
}
function TSimpletonMind.GetCaption: string;
begin
  Result:= 'Простак';
end;

function TSimpletonMind.GetEnglishCaption: string;
begin
  Result:= 'Simpleton';
end;

function TSimpletonMind.Thinking: TwwDirection;
var
  NewHead: TPoint;
  NewDir, TailDir: TwwDirection;
  LegalDirs: set of TwwDirection;
  Num: Integer;
  l_W: TwwWorm;
begin
  l_W:= Thing as TwwWorm;
  case l_W.Favorite of
   ftVertical:
    begin
     if l_W.Target.Head.Position.Y <> l_W.Head.Position.Y then
     begin
      if l_W.Target.Head.Position.Y - l_W.Head.Position.Y > 0 then
       NewDir:= dtDown
      else
       NewDir:= dtUp;
     end
     else
     begin
      if l_W.Target.Head.Position.X - l_W.Head.Position.X > 0 then
       NewDir:= dtRight
      else
       NewDir:= dtLeft;
     end;
    end; // ftVertical
   ftHorizontal:
    begin
     if l_W.Target.Head.Position.X <> l_W.Head.Position.X then
     begin
      if l_W.Target.Head.Position.X-l_W.Head.Position.X > 0 then
       NewDir:= dtRight
      else
       NewDir:= dtLeft;
     end
     else
     begin
      if l_W.Target.Head.Position.Y-l_W.Head.Position.Y > 0 then
       NewDir:= dtDown
      else
       NewDir:= dtUp;
     end;
    end; // ftHorizontal
  end; { case }
  MovePoint(l_W.Head.Position, NewDir, NewHead);
  if not IsFree(NewHead) then
  begin
    LegalDirs:= [dtLeft, dtUp, dtRight, dtDown];
    TailDir:= dtStop;
    if l_W.IsMe(NewHead) then
    begin
     TailDir:= l_W.ToTail(NewHead);
     if TailDir <> dtStop then
      NewDir:= TailDir;
    end; // isMe
    MovePoint(l_W.Head.Position, NewDir, NewHead);
    repeat
     if not IsFree(NewHead) then
     begin
      if not (NewDir in LegalDirs{[dtStop..dtDown]}) then
      begin
       Result:= dtStop;
       break;
      end; // not (NewDir in [dtStop..dtDown])
      Exclude(LegalDirs, NewDir);
      if ShiftDir(TailDir) = l_W.ToHead(NewHead) then
       NewDir:= ShiftDirLeft(NewDir)
      else
       NewDir:= ShiftDir(NewDir);
      MovePoint(l_W.Head.Position, NewDir, NewHead);
     end; // not IsFree
    until (IsFree(NewHead) or (LegalDirs = []));
    if LegalDirs = [] then
     NewDir:= dtStop;
  end;
  Result:= NewDir;
end;

{
********************************** TLazyMind ***********************************
}
function TLazyMind.GetCaption: string;
begin
  Result:= 'Ленивый Простак';
end;

function TLazyMind.GetEnglishCaption: string;
begin
  Result:= 'Lazy Simpleton'
end;

function TLazyMind.Thinking: TwwDirection;
begin
  TwwWorm(Thing).Target:= (Thing.World as TWormsField).NearestTarget(Thing.Head.Position);
  Result:= inherited Thinking;
end;

{
********************************* TGourmetMind *********************************
}
function TGourmetMind.GetCaption: string;
begin
  Result:= 'Простак-гурман'
end;

function TGourmetMind.GetEnglishCaption: string;
begin
  Result:= 'Gourmet'
end;

function TGourmetMind.Thinking: TwwDirection;
var
  l_C, l_D: TwwTarget;
begin
  l_C:= (Thing.World as TWormsField).PowerestTarget;
  l_D:= (Thing.World as TWormsField).NearestTarget(Thing.Head.Position);
  if l_D.Power = l_C.Power then
   TwwWorm(Thing).Target:= l_D
  else
   TwwWorm(Thing).Target:= l_C;
  Result := inherited Thinking;
end;


end.

