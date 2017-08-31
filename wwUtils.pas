unit wwUtils;

interface
Uses
 Types,
 wwTypes;

function Equal(A, B: TPoint): Boolean;
{ ѕровер€ет, совпадают ли координаты переданных точек }

procedure IncPoint(var APoint: TPoint; ADir: TwwDirection);
{ ѕеремещает переданную точку в указанном направлении }

procedure MovePoint(FromPoint: TPoint; Dir: TwwDirection; var ToPoint: TPoint); overload;
{ ѕеремещает переданную точку в указанном направлении }

function MovePoint(FromPoint: TPoint; Dir: TwwDirection): TPoint; overload
{ ѕеремещает переданную точку в указанном направлении }

function ShiftDir(ADir: TwwDirection): TwwDirection;
{ —двигает направление вправо }

function ShiftDirLeft(ADir: TwwDirection): TwwDirection;
{ —двигает направление влево }

function InvertDir(ADir: TwwDirection): TwwDirection;
{ ¬озвращает направление противоположное переданному }

function CalcDir(FromPoint, ToPoint: TPoint; FavoriteDir: TwwFavoriteType):
    TwwDirection;
{ ¬ычисл€ет направление от точки FromPoint на точку ToPoint с учетом приоритетного направлени€ }

function BodySegment(FromPoint, ToPoint, ZeroPoint: TPoint): TCurve;


function CalcDistance(A, B: TPoint): Integer;
{ ¬ычисл€ет рассто€ние между двум€ точками }

function IsTurn(A, B: TPoint): Boolean;
{ Ќаход€тс€ ли переданные точки на повороте }

function InvertFavorite(aFavorite: TwwFavoriteType): TwwFavoriteType;
{ »нвертирует приоритетное направление }

function Direction2FavType(aDir: TwwDirection): TwwFavoriteType;

implementation

const
(*
  Addition : array [TwwDirection, ..aY] of Integer = (
	           (0, 0), (0, 0), (-1, 0), (0, -1), (1, 0), (0, 1));
*)
  AddPoint : array[TwwDirection] of TPoint = (
             (X:0; Y:0), // dtNone,
             (X:0;Y:0),  // dtStop,
             (X:-1; Y:0),// dtLeft,
             (X:0; Y:-1),// dtUp,
             (X:1; Y:0), // dtRight,
             (X:0; Y:1));// dtDown

function BodySegment(FromPoint, ToPoint, ZeroPoint: TPoint): TCurve;
var
 P1, P2: TPoint;
begin
 if Equal(FromPoint, ToPoint) then
  Result:= ctNone
 else
 if FromPoint.X = ToPoint.X then
 begin
  if FromPoint.Y > ToPoint.Y then
   Result:= ctUp
  else
   Result:= ctDown
 end
 else
 if FromPoint.Y = ToPoint.Y then
 begin
  if FromPoint.X > ToPoint.X then
   Result:= ctLeft
  else
   Result:= ctRight
 end
 else
 if (FromPoint.X < ToPoint.X) and (FromPoint.Y > ToPoint.Y) and
    (ZeroPoint.X = ToPoint.X) and (ZeroPoint.Y = FromPoint.Y) then
  Result:= ctLeftUp
 else
 if (FromPoint.X > ToPoint.X) and (FromPoint.Y < ToPoint.Y) and
    (ZeroPoint.X = FromPoint.X) and (ZeroPoint.Y = ToPoint.Y) then
  Result:= ctLeftUp
 else
 if (FromPoint.X < ToPoint.X) and (FromPoint.Y < ToPoint.Y) and
    (ZeroPoint.X = FromPoint.X) and (ZeroPoint.Y = ToPoint.Y) then
  Result:= ctRightUp
 else
 if (FromPoint.X > ToPoint.X) and (FromPoint.Y > ToPoint.Y) and
    (ZeroPoint.X = ToPoint.X) and (ZeroPoint.Y = FromPoint.Y) then
  Result:= ctRightUp
 else
 if (FromPoint.X < ToPoint.X) and (FromPoint.Y > ToPoint.Y) and
    (ZeroPoint.X = FromPoint.X) and (ZeroPoint.Y = ToPoint.Y) then
  Result:= ctRightDown
 else
 if (FromPoint.X > ToPoint.X) and (FromPoint.Y < ToPoint.Y) and
    (ZeroPoint.X = ToPoint.X) and (ZeroPoint.Y = FromPoint.Y) then
  Result:= ctRightDown
 else
  REsult:= ctLeftDown
end;



function Equal(A, B: TPoint): Boolean;
begin
  Result:= A = B// (A.X = B.X) and (A.Y = B.Y);
end;



function ShiftDir(ADir: TwwDirection): TwwDirection;
begin
  case ADir of
    dtUp: ShiftDir:= dtRight;
    dtRight: ShiftDir:= dtDown;
    dtDown: ShiftDir:= dtLeft;
    dtLeft: ShiftDir:= dtUp;
  else
    ShiftDir:= ADir;
  end;
end;

function ShiftDirLeft(ADir: TwwDirection): TwwDirection;
begin
  case ADir of
    dtUp: ShiftDirLeft:= dtLeft;
    dtRight: ShiftDirLeft:= dtUp;
    dtDown: ShiftDirLeft:= dtRight;
    dtLeft: ShiftDirLeft:= dtDown;
  else
    ShiftDirLeft:= ADir;
  end;
end;

function InvertDir(ADir: TwwDirection): TwwDirection;
begin
  case ADir of
    dtUp   : Result:= dtDown;
    dtRight: Result:= dtLeft;
    dtDown : Result:= dtUp;
    dtLeft : Result:= dtRight;
  else
    Result:= ADir;
  end;
end;

function CalcDir(FromPoint, ToPoint: TPoint; FavoriteDir: TwwFavoriteType):
    TwwDirection;
var
  Delta: TPoint;
  i: Integer;
begin
  Result:= dtStop;
  Delta:= FromPoint - ToPoint;

  if (Delta.X <> 0) and (Delta.Y <> 0) then
  begin
   if FavoriteDir = ftVertical then
    Delta.X:= 0
   else
    Delta.Y:= 0;
  end; // (Delta.X <> 0) and (Delta.Y <> 0)

  if Delta.X > 0 then
    Delta.X:= -1
  else
  if Delta.X < 0 then
    Delta.X:= 1;

  if Delta.Y > 0 then
    Delta.Y:= -1
  else
  if Delta.Y < 0 then
    Delta.Y:= 1;

  Result:= dtStop;
  for i:= Ord(dtLeft) to Ord(High(TwwDirection)) do
   if Equal(AddPoint[TwwDirection(i)], Delta) then
   begin
    Result:= TwwDirection(i);
    break;
   end;
end;


procedure IncPoint(var APoint: TPoint; ADir: TwwDirection);
begin
  APoint.X:= APoint.X + AddPoint[ADir].X;
  APoint.Y:= APoint.Y + AddPoint[ADir].Y;
end;


procedure MovePoint(FromPoint: TPoint; Dir: TwwDirection; var ToPoint: TPoint);
begin
  ToPoint:= FromPoint;
  IncPoint(ToPoint, Dir);
end;

function MovePoint(FromPoint: TPoint; Dir: TwwDirection): TPoint;
begin
 Result:= FromPoint;
 IncPoint(Result, Dir);
end;

function CalcDistance(A, B: TPoint): Integer;
begin
 Result:= Abs(A.X - B.X) + Abs(A.Y - B.Y);
end;

function IsTurn(A, B: TPoint): Boolean;
begin
 Result:= Abs(A.X - B.X) + Abs(A.Y - B.Y) > 1;
end;

function InvertFavorite(aFavorite: TwwFavoriteType): TwwFavoriteType;
begin
 if aFavorite = ftVertical then
  Result:= ftHorizontal
 else
  Result:= ftVertical;
end;

function Direction2FavType(aDir: TwwDirection): TwwFavoriteType;
begin
  if aDir in [dtLeft, dtRight] then
    Result := ftHorizontal
  else
  if aDir in [dtUp, dtDown] then
    Result:= ftVertical
  else
    Result:= ftHorizontal;
end;

end.
