unit wwClasses;
{ Базовые объекты мира червяков  }

interface

Uses
 Types, Contnrs, Classes,
 wwTypes;

const
  MapHeight = 499;
  MapWidth = 499;

Type
 TwwPoint = class
  Position: TPoint;
  Value   : Integer;
  procedure MoveTo(aDirection : TwwDirection);
 end;

 TwwWorld = class;
 TwwThing = class(TObject)
 private
  f_Points: TObjectList;
  f_IsDead: Boolean;
  f_Caption: String;
  f_Direction: TwwDirection;
  f_Entity: TwwEntity;
  FVariety: Integer;
  FWorld: TwwWorld;
  FAge: Integer;
  FAbsoluteIndex: Integer;
 private
  function GetHead: TwwPoint;
  function GetIsLive: Boolean;
  function GetLength: Integer;
  function GetPoint(Index: Integer): TwwPoint;
  function GetTail: TwwPoint;
  procedure SetIsDead(const Value: Boolean);
  procedure SetIsLive(const Value: Boolean);
  procedure SetLength(const Value: Integer);
 protected
  procedure CorrectSegments; virtual;
  procedure Move;
  procedure WhileStop; virtual;
  function GetDefaultLength: Integer; virtual;
  procedure Think; virtual;
 public
  constructor Create(aWorld: TwwWorld; const aLength: Integer);
  destructor Destroy; override;
  procedure Enlarge(const aDelta: Integer);
  function IsMe(const aPoint: TPoint): Boolean;
  procedure Update; virtual;
  procedure Die; virtual;
  function Eat(const aPOint: TPoint): Boolean; virtual;
  function IsFree(const aPOint: TPoint; aWhat: TwwEntities = [weLive]): Boolean;
  function IsBusy(const aPOint: TPoint): Boolean;
  procedure Ressurect; virtual;
  function PointIndex(aPoint: TPoint): Integer;
  procedure AddPoint(aPoint: TPoint);
 public
  property Caption: String
   read f_Caption
   write f_Caption;
  property DefaultLength: Integer
   read GetDefaultLength;
  property Head: TwwPoint
   read GetHead;
  property Tail: TwwPoint
   read GetTail;
  property Length: Integer
   read GetLength
   write SetLength;
  property Points[Index: Integer]: TwwPoint
   read GetPoint;
  property IsDead: Boolean
   read f_IsDead
   write SetIsDead;
  property IsLive: Boolean
   read GetIsLive
   write SetIsLive;
  property Entity: TwwEntity
   read f_Entity
   write f_Entity;
  property Direction: TwwDirection
   read f_Direction
   write f_Direction;
  property Variety: Integer read FVariety write FVariety;
  property World: TwwWorld read FWorld write FWorld;
  property Age: Integer read FAge;
  property AbsoluteIndex: Integer read FAbsoluteIndex;
 end;

 TwwIdeas = class(TwwThing)
 private

 protected

 public
  constructor Create(aWorld: TwwWorld; const aLength: Integer);
  procedure Ressurect; override;
 end;

 TwwWorld = class
 private
  f_Things: TObjectList;
  f_Bounds: TRect;
  f_Ideas : TwwIdeas;
  f_OnNewIdea: TNotifyEvent;
  FNotIdea: Boolean;
  FMap: array[0..MapWidth, 0..MapHeight] of Integer;
  function GetCount: Integer;
  function GetThings(Index: Integer): TwwThing;
  procedure AddThingToMap(aThing: TwwThing);
  procedure ClearMap;
 protected
  procedure Ressurect(aThing: TwwThing); virtual;
 public
  constructor Create(const aBounds: TRect);
  destructor Destroy; override;
  function IsFree(const aPOint: TPoint; aWhat: TwwEntities = [weLive]): Boolean;
  function IsBusy(const aPOint: TPoint; aWhat: TwwEntities = [weLive]): Boolean;
      overload;
  function IsBusy(const aPoint: TPoint; var aThing: TwwThing; aWhat: TwwEntities
      = [weLive]): Boolean; overload;
  function ThingAt(const aPoint: TPoint): TwwThing;
  procedure Update; virtual;
  procedure DeleteThing(aIndex: Integer);
  procedure AddThing(aThing: TwwThing);
  function IsLegal(aPoint: TPoint): Boolean;
 public
  property Count: Integer
   read GetCount;
  property Things[Index: Integer]: TwwThing
   read GetThings;
  property Size: TRect
   read f_Bounds;
  property OnNewIdea: TNotifyEvent
   read f_OnNewIdea
   write f_OnNewIdea;
 end;

implementation

Uses
 Math, SysUtils,
 wwUtils;

{ TwwPoint }

procedure TwwPoint.MoveTo(aDirection: TwwDirection);
begin
 IncPoint(Position, aDirection);
end;

{ TwwThing }

constructor TwwThing.Create(aWorld: TwwWorld; const aLength: Integer);
begin
 inherited Create;
 World:= aWorld;
 f_Points:= TObjectList.Create;
 f_Caption:= '';
 Enlarge(aLength);
 Entity:= weNotLive;
end;

destructor TwwThing.Destroy;
begin
 f_Points.Free;
  inherited;
end;

procedure TwwThing.Die;
begin
 IsDead:= True;
end;

procedure TwwThing.Enlarge(const aDelta: Integer);
var
 i: Integer;
 l_P: TwwPoint;
 l_Tail: TwwPoint;
 l_Value: Integer;
begin
 if aDelta > 0 then
  for i:= 1 to aDelta do
  begin
   l_P:= TwwPoint.Create;
   if Length > 1 then
    l_P.Position:= Tail.Position;
   f_Points.Add(l_P);
  end
 else
 if aDelta < 0 then
 begin
  i:= 0;
  while i <> Abs(aDelta) do
  begin
   l_Tail:= Tail;
   f_Points.Delete(Pred(f_Points.Count));
   Inc(i);
   if Length <= DefaultLength then
   begin
    Die;
    break;
   end; // Length <= DefaultLenght
  end;
 end;
end;

function TwwThing.GetHead: TwwPoint;
begin
 if Length > 0 then
  Result:= Points[0]
 else
  Result:= nil;
end;

function TwwThing.GetIsLive: Boolean;
begin
 Result:= not IsDead;
end;

function TwwThing.GetLength: Integer;
begin
 Result:= f_Points.Count;
end;

function TwwThing.GetPoint(Index: Integer): TwwPoint;
begin
 if InRange(Index, 0, Pred(Length)) then
  Result:= TwwPoint(f_Points.Items[Index])
 else
  Result:= nil;
end;

function TwwThing.GetTail: TwwPoint;
begin
 if Length > 0 then
  Result:= Points[Pred(Length)]
 else
  Result:= nil;
end;

function TwwThing.IsMe(const aPoint: TPoint): Boolean;
begin
 Result:= PointIndex(aPoint) <> -1;
end;

procedure TwwThing.Move;
var
 i: Integer;
 l_Head: TPoint;
begin
 if IsLive and (Direction <> dtNone) then
 begin
  if Direction = dtStop then
   WhileStop
  else
  begin
   l_Head:= MovePoint(Head.Position, Direction);
   
   if World.IsLegal(l_Head) and 
      (IsFree(l_Head, [weLive, weNotLive]) or Eat(l_Head)) then
   begin
    for i:= Pred(Length) downto 1 do
     Points[i].Position:= Points[Pred(i)].Position;
    Head.Position:= l_Head;
    CorrectSegments;
   end
   else
    Die;
  end;
 end;
end;

procedure TwwThing.CorrectSegments;
var
 i: Integer;
 l_Value: Integer;
begin
 case Direction of
  dtUp: l_Value:= ws_HeadU;
  dtDown: l_Value:= ws_HeadD;
  dtLeft: l_Value:= ws_HeadR;
  dtRight: l_Value:= ws_HeadL;
 else
  l_Value:= Head.Value;
 end;
 Head.Value:= l_Value;
 if Length > 2 then
  for i:= 1 to Length-2 do
  begin
   case BodySegment(Points[Succ(i)].Position, Points[Pred(i)].Position, Points[i].Position) of
    ctUp, ctDown    : l_Value:= ws_BodyV;
    ctRight, ctLeft : l_Value:= ws_BodyH;
    ctLeftUp        : l_Value:= ws_RotUL;
    ctLeftDown      : l_Value:= ws_RotD;
    ctRightUp       : l_Value:= ws_RotUR;
    ctRightDown     : l_Value:= ws_RotL;
   else
    l_Value:= Points[i].Value;
   end; // case
   Points[i].Value:= l_Value;
  end; // for i
 case CalcDir(Points[Pred(Length)].Position, Points[Pred(Pred(Length))].Position, ftVertical) of
  dtUp: l_Value:= ws_TailU;
  dtDown: l_Value:= ws_TailD;
  dtLeft: l_Value:= ws_TailR;
  dtRight: l_Value:= ws_TailL;
 else
  l_Value:= Tail.Value;
 end;
 Tail.Value:= l_Value;
end;

procedure TwwThing.SetIsDead(const Value: Boolean);
begin
 f_IsDead := Value;
end;

procedure TwwThing.SetIsLive(const Value: Boolean);
begin
 IsDead:= not Value;
end;

procedure TwwThing.SetLength(const Value: Integer);
begin
 f_Points.Clear;
 Enlarge(Value);
end;


procedure TwwThing.Update;
begin
 Inc(FAge);
 Think;
 Move;
end;

procedure TwwThing.WhileStop;
begin
end;

function TwwThing.Eat(const aPoint: TPoint): Boolean;
begin
 Result:= IsFree(aPoint);
end;

function TwwThing.IsBusy(const aPOint: TPoint): Boolean;
begin
 Result:= World.IsBusy(aPoint);
end;

function TwwThing.IsFree(const aPOint: TPoint; aWhat: TwwEntities = [weLive]): 
    Boolean;
begin
 Result:= World.IsFree(aPoint, aWhat);
end;


procedure TwwThing.Ressurect;
var
 A: TPoint;
begin
 FAge:= 0;
 IsLive:= True;
 repeat
  A.X := Random(World.Size.Right-5) + 5;
  A.Y := Random(World.Size.Bottom-2) + 1;
 until IsFree(A);
 Length:= DefaultLength;
 Head.Position:= A;
end;

function TwwThing.GetDefaultLength: Integer;
begin
 Result:= 1;
end;

procedure TwwThing.Think;
begin

end;

function TwwThing.PointIndex(aPoint: TPoint): Integer;
var
 i: Integer;
begin
 Result := -1;
 if IsLive then
 for i:= Pred(Length) downto 0 do
  if Equal(Points[i].Position, aPoint) then
  begin
   Result:= i;
   break;
  end;
end;

procedure TwwThing.AddPoint(aPoint: TPoint);
var
 l_P: TwwPoint;
begin
 l_P:= TwwPoint.Create;
 l_P.Position:= aPoint;
 f_Points.Add(l_P);
end;

{ TwwWorld }

constructor TwwWorld.Create;
begin
 inherited Create;
 f_Things:= TObjectList.Create;
 f_Bounds:= aBounds;
 f_Ideas:= TwwIdeas.Create(Self, 0);
 FNotIdea:= False;
 ClearMap;
end;

destructor TwwWorld.Destroy;
begin
 f_Ideas.Free;
 f_Things.Free;
 inherited;
end;

function TwwWorld.IsBusy(const aPOint: TPoint; aWhat: TwwEntities = [weLive]):
    Boolean;
var
 l_T: TwwThing;
begin
 Result:= IsBusy(aPoint, l_T, aWhat);
end;

function TwwWorld.IsBusy(const aPoint: TPoint; var aThing: TwwThing; aWhat:
    TwwEntities = [weLive]): Boolean;
var
 i: Integer;
 l_T: TwwThing;
begin
 aThing:= nil;
 Result:= False;
 if IsLegal(aPoint) then
 begin
  {$IFDEF UseArray}
  i:= FMap[aPoint.X, aPoint.Y];
  if i > -1 then
  begin

   l_T:= Things[i];
   if l_T.Entity in aWhat then
   begin
    aThing:= l_T;
    Result:= True;
   end;
  end; // i > -1
  {$ELSE}

  for i:= 0 to Pred(Count) do
   if Things[i].IsMe(aPoint) and (Things[i].Entity in aWhat) then
   begin
    Result:= True;
    aThing:= Things[i];
    break;
   end;
  {$ENDIF}
  (*
  if not FNotIdea then
  begin
   f_Ideas.AddPoint(aPoint);
   if Assigned(f_OnNewIdea) then
    f_OnNewIdea(Self);
  end;
  *)
 end
 else
  Result:= True;
end;

function TwwWorld.IsFree(const aPOint: TPoint; aWhat: TwwEntities = [weLive]):
    Boolean;
begin
 Result:= not IsBusy(aPoint, aWhat);
end;

function TwwWorld.ThingAt(const aPoint: TPoint): TwwThing;
var
 l_T: TwwThing;
begin
 Result:= nil;
 FNotIdea:= True;
 try
  if IsBusy(aPoint, l_T, [weLive, weNotLive]) then
   Result:= l_T
  else
   if f_Ideas.IsMe(aPoint) then
    Result:= f_Ideas;
 finally
  FNotIdea:= False;
 end
end;

function TwwWorld.GetCount: Integer;
begin
 Result:= f_Things.Count;
end;

function TwwWorld.GetThings(Index: Integer): TwwThing;
begin
 if InRange(Index, 0, Pred(Count)) then
  Result:= TwwThing(f_Things.Items[Index]);
end;

procedure TwwWorld.Update;
var
 i, j: Integer;
 l_T: TwwThing;
begin
 ClearMap;
 for i:= 0 to Pred(Count) do
 begin
  l_T:= Things[i];
  if l_T.IsLive then
   AddThingToMap(l_T);
 end; // for i
 for i:= 0 to Pred(Count) do
 begin
  f_Ideas.Ressurect;
  Things[i].Update;
  if Things[i].IsDead then
   Ressurect(Things[i])
  else
   AddThingToMap(l_T);
 end;
end;

procedure TwwWorld.Ressurect(aThing: TwwThing);
begin
 aThing.Ressurect;
end;

procedure TwwWorld.DeleteThing(aIndex: Integer);
var
 l_O: TObject;
begin
 l_O:= f_Things.Items[aIndex];
 f_Things.Delete(aIndex);
 FreeAndNil(l_O);
end;

procedure TwwWorld.AddThing(aThing: TwwThing);
begin
 aThing.FAbsoluteIndex:= f_Things.Count;
 f_Things.Add(aThing);
 aThing.Ressurect;
end;

function TwwWorld.IsLegal(aPoint: TPoint): Boolean;
begin
 Result:= f_Bounds.Contains(aPoint);
end;

procedure TwwWorld.AddThingToMap(aThing: TwwThing);
var
 j: Integer;
begin
  for j:= 0 to Pred(aThing.Length) do
   FMap[aThing.Points[j].Position.X, aThing.Points[j].Position.Y]:= aThing.AbsoluteIndex;
end;

procedure TwwWorld.ClearMap;
var
 i, j: Integer;
begin
 for i:= 0 to MapWidth do
  for j:= 0 to MapHeight do
   FMap[i, j]:= -1;
end;

{ TwwIdeas }

constructor TwwIdeas.Create(aWorld: TwwWorld; const aLength: Integer);
begin
 inherited Create(aWorld, 0);
 Variety:= -1;
end;

procedure TwwIdeas.Ressurect;
begin
 Length:= 0;
end;

end.
