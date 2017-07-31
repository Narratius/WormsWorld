unit WormsWorld;

interface
Uses
 Types,
 wwClasses, wwWorms, wwMinds;

type
  TWormsField = class (TwwWorld)
  private
    FInstantRessurecctTargets: Boolean;
    FInstantRessurecctWorms: Boolean;
    FMaxTargetCount: Integer;
    FMaxWormsCount: Integer;
    FMindCenter: TwwMindCenter;
    function GetTargetCount: Integer;
    function GetTargets(Index: Integer): TwwTarget;
    function GetWorms(Index: Integer): TwwWorm;
    function GetWormsCount: Integer;
    procedure SetInstantRessurecctTargets(const Value: Boolean);
    procedure SetInstantRessurecctWorms(const Value: Boolean);
    procedure SetMaxTargetCount(const Value: Integer);
    procedure SetMaxWormsCount(const Value: Integer);
  protected
    procedure Ressurect(aThing: TwwThing); override;
    procedure RessurectTargets;
    procedure RessurectWorms;
  public
    constructor Create(const aBounds: TRect);
    destructor Destroy; override;
    function NearestTarget(const aPoint: TPoint): TwwTarget;
    function NearestWorm(const aPoint: TPoint): TwwWorm;
    function PowerestTarget: TwwTarget;
    function RandomTarget(const aPoint: TPoint): TwwTarget;
    procedure Update; override;
    property InstantRessurectTargets: Boolean read FInstantRessurecctTargets
            write SetInstantRessurecctTargets;
    property InstantRessurectWorms: Boolean read FInstantRessurecctWorms write
            SetInstantRessurecctWorms;
    property MaxTargetCount: Integer read FMaxTargetCount write
            SetMaxTargetCount;
    property MaxWormsCount: Integer read FMaxWormsCount write SetMaxWormsCount;
    property MindCenter: TwwMindCenter
     read FMindCenter;
    property TargetCount: Integer read GetTargetCount;
    property Targets[Index: Integer]: TwwTarget read GetTargets;
    property Worms[Index: Integer]: TwwWorm read GetWorms;
    property WormsCount: Integer read GetWormsCount;
  end;
  
implementation

Uses
 SysUtils, VCL.Forms,
 wwDummyMind, wwUtils, wwSimpleMind, wwMaratMinds, wwStarMind,
 wwFirst;

{ TWormsField }

{
********************************* TWormsField **********************************
}
constructor TWormsField.Create(const aBounds: TRect);
begin
  inherited Create(aBounds);
  FMindCenter:= TwwMindCenter.Create(ChangeFileExt(Application.ExeName, '.dat'));
  with FMindCenter do
  begin
   AddMind(TDummyMind.Create);
   AddMind(TCarefullMind.Create);
   AddMind(TImpudentMind.Create);
   AddMind(TCowardMind.Create);
   AddMind(TSimpletonMind.Create);
   AddMind(TLazyMind.Create);
   AddMind(TGourmetMind.Create);
   AddMind(TAStarMind.Create);
   AddMind(TFirstMind.Create);
  end;
end;

destructor TWormsField.Destroy;
begin
  FMindCenter.Free;
  inherited Destroy;
end;

function TWormsField.GetTargetCount: Integer;
var
  i: Integer;
  l_T: TwwThing;
begin
  Result:= 0;
  for i:= 0 to Pred(Count) do
  begin
   l_T:= Things[i];
   if (l_T is TwwTarget){ and l_T.IsLive} then
    Inc(Result);
  end;
end;

function TWormsField.GetTargets(Index: Integer): TwwTarget;
var
  i, l_Current: Integer;
  l_T: TwwThing;
begin
  l_Current:= 0;
  Result:= nil;
  for i:= 0 to Pred(Count) do
  begin
   l_T:= Things[i];
   if (l_T is TwwTarget){ and (l_T.IsLive)} then
   begin
    if (l_Current = Index) then
    begin
     Result:= l_T as TwwTarget;
     break;
    end
    else
     Inc(l_Current);
   end;
  end;
end;

function TWormsField.GetWorms(Index: Integer): TwwWorm;
var
  i, l_Current: Integer;
  l_T: TwwThing;
begin
  l_Current:= 0;
  Result:= nil;
  for i:= 0 to Pred(Count) do
  begin
   l_T:= Things[i];
   if (l_T is TwwWorm) then
    if (l_Current = Index) then
    begin
     Result:= l_T as TwwWorm;
     break;
    end
    else
     Inc(l_Current);
  end;
end;

function TWormsField.GetWormsCount: Integer;
var
  i: Integer;
  l_T: TwwThing;
begin
  Result:= 0;
  for i:= 0 to Pred(Count) do
  begin
   l_T:= Things[i];
   if (l_T is TwwWorm) and l_T.IsLive then
    Inc(Result);
  end;
end;

function TWormsField.NearestTarget(const aPoint: TPoint): TwwTarget;
var
  I: Integer;
  MinDelta: Integer;
  MinIndex: Integer;
  l_TD: Integer;
begin
  Result := nil;
  MinIndex:= -1;
  MinDelta:= High(MinDelta);
  if TargetCount = 0 then
   RessurectTargets;
  for i:= 0 to Pred(TargetCount) do
  begin
   if not Targets[i].IsLive then
     Targets[i].Ressurect;
   begin
    l_TD:= CalcDistance(aPoint, Targets[i].Head.Position);
    if l_TD < MinDelta then
    begin
     MinDelta:= l_TD;
     MinIndex:= i;
    end;
   end;
  end;
  if MinIndex > -1 then
   Result:= Targets[MinIndex];
end;

function TWormsField.NearestWorm(const aPoint: TPoint): TwwWorm;
var
  I: Integer;
  MinDelta: Integer;
  MinIndex: Integer;
  l_TD: Integer;
begin
  Result := nil;
  MinIndex:= -1;
  MinDelta:= High(MinDelta);
  if WormsCount = 0 then
   RessurectWorms;
  for i:= 0 to Pred(WormsCount) do
  begin
   if Worms[i].IsLive then
   begin
    l_TD:= CalcDistance(aPoint, Worms[i].Head.Position);
    if l_TD < MinDelta then
    begin
     MinDelta:= l_TD;
     MinIndex:= i;
    end;
   end;
  end;
  if MinIndex > -1 then
   Result:= Worms[MinIndex];
end;

function TWormsField.PowerestTarget: TwwTarget;
var
  l_Power: Integer;
  l_i, I: Integer;
begin
  l_Power:= 0;
  Result:= nil;
  if TargetCount = 0 then
    RessurectTargets;
  for i:= 0 to Pred(TargetCount) do
  begin
    if (Targets[i].Power > l_Power) and Targets[i].IsLive then
    begin
     l_Power:= Targets[i].Power;
     l_I:= i;
    end;
  end;
  Result:= Targets[l_i];
end;

function TWormsField.RandomTarget(const aPoint: TPoint): TwwTarget;
begin
  Result:= Targets[Random(TargetCount)];
end;

procedure TWormsField.Ressurect(aThing: TwwThing);
begin
  if (aThing is TwwWorm) and InstantRessurectWorms then
   aThing.Ressurect
  else
  if (aThing is TwwTarget) and InstantRessurectTargets then
   aThing.Ressurect;
end;

procedure TWormsField.RessurectTargets;
var
  i: Integer;
begin
  for i:= 0 to Pred(MaxTargetCount) do
   Targets[i].Ressurect;
end;

procedure TWormsField.RessurectWorms;
var
  i: Integer;
begin
  for i:= 0 to Pred(MaxWormsCount) do
   Worms[i].Ressurect;
end;

procedure TWormsField.SetInstantRessurecctTargets(const Value: Boolean);
begin
  FInstantRessurecctTargets := Value;
end;

procedure TWormsField.SetInstantRessurecctWorms(const Value: Boolean);
begin
  FInstantRessurecctWorms := Value;
end;

procedure TWormsField.SetMaxTargetCount(const Value: Integer);
var
  i: Integer;
begin
  FMaxTargetCount := Value;
  i:= 0;
  while i < Count do
  begin
   if Things[i] is TwwTarget then
    DeleteThing(i)
   else
    Inc(i);
  end;
  for i:= 0 to Pred(MaxTargetCount) do
   AddThing(TwwTarget.Create(Self));
end;

procedure TWormsField.SetMaxWormsCount(const Value: Integer);
var
  i: Integer;
begin
  FMaxWormsCount := Value;
  i:= 0;
  while i < Count do
  begin
   if Things[i] is TwwWorm then
    DeleteThing(i)
   else
    Inc(i);
  end;
  for i:= 0 to Pred(MaxWormsCount) do
   AddThing(TwwWorm.Create(Self, FMindCenter, i));
end;

procedure TWormsField.Update;
begin
  inherited;
  if TargetCount = 0 then
   RessurectTargets;
  if WormsCount = 0 then
   RessurectWorms;
end;

end.
