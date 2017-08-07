unit wwMinds;

interface
Uses
 Contnrs, IniFiles,
 wwClasses, wwTypes, System.Types;

type
 TwwMind = class//(TThread)
 private
  f_CurrentThing: TwwThing;
  FMaxThingAge: Integer;
  FMaxThingLength: Integer;
  FWeight: Integer;
  FTotalLength: Int64;
  FTotalWorms: Integer;
  FTotalAge: Int64;
  FAverageThinkTime: Integer;
  FEnabled: Boolean;
  FEntity: TwwEntity;
  function GetAverageLength: Integer;
   procedure SetEnabled(const Value: Boolean);
 protected
  function CheckPoint(From: TPoint; Dir: TwwDirection; aEntity: TwwEntities =
      [weLive]): Boolean;
  function GetCaption: String; virtual; abstract;
  function GetEnglishCaption: String; virtual;
  function IsFree(const aPOint: TPoint; aEntity: TwwEntities = [weLive]): Boolean;
  function IsBusy(const aPOint: TPoint): Boolean;
  function IsMe(const aPoint: TPoint): Boolean;
  function Thinking: TwwDirection; virtual; abstract;
  property Thing: TwwThing
   read f_CurrentThing;
 public
  constructor Create(aEntity: TwwEntity = weLive);
  function Think(aFor: TwwThing): TwwDirection;
  function FindTarget(aThing: TwwThing): TwwThing; virtual;
  function IsLegal(aPoint: TPoint): Boolean;
  procedure ReadValues(DataFile: TIniFile);
  procedure WriteValues(DataFile: TIniFile);
  procedure PostMorten(aThing: TwwThing);
 public
  property AverageLength: Integer
   read GetAverageLength;
  property Caption: String
   read GetCaption;
  property Enabled: Boolean read FEnabled write SetEnabled;
  property EnglishCaption: String
   read GetEnglishCaption;

  property MaxThingLength: Integer read FMaxThingLength;
  property MaxThingAge: Integer read FMaxThingAge;
  property Weight: Integer
   read FWeight
   write FWeight;
  property TotalLength: Int64
   read FTotalLength;
  property TotalWorms: Integer
   read FTotalWorms;
  property TotalAge: Int64
   read FTotalAge;
  property AverageThinkTime: Integer read FAverageThinkTime;
  property Entity: TwwEntity read FEntity write FEntity;
 end;

 TwwMindClass = class Of TwwMind;
 TwwMindRec = record
   Entity: TwwEntity;
   MindClass: TwwMindClass;
 end;



 TwwMindCenter = class(TObjectList)
 private
  FDataFileName: String;
  FDataFile: TIniFile;
  function GetMinds(Index: Integer): TwwMind;
 public
  constructor Create(aDataFileName: String); reintroduce;
  destructor Destroy; override;
  function RandomMind(aEntity: TwwEntity = weLive): TwwMind;
  procedure AddMind(aMind: TwwMind);
  procedure RegisterMind(aMind: TwwMindClass; aEntity: TwwEntity);
  procedure Resort;
  property Minds[Index: Integer]: TwwMind
   read GetMinds;
 end;

implementation

Uses
 Math,
 WormsWorld, wwWorms, wwUtils;

{ TwwMind }

function TwwMind.GetEnglishCaption: String;
begin
 Result:= ClassName;
end;

function TwwMind.IsBusy(const aPOint: TPoint): Boolean;
begin
 Result:= f_CurrentThing.IsBusy(aPoint);
end;

function TwwMind.IsFree(const aPOint: TPoint; aEntity: TwwEntities = [weLive]):
    Boolean;
begin
 Result:= f_CurrentThing.IsFree(aPoint);
end;

function TwwMind.IsMe(const aPoint: TPoint): Boolean;
begin
 Result:= f_CurrentThing.IsMe(aPoint);
end;

function TwwMind.Think(aFor: TwwThing): TwwDirection;
begin
 FMaxThingLength:= Max(aFor.Length, MaxThingLength);
 FMaxThingAge:= Max(FMaxThingAge, aFor.Age);

 f_CurrentThing:= aFor;
 if (Thing <> nil){ and (Thing is TwwWorm)} then
 begin
  if (Thing is TwwWorm) and ((TwwWorm(Thing).Target = nil) or (TwwWorm(Thing).Target.IsDead)) then
   TwwWorm(Thing).Target:= FindTarget(Thing);
  Result:= Thinking;
 end
 else
  Result:= dtNone;
end;

constructor TwwMind.Create(aEntity: TwwEntity);
begin
  inherited Create;
  fEntity:= aEntity;
end;

function TwwMind.FindTarget(aThing: TwwThing): TwwThing;
begin
 Result := (aThing.World as TWormsField).NearestTarget(aThing.Head.Position);
end;

function TwwMind.IsLegal(aPoint: TPoint): Boolean;
begin
  Result := Thing.World.IsLegal(aPoint);
end;

procedure TwwMind.ReadValues(DataFile: TIniFile);
begin
 with DataFile do
 begin
  FMaxThingLength:= ReadInteger(Caption, 'MaxLen', 0);
  FMaxThingAge:= ReadInteger(Caption, 'MaxAge', 0);
  FWeight:= ReadInteger(Caption, 'Weight', 0);
  FTotalLength:= ReadInteger(Caption, 'TotalLen', 0);
  FTotalAge:= ReadInteger(Caption, 'TotalAge', 0);
  FTotalWorms:= ReadInteger(Caption, 'Worms', 0);
  FAverageThinkTime:= ReadInteger(Caption, 'ThinkTime', 0);
  FEnabled:= ReadBool(Caption, 'Enabled', True);
 end;
end;

procedure TwwMind.SetEnabled(const Value: Boolean);
begin
  FEnabled := Value;
end;

procedure TwwMind.WriteValues(DataFile: TIniFile);
begin
 with DataFile do
 begin
  WriteInteger(Caption, 'MaxLen', FMaxThingLength);
  WriteInteger(Caption, 'MaxAge', FMaxThingAge);
  WriteInteger(Caption, 'Weight', FWeight);
  WriteInteger(Caption, 'TotalLen', FTotalLength);
  WriteInteger(Caption, 'TotalAge', FTotalAge);
  WriteInteger(Caption, 'Worms', FTotalWorms);
  WriteInteger(Caption, 'ThinkTime', FAverageThinkTime);
  WriteBool(Caption, 'Enabled', FEnabled);
 end;
end;

function TwwMind.CheckPoint(From: TPoint; Dir: TwwDirection; aEntity:
    TwwEntities = [weLive]): Boolean;
begin
 Result:= IsFree(MovePoint(From, Dir), aEntity);
end;

procedure TwwMind.PostMorten(aThing: TwwThing);
begin
 Inc(FTotalAge, aThing.Age);
 Inc(FTotalLength, aThing.Length);
 Inc(FTotalWorms);
 if (aThing is TwwWorm) and (TwwWorm(aThing).TargetCount <> 0) then
  FAverageThinkTime:= Max(FAverageThinkTime, aThing.Age div TwwWorm(aThing).TargetCount)
 else
  FAverageThinkTime:= 0;
end;

function TwwMind.GetAverageLength: Integer;
begin
 if TotalWorms <> 0 then
  Result:= TotalLength div TotalWorms
 else
  Result:= 0;
end;

{ TwwMindCenter }

constructor TwwMindCenter.Create(aDataFileName: String);
begin
 inherited Create;
 FDataFileName:= aDataFileName;
 FDataFile:= TIniFile.Create(FDataFileName);
end;

destructor TwwMindCenter.Destroy;
var
 i: Integer;
begin
 for i:=0 to Pred(Count) do
  Minds[i].WriteValues(FDataFile);
 FDataFile.Free;
  inherited;
end;

function TwwMindCenter.GetMinds(Index: Integer): TwwMind;
begin
 Result:= TwwMind(Items[Index]);
end;

function TwwMindCenter.RandomMind(aEntity: TwwEntity = weLive): TwwMind;
var
 l_Total, l_Weight: Integer;
 i,j, l_index: Integer;
 l_Arr: array[0..99] of Integer;
begin
 if Count > 0 then
 begin
  l_Total:= 0;
  FillChar(l_arr, SizeOf(l_Arr), 0);
  for i:= 0 to Pred(Count) do
  begin
    if Minds[i].Enabled and (Minds[i].Entity = aEntity) then
    begin
     if Minds[i].AverageLength = 0 then
      Inc(l_Total, 50)
     else
      Inc(l_Total, Minds[i].AverageLength);
    end;
  end; // for i
  l_index:= 0;
  for i:= 0 to Pred(Count) do
  begin
   if Minds[i].Enabled and (Minds[i].Entity = aEntity) then
   begin
     if Minds[i].AverageLength = 0 then
      l_Weight:= Round(50*100 / l_Total)
     else
      l_Weight:= Round(Minds[i].AverageLength*100 / l_Total);
     for j:= l_index to Pred(Min(100, l_index+l_Weight)) do
      l_Arr[j]:= i;
     Inc(l_Index, l_Weight);
     Minds[i].Weight:= l_Weight;
   end; // Minds[i].Enabled
  end; // for i
  l_index:= RandomFrom(l_Arr);
  Result:= Minds[l_index];
 end
 else
  Result:= nil;
end;

procedure TwwMindCenter.AddMind(aMind: TwwMind);
begin
 Add(aMind);
 aMind.Enabled:= True;
 aMind.ReadValues(FDataFile);
end;

 function CompareLength(Item1, Item2: TObject): Integer;
 begin
  Result := CompareValue(TwwMind(Item1).MaxThingLength, TwwMind(Item2).MaxThingLength);
 end;

procedure TwwMindCenter.RegisterMind(aMind: TwwMindClass; aEntity: TwwEntity);
var
 l_Rec: TwwMindRec;
begin
  l_Rec.Entity:= aEntity;
  l_Rec.MindClass:= aMind;
end;

procedure TwwMindCenter.Resort;
begin
 Sort(@CompareLength);
end;

end.
