unit TFGame;

interface

uses
  GVDLL, SysUtils;

type
  TTFGame = class;
  TTFGameScene = class
  private
    FGame : TTFGame;
    function GetRez: Integer;
  protected
    property Rez: Integer read GetRez;
  public
    constructor Create(AOwner: TTFGame);
    procedure LoadResources; virtual; abstract;
    procedure FreeResources; virtual; abstract;
    destructor Destroy; override;
    procedure  Update(ElapsedTime: Single); virtual; abstract;
    procedure  Render; virtual; abstract;
    procedure  HandleEvent(Event: Integer; Data: Pointer); virtual;
    procedure  SendEventToGame(Event: Integer; Data: Pointer);
   property Game: TTFGame
    read FGame; 
  end;

  TTFSpriteEngine = class;
  TTFGameSprite = class
  private
    FEntity: Integer;
    FDetectCollisions: Boolean;
    procedure SetDetectCollisions(const Value: Boolean);
    procedure SetPos(const Value: TGVVector);
    function GetPos: TGVVector;
  protected
    property Entity: Integer read FEntity;
  public
    constructor Create(aSprite: Integer; spPage, spGroup: Cardinal; Mju: Extended=6; MSB: Integer=10; AT: Byte=70);
    destructor  Destroy; override;
    procedure  OnCollide(DumpedInto: TTFGameSprite; Point: TGVVector); virtual;
    procedure  Render; virtual;
    procedure  Update(ElapsedTime: Single); virtual;

    property DetectCollisions: Boolean read FDetectCollisions write SetDetectCollisions;
    property Pos: TGVVector read GetPos write SetPos;

  end;

  TTFSpriteEngine = class
  private
    FSprites: array of TTFGameSprite;
    FCount : Integer;
    function GetSprite(Index: Integer): TTFGameSprite;
  public
    property Sprites[Index: Integer]: TTFGameSprite read GetSprite;
  end;

  TTFPlayer = class
  private
    FScene: TTFGameScene;
  public
  	property Scene: TTFGameScene read FScene;
    constructor Create(aOwner: TTFGameScene);
    procedure Update(ElapsedTime: Single); virtual; abstract; // updates player actions at screen
  end;

{ === TTFGame =========================================================== }
  { TTFGameScreen }
  TTFGameScreen = record
    Caption : string;
    Width   : Cardinal;
    Height  : Cardinal;
    Bpp     : Cardinal;
    Windowed: Boolean;
  end;
  PGVGameScreen = ^TTFGameScreen;

  { TTFGameViewport }
  TTFGameViewport = record
    X     : Cardinal;
    Y     : Cardinal;
    Width : Cardinal;
    Height: Cardinal;
  end;
  PGVGameViewport = ^TTFGameViewport;

  { TTFGameAudio }
  TTFGameAudio = record
    MusicVol : Single;
    SfxVol   : Single;
    MusicPath: string;
  end;
  PGVGameAudio = ^TTFGameAudio;

  { јналог TApplication - инициализанци€, основной цикл работы
    приложени€, использующего Game Vision SDK. ¬ наследнике
    необходимо перекрыть методы LoadConfig, SaveConfig         }
  TTFGame = class
  private
    FScenes        : array of TTFGameScene;
    FElapsedTime   : Single;
    FFrameRate     : Cardinal;
    FScreen        : TTFGameScreen;
    FViewport      : TTFGameViewport;
    FAudio         : TTFGameAudio;
    FSceneCount    : Integer;
    FCurrentScene  : Integer;
    FRezFileName   : string;
    FRez           : Integer;

    function GetScreen  : PGVGameScreen;
    function GetViewport: PGVGameViewport;
    function GetAudio   : PGVGameAudio;
    function GetScene(Index: Integer): TTFGameScene;
    function GetCurrentScene: Integer;
    procedure SetCurrentScene(const Value: Integer);
    function GetCaption: String;
    function GetColorDeep: Integer;
    function GetHeight: Integer;
    function GetWidth: Integer;
    function GetWindowed: Boolean;
    procedure SetCaption(const Value: String);
    procedure SetColorDeep(const Value: Integer);
    procedure SetHeight(const Value: Integer);
    procedure SetWidth(const Value: Integer);
    procedure SetWindowed(const Value: Boolean);

  public
    property Scenes[Index:Integer]: TTFGameScene read GetScene;
    property CurrentScene: Integer read GetCurrentScene write SetCurrentScene;
    property ElapsedTime: Single          read FElapsedTime;
    property FrameRate  : Cardinal        read FFrameRate;
    property Screen     : PGVGameScreen   read GetScreen;
    property Viewport   : PGVGameViewport read GetViewport;
    property Audio      : PGVGameAudio    read GetAudio;
    property Rez        : Integer read FRez;
  public
    constructor Create(aRezFile: string);
    destructor  Destroy; override;
    function  AddScene(AScene: TTFGameScene): Integer;
    procedure LoadConfig; virtual;
    procedure SaveConfig; virtual;
    procedure SystemsInit; virtual;
    procedure SystemsDone; virtual;
    procedure PreRender; virtual;
    procedure PostRender; virtual;
    procedure Run;
    procedure  HandleEvent(Event: Integer; Data: Pointer); virtual;
    { --- Audio Routines ------------------------------------------------ }
    procedure AdjustSfxVol(aDelta: Single);
    procedure AdjustMusicVol(aDelta: Single);
  public
   property Caption: String
    read GetCaption
    write SetCaption;
   property Width: Integer
    read GetWidth
    write SetWidth;
   property Height: Integer
    read GetHeight
    write SetHeight;
   property ColorDeep: Integer
    read GetColorDeep
    write SetColorDeep;
   property Windowed: Boolean
    read GetWindowed
    write SetWindowed;
  end;

  
implementation

{ === TTFGame =========================================================== }
function TTFGame.GetScreen: PGVGameScreen;
begin
  Result := @FScreen;
end;

function TTFGame.GetViewport: PGVGameViewport;
begin
  Result := @FViewport;
end;

function TTFGame.GetAudio: PGVGameAudio;
begin
  Result := @FAudio;
end;

constructor TTFGame.Create(aRezFile: string);
begin
  inherited Create;
  FScenes := nil;
  FElapsedTime := 0;
  FFrameRate   := 0;
  FillChar(FScreen, SizeOf(FScreen), 0);
  FillChar(FViewport, SizeOf(FViewport), 0);
  FillChar(FAudio, SizeOf(FAudio), 0);
  FRezFileName := aRezFile;
  LoadConfig;
  SystemsInit;
end;

destructor TTFGame.Destroy;
begin
  SystemsDone;
  SaveConfig;
  inherited Destroy;
end;


procedure TTFGame.LoadConfig;
begin
end;

procedure TTFGame.SaveConfig;
begin
end;

procedure TTFGame.PreRender;
begin
end;

procedure TTFGame.PostRender;
begin
end;

procedure TTFGame.Run;
var
  SC : TTFGameScene;
begin
  if FSceneCount = 0 then Exit;
  FCurrentScene := 0;
  // enter game loop
  repeat
    // let windows do its thing;
    GV_App_ProcessMessages;

    // if the render / appwindow contex is not ready just let windows
    // process messages
    if not GV_RenderDevice_IsReady then continue;

    SC := FScenes[FCurrentScene];
    // start rendering
    if GV_RenderDevice_StartFrame then
    begin
    	// pre render
      PreRender;
      SC.Render;
      // post render
      PostRender;
      // stop rendering
      GV_RenderDevice_EndFrame;
    end;

    // show frame buffer
    GV_RenderDevice_ShowFrame;

    // update input
    GV_Input_Update;

    // update timing
    GV_Timer_Update;
    FElapsedTime := GV_Timer_ElapsedTime;
    FFrameRate   := GV_Timer_FrameRate;

    SC.Update(FElapsedTime);
    // loop until app is terminated
  until GV_App_IsTerminated;
end;


procedure TTFGame.AdjustMusicVol(aDelta: Single);
begin
  with Audio^ do
  begin
    MusicVol := MusicVol + aDelta;
    GV_ClampValueSingle(MusicVol, 0.0, 1.0);
    GV_MusicPlayer_SetSongVol(MusicVol);
  end;
end;

procedure TTFGame.AdjustSfxVol(aDelta: Single);
begin
  with Audio^ do
  begin
    SfxVol := SfxVol + aDelta;
    GV_ClampValueSingle(SfxVol, 0.0, 1.0);
    GV_Audio_SetMasterSfxVol(SfxVol);
  end;
end;

{ TTFGameScene }

constructor TTFGameScene.Create(AOwner: TTFGame);
begin
  inherited Create;
  FGame := AOwner;
  LoadResources;
end;

function TTFGame.GetScene(Index: Integer): TTFGameScene;
begin
  Result := FScenes[Index];
end;

destructor TTFGameScene.Destroy;
begin
  FreeResources;
  inherited;
end;

function TTFGame.AddScene(AScene: TTFGameScene): Integer;
begin
  Inc(FSceneCount);
  if FSceneCount > Length(FScenes) then
    SetLength(FScenes, Length(FScenes)+10);
  FScenes[FSceneCount-1] := AScene;
  Result := FSceneCount - 1;
end;

function TTFGame.GetCurrentScene: Integer;
begin
  Result := FCurrentScene;
end;

procedure TTFGame.SetCurrentScene(const Value: Integer);
begin
  FCurrentScene := Value;
end;

procedure TTFGame.SystemsDone;
begin
  if FRez <> -1 then GV_RezFile_CloseArchive(FRez);
  GV_Input_Close;
  // shutdown graphics
  GV_RenderDevice_RestoreMode;
  // shutdown app window
  GV_AppWindow_Close;
  // dispose resources
  GV_Entity_Done;
  GV_Polygon_Done;
  GV_Image_Done;
  GV_Font_Done;
  GV_Sprite_Done;
  GV_Texture_Done;
  GV_RezFile_Done;
  GV_Done;
end;

procedure TTFGame.SystemsInit;
begin
  {$IFDEF DEBUG}
  GV_Init;
  {$ELSE}
  GV_Init(GV_LogFile_Priority_Critical);
  {$ENDIF}
  // alloc resources
  GV_RezFile_Init(256);
  GV_Texture_Init(256);
  GV_Font_Init(256);
  GV_Sprite_Init(256);
  GV_Image_Init(256);
  GV_Polygon_Init(256);
  GV_Entity_Init(256);
  if FRezFileName <> '' then FRez := GV_RezFile_OpenArchive(FRezFileName) else FRez := -1;
  GV_AppWindow_Open(FScreen.Caption, FScreen.Width, FScreen.Height);
  GV_AppWindow_Show;
  GV_RenderDevice_SetMode(GV_AppWindow_GetHandle, FScreen.Width, FScreen.Height, FScreen.Bpp, FScreen.Windowed, GV_SwapEffect_Discard);
  // init input
  GV_Input_Open(GV_AppWindow_GetHandle, FScreen.Windowed);
end;

function TTFGameScene.GetRez: Integer;
begin
	Result := FGame.FRez;
end;

procedure TTFGameScene.HandleEvent(Event: Integer; Data: Pointer);
begin
  // process your scene messages here
end;

procedure TTFGame.HandleEvent(Event: Integer; Data: Pointer);
begin
  // process your game events here
end;

procedure TTFGameScene.SendEventToGame(Event: Integer; Data: Pointer);
begin
  FGame.HandleEvent(Event, Data);
end;

{ TTFPlayer }

constructor TTFPlayer.Create(aOwner: TTFGameScene);
begin
  inherited Create;
  FScene := aOwner;
end;

{ TTFGameSprite }

constructor TTFGameSprite.Create(aSprite: Integer; spPage, spGroup: Cardinal; Mju: Extended; MSB: Integer; AT: Byte);
begin
  FEntity := GV_Entity_Create(aSprite, spPage, spGroup);
  GV_Entity_SetRenderState(FEntity, GV_RenderState_Image);
  GV_Entity_PolyPointTrace(FEntity, Mju, MSB, AT);
end;

destructor TTFGameSprite.Destroy;
begin
  GV_Entity_Dispose(FEntity);
  inherited;
end;

function TTFGameSprite.GetPos: TGVVector;
begin
  GV_Entity_GetPos(FEntity, @Result.X, @Result.Y);
end;

procedure TTFGameSprite.OnCollide(DumpedInto: TTFGameSprite;
  Point: TGVVector);
begin

end;

procedure TTFGameSprite.Render;
begin
  GV_Entity_Render(FEntity);
end;

procedure TTFGameSprite.SetDetectCollisions(const Value: Boolean);
begin
  FDetectCollisions := Value;
end;

procedure TTFGameSprite.SetPos(const Value: TGVVector);
begin
  GV_Entity_SetPos(FEntity, Value.X, Value.Y);
end;

procedure TTFGameSprite.Update(ElapsedTime: Single);
begin

end;

{ TTFSpriteEngine }

function TTFSpriteEngine.GetSprite(Index: Integer): TTFGameSprite;
begin
  Result := FSprites[Index];
end;

function TTFGame.GetCaption: String;
begin
 Result:= Screen^.Caption;
end;

function TTFGame.GetColorDeep: Integer;
begin
 Result:= Screen^.BPP;
end;

function TTFGame.GetHeight: Integer;
begin
 Result:= Screen^.Height;
end;

function TTFGame.GetWidth: Integer;
begin
 Result:= Screen^.Width;
end;

function TTFGame.GetWindowed: Boolean;
begin
 Result:= Screen^.Windowed;
end;

procedure TTFGame.SetCaption(const Value: String);
begin
 if Screen^.Caption <> Value then
 Screen^.Caption:= Value;
end;

procedure TTFGame.SetColorDeep(const Value: Integer);
begin
 if Screen^.BPP <> Value then
 Screen^.BPP:= Value;
end;

procedure TTFGame.SetHeight(const Value: Integer);
begin
 if Screen^.Height <> Value then
 Screen^.Height:= Value;
end;

procedure TTFGame.SetWidth(const Value: Integer);
begin
 if Screen^.Width <> Value then
 Screen^.Width:= Value;
end;

procedure TTFGame.SetWindowed(const Value: Boolean);
begin
 if Screen^.Windowed <> Value then
 Screen^.Windowed:= Value;
end;

end.
