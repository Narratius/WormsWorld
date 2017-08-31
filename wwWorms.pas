unit wwWorms;

interface
Uses
 Types, SyncObjs,
 wwClasses, wwTypes, wwMinds;

type
  TwwThinkingThing = class(TwwThing)
  private
    f_Mind: TwwMind;
    f_MindCenter: TwwMindCenter;
    f_Direction: TwwDirection;
    procedure ChangeMind;
  protected
    function Eat(const aPoint: TPoint): Boolean; virtual;
    procedure Move; virtual;
    procedure WhileStop; virtual;
    procedure Think; virtual;
  public
    constructor Create(aMindCenter: TwwMindCenter; aLock: TCriticalSection); reintroduce; virtual;
    destructor Destroy; override;
    procedure Update; override;
    procedure Ressurect; override;
  public
    property Direction: TwwDirection
     read f_Direction
     write f_Direction;
  end;

  TwwTarget = class (TwwThinkingThing)
  private
    f_Power: Integer;
    FPower: Integer;
  protected
    procedure Think; override;
  public
    constructor Create(aMindCenter: TwwMindCenter; aLock: TCriticalSection); override;
    procedure Ressurect; override;
    property Power: Integer read FPower;
  end;

  TwwWorm = class (TwwThinkingThing)
  private
    FTarget: TwwThing;
    FFavorite: TwwFavoriteType;
    FStopTurns: Integer;
    FTargetCount: Integer;
    procedure FindTarget;
  protected
    procedure CorrectSegments; virtual;
    function GetDefaultLenght: Integer;
    function GetDefaultLength: Integer; override;
    procedure Move; override;
    procedure Think; override;
    procedure WhileStop; override;
  public
    constructor Create(aMindCenter: TwwMindCenter; aLock: TCriticalSection); override;
    procedure Die; override;
    function Eat(const aPOint: TPoint): Boolean; override;
    function IsNeck(const aPoint: TPoint): Boolean;
    procedure Ressurect; override;
    function ToHead(A: TPoint): TwwDirection;
    function ToTail(A: TPoint): TwwDirection;
    function ToNeck: TwwDirection;
    property Favorite: TwwFavoriteType read FFavorite write FFavorite;
    property Target: TwwThing read FTarget write FTarget;
    property Mind: TwwMind
     read f_Mind;
    property TargetCount: Integer read FTargetCount;
  end;

implementation

Uses
 Math,
 wwUtils, SysUtils, System.TypInfo;

const
 MinWormLength = 5;
 TargetsVarieties : array[0..1] of Integer =  (0, 1);
 TargetName : array[0..1] of String = ('Apple', 'Orange');
 TargetPower : array[0..1] of Integer = (5, 3);
 MaxStopTurns = 3;

type
  RwwMind = class of TwwMind;
{
*********************************** TwwWorm ************************************
}
constructor TwwWorm.Create(aMindCenter: TwwMindCenter; aLock: TCriticalSection);
begin
  inherited Create(aMindCenter, aLock);
  Caption:= 'Worm';
  Entity:= weLive;
end;

function TwwWorm.Eat(const aPOint: TPoint): Boolean;
var
 l_T: TwwThing;
begin
 // ѕроверить, €вл€етс€ ли данна€ точка нашей целью
 Result:= False;
 l_T:= World.ThingAt(aPoint);
 if (l_T <> nil) and (l_T.Entity = weNotLive) then
 begin
  Enlarge(TwwTarget(l_T).Power);
  Inc(FTargetCount);
  l_T.Die;
  if Target = l_T then
    FindTarget;
  Result:= True;
 end;

 (*
 if Equal(aPoint, Target.Head.Position) then
 begin
  Enlarge(TwwTarget(Target).Power);
  Inc(FTargetCount);
  Target.Die;
  Target:= nil;
  Result:= True;
 end
 else
 begin
  l_T:= World.ThingAt(aPoint);
  Result:= (l_T = nil) or (l_T.Entity = weNotLive);
 end;
 *)
end;

function TwwWorm.GetDefaultLenght: Integer;
begin
  Result := MinWormLength;
end;

function TwwWorm.GetDefaultLength: Integer;
begin
  Result:= MinWormLength;
end;

function TwwWorm.IsNeck(const aPoint: TPoint): Boolean;
begin
  if Length > 1 then
   Result:= IsMe(aPoint) and Equal(Points[1].Position, aPoint)
  else
   Result:= False;
end;

procedure TwwWorm.Move;
begin
  inherited;
  CorrectSegments;
end;

procedure TwwWorm.Ressurect;
var
 i: Integer;
 {$IFNDEF Delphi7}
 l_P: TPoint;
 {$ENDIF}
begin
 inherited;

 if f_Mind <> nil then
 begin
  Caption:= f_Mind.Caption;
  f_CS.Acquire;
  try
    Target:= f_Mind.FindTarget(Self) ;
  finally
    f_CS.Release
  end;
 end;
 Head.Value:= ws_HeadL;
 for i:= 1 to Length-2 do
 begin
  Points[i].Position:= Head.Position;
  {$IFDEF Delphi7}
  Points[i].Position.X:= Head.Position.X{ - i};
  {$ELSE}
  l_P:= Points[i].Position;
  l_P.X:= Head.Position.X;
  Points[i].Position:= l_P;
  {$ENDIF}
  Points[i].Value:= ws_BodyH;
 end;
 Tail.Position:= Head.Position;
  {$IFDEF Delphi7}
  Tail.Position.X:= Head.Position.X{ - i};
  {$ELSE}
  l_P:= Points[i].Position;
  l_P.X:= Tail.Position.X;
  Tail.Position:= l_P;
  {$ENDIF}
 Tail.Value:= ws_TailL;
 FTargetCount:= 0;
end;

procedure TwwWorm.Think;
begin
 inherited;
 if Direction <> dtStop then
  FStopTurns:= 0;
end;

function TwwWorm.ToHead(A: TPoint): TwwDirection;
var
 l_Index: Integer;
begin
 Result:= dtStop;
 l_Index:= PointIndex(A);
 if (l_Index > 0) then
  Result:= CalcDir(A, Points[Pred(l_Index)].Position, ftVertical)
end;

function TwwWorm.ToTail(A: TPoint): TwwDirection;
var
 l_IndexA, l_Tail: Integer;
begin
 Result:= dtStop;
 l_IndexA:= PointIndex(A);
 if (l_IndexA <> -1) and (l_IndexA < Length) then
 begin
  while Equal(A, Tail.Position) do
  begin
   Dec(l_IndexA);
   A:= Points[l_IndexA].Position;
  end;
  while IsTurn(A, Points[Succ(l_IndexA)].Position) do
  begin
   Dec(l_IndexA);
   A:= Points[l_IndexA].Position;
  end;
  Result:= CalcDir(A, Points[Succ(l_IndexA)].Position, ftVertical)
 end;
end;

function TwwWorm.ToNeck: TwwDirection;
begin
 Result:= CalcDir(Head.Position, Points[1].Position, ftVertical)
end;

procedure TwwWorm.WhileStop;
begin
 Enlarge(-5);
 Inc(FStopTurns);
 if FStopTurns > MaxStopTurns then
  Die;
end;

procedure TwwWorm.FindTarget;
begin
 if f_Mind <> nil then
  Target:= f_Mind.FindTarget(Self) as TwwTarget;
end;

{ TwwTarget }

{
********************************** TwwTarget ***********************************
}
constructor TwwTarget.Create(aMindCenter: TwwMindCenter; aLock: TCriticalSection);
begin
  inherited Create(aMindCenter, aLock);
  Caption:= 'Target';
  Entity:= weNotLive;
end;

procedure TwwTarget.Ressurect;
begin
  inherited;
  Variety:= RandomFrom(TargetsVarieties);
  Head.Value:= ws_Target;
  Caption:= TargetName[Variety];
  FPower:= TargetPower[Variety];
end;

procedure TwwTarget.Think;
begin
  if Variety = 0 then
   inherited
  else
   Direction:= dtNone;
end;

procedure TwwWorm.Die;
begin
 inherited;
 if f_Mind <> nil then
  f_Mind.PostMorten(Self);
end;

procedure TwwWorm.CorrectSegments;
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


{ TwwThinkingThing }

{
*********************************** TwwThinkingThing ************************************
}
constructor TwwThinkingThing.Create(aMindCenter: TwwMindCenter; aLock: TCriticalSection);
begin
  inherited Create(aLock);
  Caption:= 'ThinkingThing';
  Entity:= weLive;
  f_MindCenter:= aMindCenter;
end;

procedure TwwThinkingThing.Move;
var
 i: Integer;
 l_Head: TPoint;
begin
 if IsAlive and (Direction <> dtNone) then
 begin
  if Direction = dtStop then
   WhileStop
  else
  begin
   l_Head:= MovePoint(Head.Position, Direction);
   if World.IsLegal(l_Head) and
      (Eat(l_Head) or World.IsFree(l_Head, [weLive, weNotLive])) then
   begin
    for i:= Pred(Length) downto 1 do
     Points[i].Position:= Points[Pred(i)].Position;
    Head.Position:= l_Head;
   end
   else
    Die;
  end;
 end;
end;

procedure TwwThinkingThing.Ressurect;
begin
  inherited;
  f_MindCenter.PostMorten(f_Mind);
  ChangeMind;
end;


destructor TwwThinkingThing.Destroy;
begin
  FreeAndNil(f_Mind);
  inherited;
end;

(*
function TddCustomConfigNode.Clone(anOwner: TObject = nil): Pointer;
  {virtual;}
  {-}
begin
 Result := RddBaseConfigNode(ClassType).Create(Alias, Caption);
 TddCustomConfigNode(Result).Assign(Self);
end;
*)
procedure TwwThinkingThing.ChangeMind;
var
  l_Mind: TwwMind;
begin
  FreeAndNil(f_Mind);
  l_Mind := f_MindCenter.RandomMind(Entity);
  if l_Mind <> nil then
  begin
    f_Mind := RwwMind(l_Mind.ClassType).Create;
  end;
end;

procedure TwwThinkingThing.Think;
begin
 f_CS.Acquire;
 try
   if f_Mind = nil then
     ChangeMind;
   if f_Mind <> nil then
    Direction:= f_Mind.Think(Self)
   else
    Direction:= dtNone;
 finally
   f_CS.Release
 end;
end;

procedure TwwThinkingThing.Update;
begin
 inherited;
 Think;
 Move;
 //Sleep(25);
end;

procedure TwwThinkingThing.WhileStop;
begin

end;


function TwwThinkingThing.Eat(const aPoint: TPoint): Boolean;
begin
 Result:= World.IsFree(aPoint); // ?????
end;


end.

