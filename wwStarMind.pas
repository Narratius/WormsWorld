unit wwStarMind;

interface

uses
  Types, Contnrs, SyncObjs,
  wwTypes, wwMinds;

type
  TwwNode = class (TObject)
  private
    FCostFromStart: Integer;
    FCostToFinish: Integer;
    FFinish: TPoint;
    FParent: TPoint;
    FPosition: TPoint;
    FStart: TPoint;
    function GetCost: Integer;
  public
    constructor Create(aPosition, aStart, aFinish : TPoint); reintroduce;
    function Clone: TwwNode;
    function CreateNear(aDirection: TwwDirection): TwwNode;
    property Cost: Integer read GetCost;
    property CostFromStart: Integer read FCostFromStart write FCostFromStart;
    property CostToFinish: Integer read FCostToFinish write FCostToFinish;
    property Parent: TPoint read FParent write FParent;
    property Position: TPoint read FPosition;
  end;

  TwwNodeList = class (TObjectList)
  public
    procedure AddNode(aNode: TwwNode); virtual;
    function HaveNode(aNode: TwwNode): Boolean;
    function NodeAt(aPoint: TPoint): TwwNode;
    procedure RemoveNode(aNode: TwwNode); virtual;
  end;

  TwwSortedNodeList = class (TwwNodeList)
  public
    procedure AddNode(aNode: TwwNode); override;
    procedure RemoveNode(aNode: TwwNode); override;
  end;

  TAStarMind = class (TwwMind)
  private
   f_Open: TwwSOrtedNodeList;
   f_Closed: TwwNodeList;
   f_CS: TCriticalSection;
  private
    function CalcCost(A, B: TPoint): Integer;
    function FindDir(A, B: TPoint): TwwDirection;
    function DummyThing: TwwDirection;
  protected
    function GetCaption: string; override;
    function GetEnglishCaption: string; override;
    function Thinking: TwwDirection; override;
  public
   constructor Create; override;
   destructor Destroy; override;
  end;


implementation

Uses
 wwUtils, wwWorms, WormsWorld, wwClasses,
 Math;


{
********************************** TAStarMind **********************************
}
function TAStarMind.CalcCost(A, B: TPoint): Integer;
begin
 (*
  if (IsFree(A) or Equal(A, Thing.Head.Position)) and IsFree(B) then
   Result:= CalcDistance(A, B)
  else
   Result:= High(Word);
 *)
 Result:= 1;
 if IsBusy(A) and not Equal(A, Thing.Head.Position) then
  Inc(Result, High(Word));
 if IsBusy(B) then
  Inc(Result, High(Word));
end;

constructor TAStarMind.Create;
begin
 inherited Create;
 f_Open:= TwwSOrtedNodeList.Create;
 f_Closed:= TwwNodeList.Create;
 f_CS:= TCriticalSection.Create;
end;

destructor TAStarMind.Destroy;
begin
 f_CS.Free;
 f_Open.Free;
 f_Closed.Free;
 inherited;
end;

function TAStarMind.DummyThing: TwwDirection;
var
  l_W: TwwWorm;
  NewHead: TPoint;
  TargetDir, NewDir: TwwDirection;
  LegalDirs: TwwDirections;
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
 Result:= NewDir;
end;

function TAStarMind.FindDir(A, B: TPoint): TwwDirection;
var
  l_Start, l_Current, l_NearCurrent: TwwNode;
  l_Skip: Boolean;
  i: TwwDirection;
  l_CostFrom: Integer;
  l_AllowFree: Boolean;
  l_Mem0, l_Mem1: Int64;
  procedure CreateRoad(aNode: TwwNode);
  var
   l_N: TwwNode;
  begin
   Result:= dtStop;
   l_N:= aNode;
   while not Equal(l_N.Position, A) and IsFree(l_N.Position) do
   begin
    Result:= CalcDir(l_N.Parent, l_N.Position, ftVertical);
    l_N:= f_Closed.NodeAt(l_N.Parent);
    if not CheckPoint(Thing.Head.Position, Result) then
     Result:= dtStop;
   end;
  end;

begin
 Result:= dtStop;
   l_Start:= TwwNode.Create(A, A, B);
   f_Open.AddNode(l_Start); // Список владеет объектом l_Start, удалять нельзя
   while f_Open.Count <> 0 do
   begin
    l_Current:= TwwNode(f_Open.First).Clone; // Сделали копию объекта, потом нужно грохнуть
    f_Open.RemoveNode(l_Current); // Уничтожили оригинал объекта
     if Equal(l_Current.Position, B) then
     begin
      CreateRoad(l_Current);
      l_Current.Free;
      break;
     end;
     for i:= dtLeft to dtDown do
     begin
      l_AllowFree:= True;
      l_NearCurrent:= l_Current.CreateNear(i); // Создали дополнительный объект
       if IsFree(l_NearCurrent.Position) then
       begin
        l_CostFrom:= l_Current.CostFromStart + CalcCost(l_Current.Position, l_NearCurrent.Position);
        l_Skip:= (f_Open.HaveNode(l_NearCurrent) or f_Closed.HaveNode(l_NearCurrent)) and
            (l_NearCurrent.CostFromStart <= l_CostFrom);
        if not l_Skip then
        begin
         l_NearCurrent.CostFromStart:= l_CostFrom;
         f_Closed.RemoveNode(l_NearCurrent); // Удаляем объект, указывающий на Position
         if not f_Open.HaveNode(l_NearCurrent) then
         begin
          f_Open.AddNode(l_NearCurrent); // Добавили объект в список, уничтожать нельзя
          l_AllowFree:= False;
         end; // not l_Open.HaveNode(l_NearCurrent)
        end; // подходящий узел
       end; // IsFree(l_NearCurrent.Position)
       if l_AllowFree then
        l_NearCurrent.Free; // Уничтожили дополнительный объект
     end; // for i
     f_Closed.AddNode(l_Current); // добавили объект в список
   end; // while l_Open.Count <> 0
   f_Open.Clear;
   f_Closed.Clear;
end;

function TAStarMind.GetCaption: string;
begin
  Result:= 'Тугодум'
end;

function TAStarMind.GetEnglishCaption: string;
begin
  Result:= 'Slowcoach'
end;

function TAStarMind.Thinking: TwwDirection;
var
 l_W: TwwWorm;
 i: Integer;
 l_T: TwwThing;
begin
 l_W:= Thing as TwwWorm;
 try
   l_W.Target:= (Thing.World as TWormsField).NearestTarget(Thing.Head.Position);
   if IsBusy(l_W.Target.Head.Position) then
   begin
    l_T:= l_W.Target;
    for i:= 0 to Pred((Thing.World as TWormsField).TargetCount) do
    begin
     if (Thing.World as TWormsField).Targets[i] <> l_T then
     begin
      l_W.Target:= (Thing.World as TWormsField).Targets[i];
      if IsFree(l_W.Target.Head.Position) then
       break;
     end
    end;
   end;
   Result:= FindDir(l_W.Head.Position, l_W.Target.Head.Position);
   if Result = dtStop then
   begin
    l_T:= l_W.Target;
    for i:= 0 to Pred((Thing.World as TWormsField).TargetCount) do
    begin
     if (Thing.World as TWormsField).Targets[i] <> l_T then
     begin
      l_W.Target:= (Thing.World as TWormsField).Targets[i];
      Result:= FindDir(l_W.Head.Position, l_W.Target.Head.Position);
      if Result <> dtStop then
       break;
     end; // (Thing.World as TWormsField).Targets[i] <> l_T
    end; // for i
    if Result = dtStop then
    begin
     l_W.Target:= l_T;
     Result:= DummyThing;
    end; // Result = dtStop
   end; // Result = dtStop
 finally
  f_CS.Release;
 end;

end;

{
*********************************** TwwNode ************************************
}
constructor TwwNode.Create(aPosition, aStart, aFinish : TPoint);
begin
 inherited Create;
  FStart:= aStart;
  FFinish:= aFinish;
  FPosition:= aPosition;
  FCostFromStart:= CalcDistance(aStart, FPosition);
  FCostToFinish:= CalcDistance(FPosition, aFinish);
  FParent:= Point(0, 0);
end;

function TwwNode.Clone: TwwNode;
begin
  Result:= TwwNode.Create(FPOsition, FStart, FFinish);
  Result.CostFromStart:= CostFromStart;
  Result.CostToFinish:= CostToFinish;
  Result.Parent:= Parent;
end;

function TwwNode.CreateNear(aDirection: TwwDirection): TwwNode;
var
 l_Pos: TPoint;
begin
  MovePoint(FPosition, aDirection, l_Pos);
  Result:= TwwNode.Create(l_Pos, FStart, FFinish);
  Result.Parent:= FPosition;
end;

function TwwNode.GetCost: Integer;
begin
  Result:= CostFromStart + CostToFinish;
end;

{
********************************* TwwNodeList **********************************
}
procedure TwwNodeList.AddNode(aNode: TwwNode);
begin
  Add(aNode{.Clone});
end;

function TwwNodeList.HaveNode(aNode: TwwNode): Boolean;
begin
  Result:= NodeAt(aNode.Position) <> nil;
end;

function TwwNodeList.NodeAt(aPoint: TPoint): TwwNode;
var
  I: Integer;
begin
  Result:= nil;
  for i:= 0 to Pred(Count) do
   if Equal(TwwNode(Items[i]).Position, aPoint) then
   begin
    Result:= TwwNode(Items[i]);
    break;
   end;
end;

procedure TwwNodeList.RemoveNode(aNode: TwwNode);
var
  I: Integer;
  l_N: TwwNode;
begin
  for i:= 0 to Pred(Count) do
  begin
   l_N:= TwwNode(Items[i]);
   if Equal(aNode.Position, l_N.Position) then
   begin
    Remove(l_N);
    //Delete(i);
    break;
   end; // Equal(aNode.Position, l_N.Position)
  end // for i
end;

function CompareCost(Item1, Item2: TObject): Integer;
begin
  Result := CompareValue((Item1 as TwwNode).Cost, TwwNode(Item2).Cost);
end;
{
****************************** TwwSortedNodeList *******************************
}
procedure TwwSortedNodeList.AddNode(aNode: TwwNode);
begin
  inherited AddNode(aNode);
  Sort(@CompareCost);
end;

procedure TwwSortedNodeList.RemoveNode(aNode: TwwNode);
begin
  inherited;
  Sort(@CompareCost);
end;


end.

