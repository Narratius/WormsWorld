unit wwGVAdapter;

interface

uses
  SysUtils, Windows, Messages, Classes, VCL.Graphics, VCL.Controls,
  VCL.Forms, VCL.Dialogs, TFGame, WormsWorld, wwTypes, wwClasses;

type
  TSmartWormGame = class (TTFGame)
  private
   f_WormCount: Integer;
   f_Ressurect: Boolean;
   f_TargetCount: Integer;
   f_InstantTarget: Boolean;
  public
    constructor Create(aRezFile: string);
    destructor Destroy; override;
    procedure LoadConfig; override;
    procedure SaveConfig; override;
  end;

  TSmartWormGameScene = class (TTFGameScene)
  private
   FWormsField: TWormsField;
   FWormImages: array[ws_NoBody..ws_Target, 0..4] of Cardinal;
   Spr   : Integer;
   FPage, WPage, WGroup: Cardinal;
   Font : Integer;
   FDelay: Integer;
    function GetMaxWormsCount: Integer;
    procedure SetMaxWormsCount(Value: Integer);
    function GetMaxTargetCount: Integer;
    procedure SetMaxTargetCount(Value: Integer);
    function GetRessurectWorms: Boolean;
    procedure SetRessurectWorms(Value: Boolean);
    function GetRessurectTargets: Boolean;
    procedure SetRessurectTargets(Value: Boolean);
  public
    constructor Create(AOwner: TTFGame; aSize: TRect); reintroduce;
    destructor Destroy; override;
    procedure FreeResources; override;
    procedure LoadResources; override;
    procedure Render; override;
    procedure Update(ElapsedTime: Single); override;
    procedure DrawThing(aThing: TwwThing);
    property MaxWormsCount: Integer read GetMaxWormsCount write SetMaxWormsCount;
    property MaxTargetCount: Integer read GetMaxTargetCount write SetMaxTargetCount;
    property RessurectWorms: Boolean read GetRessurectWorms write SetRessurectWorms;
    property RessurectTargets: Boolean read GetRessurectTargets write
        SetRessurectTargets;
  end;



implementation

Uses
 IniFiles, Math,
 wwWorms, wwUtils,
 GVDLL;

var
 WormColors : array[0..4] of Cardinal;

{
******************************** TSmartWormGame ********************************
}
constructor TSmartWormGame.Create(aRezFile: string);
var
  l_Size: TRect;
  i: Integer;
begin
  inherited Create(aRezFile);
  l_Size.Left:= 0;
  l_Size.Top:= 0;
  l_Size.Right:= (Width div 16);
  l_Size.Bottom:= (Height div 16);
  AddScene(TSmartWormGameScene.Create(Self, l_Size));
  with TSmartWormGameScene(Scenes[0]) do
  begin
   MaxWormsCount:= f_WormCount;
   MaxTargetCount:= f_TargetCount;
   RessurectWorms:= f_Ressurect;
   RessurectTargets:= f_InstantTarget;
  end;
 WormColors[0]:= GV_Color_Make(93,114,164, 255);
 WormColors[1]:= GV_Color_Make(172,163,98, 255);
 WormColors[2]:= GV_Color_Make(170,104,97, 255);
 WormColors[3]:= GV_Color_Make(143,97,170, 255);
 WormColors[4]:= GV_Color_Make(96,170,158, 255);
end;

destructor TSmartWormGame.Destroy;
begin
 Scenes[0].Free;
 inherited Destroy;
end;

procedure TSmartWormGame.LoadConfig;
begin
  inherited LoadConfig;
 Caption:= 'Smart Worms';
 with TIniFile.Create(ChangeFileExt(ParamStr(0), '.ini')) do
 try
  Width:= ReadInteger('Preferences', 'Width', 1024);
  Height:= ReadInteger('Preferences', 'Height', 768);
  ColorDeep:= ReadInteger('Preferences', 'ColorDeep', 16);
  Windowed:= ReadBool('Preferences', 'Window', False);
  f_WormCount:= Min(Abs(ReadInteger('Preferences', 'WormCount', 3)), 5);
  f_Ressurect:= ReadBool('Preferences', 'Ressurect', True);
  f_TargetCount:= ReadInteger('Preferences', 'TargetCount', 5);
  f_InstantTarget:= ReadBool('Preferences', 'InstantTarget', False);
 finally
  Free;
 end;

end;

procedure TSmartWormGame.SaveConfig;
begin
  inherited SaveConfig;
 with TIniFile.Create(ChangeFileExt(ParamStr(0), '.ini')) do
 try
  WriteInteger('Preferences', 'Width', Width);
  WriteInteger('Preferences', 'Height', Height);
  WriteInteger('Preferences', 'ColorDeep', ColorDeep);
  WriteBool('Preferences', 'Window', Windowed);
  WriteInteger('Preferences', 'WormCount', f_WormCount);
  WriteBool('Preferences', 'Ressurect', f_Ressurect);
  WriteInteger('Preferences', 'TargetCount', f_TargetCount);
  WriteBool('Preferences', 'InstantTarget', f_InstantTarget);
 finally
  Free;
 end;
end;

{
***************************** TSmartWormGameScene ******************************
}
constructor TSmartWormGameScene.Create(AOwner: TTFGame; aSize: TRect);
begin
  inherited Create(AOwner);
  FWormsField:= TWormsField.Create(aSize);
end;

destructor TSmartWormGameScene.Destroy;
begin
  inherited Destroy;
  FreeAndNil(FWormsField);
end;

procedure TSmartWormGameScene.FreeResources;
begin
  GV_Sprite_Dispose(Spr);
  GV_Font_Dispose(Font);
end;

procedure TSmartWormGameScene.LoadResources;
var
  i: Integer;
begin
  Spr := GV_Sprite_Create;
  WPage := GV_Sprite_LoadPage(Spr, Rez, 0, 'data/images/worm16.png');
  WGroup := GV_Sprite_AddGroup(Spr);
  for i:= 0 to 4 do
  begin
    // head load
    fWormImages[ws_HeadU, i] := GV_Sprite_AddImageGrid(Spr, WPage, WGroup, 3, 0+(2*i), 16, 16);
    fWormImages[ws_HeadD, i] := GV_Sprite_AddImageGrid(Spr, WPage, WGroup, 0, 1+(2*i), 16, 16);
    fWormImages[ws_HeadR, i] := GV_Sprite_AddImageGrid(Spr, WPage, WGroup, 4, 0+(2*i), 16, 16);
    fWormImages[ws_HeadL, i] := GV_Sprite_AddImageGrid(Spr, WPage, WGroup, 5, 1+(2*i), 16, 16);
    // tail load
    fWormImages[ws_TailU, i] := GV_Sprite_AddImageGrid(Spr, WPage, WGroup, 1, 1+(2*i), 16, 16);
    fWormImages[ws_TailD, i] := GV_Sprite_AddImageGrid(Spr, WPage, WGroup, 2, 0+(2*i), 16, 16);
    fWormImages[ws_TailR, i] := GV_Sprite_AddImageGrid(Spr, WPage, WGroup, 5, 0+(2*i), 16, 16);
    fWormImages[ws_TailL, i] := GV_Sprite_AddImageGrid(Spr, WPage, WGroup, 4, 1+(2*i), 16, 16);
    // junctions load
    {junLeftDown}fWormImages[ws_RotD, i] := GV_Sprite_AddImageGrid(Spr, WPage, WGroup, 1, 0+(2*i), 16, 16);
    {junRightDown}fWormImages[ws_RotL, i] := GV_Sprite_AddImageGrid(Spr, WPage, WGroup, 0, 0+(2*i), 16, 16);
    {junLeftUp}fWormImages[ws_RotUL, i] := GV_Sprite_AddImageGrid(Spr, WPage, WGroup, 3, 1+(2*i), 16, 16);
    {junRightUp}fWormImages[ws_RotUR, i] := GV_Sprite_AddImageGrid(Spr, WPage, WGroup, 2, 1+(2*i), 16, 16);
    // body load
    fWormImages[ws_BodyH, i] := GV_Sprite_AddImageGrid(Spr, WPage, WGroup, 6, 0+(2*i), 16, 16);
    fWormImages[ws_BodyV, i] := GV_Sprite_AddImageGrid(Spr, WPage, WGroup, 6, 1+(2*i), 16, 16);
  end; // for i
  fWormImages[ws_Target, 0] := GV_Sprite_AddImageGrid(Spr, FPage, {FGroup}WGroup, 7,0,16,16);
  fWormImages[ws_Target, 1] := GV_Sprite_AddImageGrid(Spr, FPage, {FGroup}WGroup, 7,1,16,16);
  Font := GV_Font_Load(Rez, 'data/font/font0');
end;

procedure TSmartWormGameScene.Render;
var
 i, j: Integer;
 Y: Single;
begin
 inherited;
 GV_RenderDevice_ClearFrame(GV_ClearFrame_Default, GV_DkGray);
 j:= 0;
 for i:= 0 to Pred(FWormsField.Count) do
 begin
  DrawThing(FWormsField.Things[i]);
  if FWormsField.Things[i] is TwwWorm then
  begin
   Y:= Game.Height-16;
   with FWormsField.Things[i] as TwwWorm do
    GV_Font_Print(Font,  i*(Game.Width div FWormsField.WormsCount), Y, WormColors[i],
      '%s: %d (Max:%d) for %d', [Caption, Length, Mind.MaxThingLength, Age]);
   Inc(j);
  end;
 end; 
end;

procedure TSmartWormGameScene.Update(ElapsedTime: Single);
var
 i: Integer;
 l_Delay: Integer;
begin
 inherited;
 if GV_Input_KeyHit(GV_KEY_ESCAPE) then
  GV_App_Terminate
 else
 begin
  if Game.FrameRate > 0 then
  begin
   l_Delay:= Round(Game.FrameRate / 25);
   if l_Delay > 1 then
   begin
    if fDelay < l_Delay then
    begin
     Inc(fDelay);
     exit
    end
    else
     FDelay:= 0;
   end
   else
   if l_Delay = 0 then
    exit;
   { Логика игры }
   FWormsField.Update;
  end;
 end;
end;

function TSmartWormGameScene.GetMaxWormsCount: Integer;
begin
  Result := FWormsField.MaxWormsCount;
end;

procedure TSmartWormGameScene.SetMaxWormsCount(Value: Integer);
begin
 FWormsField.MaxWormsCount:= Value;
end;

function TSmartWormGameScene.GetMaxTargetCount: Integer;
begin
 Result := FWormsField.MaxTargetCount;
end;

procedure TSmartWormGameScene.SetMaxTargetCount(Value: Integer);
begin
 FWormsField.MaxTargetCount:= Value;
end;

procedure TSmartWormGameScene.DrawThing(aThing: TwwThing);
var
 i, l_What: Integer;
 Y: Single;
 l_Draw: Boolean;
begin
 if not aThing.IsDead then
 begin
  for i:= 0 to Pred(aThing.Length) do
  begin
   if (i > 0) then
    l_Draw:= not Equal(aThing.Points[i].Position, aThing.Points[Pred(i)].Position)
   else
    l_Draw:= True;
   if l_Draw then
   begin
    GV_Sprite_RenderImage(Spr, fWormImages[aThing.Points[i].Value, aThing.Variety], WGroup,
                         aThing.Points[i].Position.X*16,
                         aThing.Points[i].Position.Y*16,
                         1, 0, GV_White, nil, GV_RenderState_Image);
   end;
  end;                       
 end;
end;

function TSmartWormGameScene.GetRessurectWorms: Boolean;
begin
  Result := FWormsField.InstantRessurectWorms;
end;

procedure TSmartWormGameScene.SetRessurectWorms(Value: Boolean);
begin
  FWormsField.InstantRessurectWorms:= Value;
end;

function TSmartWormGameScene.GetRessurectTargets: Boolean;
begin
  Result := FWormsField.InstantRessurectTargets;
end;

procedure TSmartWormGameScene.SetRessurectTargets(Value: Boolean);
begin
 FWormsField.InstantRessurectTargets:= Value;
end;


end.
