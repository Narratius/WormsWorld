unit wwClasses;
{ Базовые объекты мира червяков  }

interface

Uses
 Contnrs, Classes, SyncObjs,
 wwTypes, System.Types;

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
 TwwThing = class(TThread)
 private
  f_Points: TObjectList;
  f_IsDead: Boolean;
  f_Caption: String;
  f_Entity: TwwEntity;
  FVariety: Integer;
  FWorld: TwwWorld;
  FAge: Integer;
  FAbsoluteIndex: Integer;
  f_DefaultLength: Integer;
  f_InstantRessurrect: Boolean;
 private
  function GetHead: TwwPoint;
  function GetIsAlive: Boolean;
  function GetLength: Integer;
  function GetPoint(Index: Integer): TwwPoint;
  function GetTail: TwwPoint;
  procedure SetIsDead(const Value: Boolean);
  procedure SetIsAlive(const Value: Boolean);
  procedure SetLength(const Value: Integer);
 protected
  f_CS: TCriticalSection;
 protected
  function GetDefaultLength: Integer; virtual;
  procedure Execute; override;
 public
  constructor Create(aLock: TCriticalSection);
  destructor Destroy; override;
  procedure Enlarge(const aDelta: Integer);
  function IsMe(const aPoint: TPoint): Boolean;
  procedure Update; virtual;
  procedure Die; virtual;
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
  property InstantRessurrect: Boolean
   read f_InstantRessurrect
   write f_InstantRessurrect;
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
  property IsAlive: Boolean read GetIsAlive write SetIsAlive;
  property Entity: TwwEntity
   read f_Entity
   write f_Entity;
  property Variety: Integer read FVariety write FVariety;
  property World: TwwWorld read FWorld write FWorld;
  property Age: Integer read FAge;
  property AbsoluteIndex: Integer read FAbsoluteIndex;
 end;

 TwwWorld = class
 private
  f_Things: TObjectList;
  f_Bounds: TRect;
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
  function GetFree: TPoint;
  function ThingAt(const aPoint: TPoint): TwwThing;
  procedure Update; virtual;
  procedure Start;
  procedure Stop;
  procedure DeleteThing(aIndex: Integer);
  procedure AddThing(aThing: TwwThing);
  function GetNearestBorder(aPoint: TPoint; aDir: TwwFavoriteType): TPoint;
  function IsLegal(aPoint: TPoint): Boolean;
 public
  property Count: Integer
   read GetCount;
  property Things[Index: Integer]: TwwThing
   read GetThings;
  property Size: TRect
   read f_Bounds;
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

constructor TwwThing.Create;
begin
 inherited Create(True);
 Priority:= tpLower;

 f_Points:= TObjectList.Create;
 f_Caption:= '';
 f_DefaultLength:= 1;
 Entity:= weNotLive;
 f_InstantRessurrect:= True;
 f_CS := aLock;
end;

destructor TwwThing.Destroy;
begin
 FreeAndNil(f_Points);
 inherited;
end;

procedure TwwThing.Die;
begin
 IsDead:= True;
 if InstantRessurrect then
   Ressurect;
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

procedure TwwThing.Execute;
begin
 while not Terminated do
 begin
  Update;

 end;
end;

function TwwThing.GetHead: TwwPoint;
begin
 if Length > 0 then
  Result:= Points[0]
 else
  Result:= nil;
end;

function TwwThing.GetIsAlive: Boolean;
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



procedure TwwThing.SetIsDead(const Value: Boolean);
begin
 f_IsDead := Value;
end;

procedure TwwThing.SetIsAlive(const Value: Boolean);
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
 if IsAlive then
   Inc(FAge);
end;



procedure TwwThing.Ressurect;
begin
 f_CS.Acquire;
 try
   FAge:= 0;
   IsAlive:= False;
   if World <> nil then
   begin
     IsAlive:= True;
     Length:= DefaultLength;
     Head.Position:= World.GetFree;
   end; // World <> nil
 finally
   f_CS.Release;
 end;
end;

function TwwThing.GetDefaultLength: Integer;
begin
 Result:= f_DefaultLength;
end;


function TwwThing.PointIndex(aPoint: TPoint): Integer;
var
 i: Integer;
begin
 Result := -1;
 f_CS.Acquire;
 try
   if IsAlive then
   for i:= Pred(Length) downto 0 do
    if Equal(Points[i].Position, aPoint) then
    begin
     Result:= i;
     break;
    end;
 finally
   f_CS.Release;
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

constructor TwwWorld.Create(const aBounds: TRect);
begin
 inherited Create;
 f_Things:= TObjectList.Create;
 f_Bounds:= aBounds;
 ClearMap;
end;

destructor TwwWorld.Destroy;
begin
 FreeAndNil(f_Things);
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
    (*
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
    *)

    for i:= 0 to Pred(Count) do
     if Things[i].IsMe(aPoint) and (Things[i].Entity in aWhat) then
     begin
      Result:= True;
      aThing:= Things[i];
      break;
     end;

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
 if IsBusy(aPoint, l_T, [weLive, weNotLive]) then
   Result:= l_T
end;

function TwwWorld.GetCount: Integer;
begin
 Result:= f_Things.Count;
end;

function TwwWorld.GetFree: TPoint;
begin
  repeat
   Result.X := Random(Size.Right-5) + 5;
   Result.Y := Random(Size.Bottom-2) + 1;
  until IsFree(Result, weAny);
end;

function TwwWorld.GetThings(Index: Integer): TwwThing;
begin
 if InRange(Index, 0, Pred(Count)) then
  Result:= TwwThing(f_Things.Items[Index])
 else
  Result:= nil;
end;

procedure TwwWorld.Update;
var
 i: Integer;
 l_T: TwwThing;
begin
 ClearMap;
 // Червяки и цели - работает ли это?
 for i:= 0 to Pred(Count) do
 begin
  l_T:= Things[i];
  if l_T.IsAlive then
   AddThingToMap(l_T);
 end; // for i

 (* В многопоточном режиме смысла не имеет
 for i:= 0 to Pred(Count) do
 begin
  Things[i].Update;
  if Things[i].IsDead then
   Ressurect(Things[i]);
 end;
 *)
end;

procedure TwwWorld.Ressurect(aThing: TwwThing);
begin
 aThing.Ressurect;
end;

procedure TwwWorld.Start;
var
 i: Integer;
begin
 for I := 0 to Pred(f_Things.Count) do
  TwwThing(f_Things[i]).Start;
end;

procedure TwwWorld.Stop;
var
 i: Integer;
begin
 for I := 0 to Pred(f_Things.Count) do
  TwwThing(f_Things[i]).Terminate;
end;

procedure TwwWorld.DeleteThing(aIndex: Integer);
begin
 f_Things.Delete(aIndex);
end;

procedure TwwWorld.AddThing(aThing: TwwThing);
begin
 aThing.FAbsoluteIndex:= f_Things.Count;
 f_Things.Add(aThing);
 aThing.World:= Self;
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
 FillChar(FMap, SizeOf(FMap), -1);
 (*
 for i:= 0 to MapWidth do
  for j:= 0 to MapHeight do
   FMap[i, j]:= -1;
 *)
end;

function TwwWorld.GetNearestBorder(aPoint: TPoint; aDir: TwwFavoriteType):
    TPoint;
var
 l_Hor, l_Ver: Integer;
begin
  l_Hor:= Min(Size.Width-aPoint.X, aPoint.X);
  l_Ver:= Min(Size.Height-aPoint.Y, aPoint.Y);
  if aDir = ftVertical then
  begin
    Result.X:= aPoint.X;
    Result.Y := IfThen(aPoint.Y > l_Ver, Size.Height, 0);
  end
  else
  begin
    Result.X := IfThen(aPoint.X > l_Hor, Size.Width, 0);
    Result.Y := aPoint.Y;
  end;
end;

end.
