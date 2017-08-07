unit PoligonForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, StdCtrls, WormsWorld, Grids, Vcl.ExtCtrls,
  System.ImageList, Vcl.ImgList, wwFullScreenForm;

type
  TPoligonMainForm = class(TForm)
    GroupBox1: TGroupBox;
    Label1: TLabel;
    MapSizeCombo: TComboBox;
    WormsCountCombo: TComboBox;
    TargetCountCombo: TComboBox;
    Label3: TLabel;
    Label2: TLabel;
    StartButton: TButton;
    StopButton: TButton;
    GroupBox2: TGroupBox;
    StatisticView: TListView;
    MapButton: TButton;
    MapGrid: TDrawGrid;
    CheckBox1: TCheckBox;
    Worms8ImageList: TImageList;
    procedure Button1Click(Sender: TObject);
    procedure StartButtonClick(Sender: TObject);
    procedure StopButtonClick(Sender: TObject);
    procedure MapButtonClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure MapGridDrawCell(Sender: TObject; ACol, ARow: Integer;
      Rect: TRect; State: TGridDrawState);
    procedure CheckBox1Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
   FWorld: TWormsField;
   FCAncel: Boolean;
   FMapVisible: Boolean;
   FShowIdeas: Boolean;
   f_FSForm: TFSForm;
   procedure NewIdea(Sender: TObject);
  public
    { Public declarations }
  end;

var
  PoligonMainForm: TPoligonMainForm;

implementation

{$R *.dfm}
Uses
 Types, wwClasses, wwTypes, wwUtils;

procedure TPoligonMainForm.Button1Click(Sender: TObject);
var
 l_From, l_To: TPoint;
 l_Dir: TwwDirection;
begin
  // Проверка CalcDir
  l_From:= Point(40, 0);
  l_To:= Point(45, 4);
  l_Dir:= CalcDir(l_From, l_To, ftVertical);
end;

procedure TPoligonMainForm.StartButtonClick(Sender: TObject);
var
 Bounds: TRect;
 i: Integer;
 Itm: TListItem;
begin
 Bounds.Left:= 0; Bounds.Top:= 0;
 case MapSizeCombo.ItemIndex of
  0:
   begin
    Bounds.Right:= 640 div 16;
    Bounds.Bottom:= 480 div 16;
   end;
  1:
   begin
    Bounds.Right:= 800 div 16;
    Bounds.Bottom:= 600 div 16;
   end;
  2:
   begin
    Bounds.Right:= 1024 div 16;
    Bounds.Bottom:= 768 div 16;
   end;
  3:
   begin
    Bounds.Right:= 1280 div 16;
    Bounds.Bottom:= 1024 div 16;
   end;
  4:
   begin
    Bounds.Right:= 1920 div 16;
    Bounds.Bottom:= 1080 div 16;
   end;
  5:
   begin
    Bounds.Right:= 3860 div 16;
    Bounds.Bottom:= 2160 div 16;
   end;
 end;
 with MapGrid do
 begin
  ColCount:= Bounds.Right+1;
  DefaultColWidth:= (Width - ColCount) div ColCount;
  RowCount:= Bounds.Bottom+1;
  DefaultRowHeight:= (Height - RowCount) div RowCount;
 end;

 StatisticView.Items.Clear;
 for i:= 0 to 4 do
 begin
  Itm:= StatisticView.Items.Add;
  Itm.Caption:= '';
  Itm.SubItems.Add('');
  Itm.SubItems.Add('');
  Itm.SubItems.Add('');
  Itm.SubItems.Add('');
 end; // for i
 FCancel:= False;
 StartButton.Enabled:= False;
 StopButton.Enabled:= True;
 MapButton.Enabled:= True;
 GroupBox1.Enabled:= False;
 FWorld:= TWormsField.Create(Bounds);
 try
  FWorld.MaxTargetCount:= Succ(TargetCountCombo.ItemIndex);
  FWorld.MaxWormsCount:= Succ(WormsCountCombo.ItemIndex);
  FWorld.InstantRessurectTargets:= True;
  FWorld.InstantRessurectWorms:= True;
  FWorld.OnNewIdea:= NewIdea;

  f_FSForm:= TFSForm.Create(Application);
  try
    f_FSForm.World:= fWorld;

    FCancel:= False; FShowIdeas:= False;
    repeat
     FWorld.Update;
     for i:= 0 to Pred(FWorld.WormsCount) do
     begin
      itm:= StatisticView.Items[i];
      itm.Caption:= FWorld.Worms[i].Mind.Caption;
      itm.SubItems.Strings[0]:= IntToStr(FWorld.Worms[i].Length);
      itm.SubItems.Strings[1]:= IntToStr(FWorld.Worms[i].Mind.MaxThingLength);
      itm.SubItems.Strings[2]:= IntToStr(FWorld.Worms[i].Mind.Weight)+'%';
      Itm.SubItems.Strings[3]:= IntToStr(FWorld.Worms[i].Age);
     end; // for i
     if FMapVisible then
     begin
      (* *)
      MapGrid.Invalidate;
      (* *)
      //WorldPaintBox.Invalidate;
      if f_FSForm.Visible then
       f_FSForm.Invalidate
      else
       FMapVisible:= False;
     end;
     Application.ProcessMessages;
     Sleep(25);
    until FCancel;
  finally
    FreeAndNil(f_FSForm);
  end;

  FWorld.MindCenter.Resort;
  StatisticView.Items.Clear;
  for i:= Pred(FWorld.MindCenter.Count) downto 0 do
  begin
   Itm:= StatisticView.Items.Add;
   Itm.Caption:= FWorld.MindCenter.Minds[i].Caption;
   Itm.SubItems.Add(IntToStr(FWorld.MindCenter.Minds[i].AverageLength));
   Itm.SubItems.Add(IntToStr(FWorld.MindCenter.Minds[i].MaxThingLength));
   Itm.SubItems.Add(IntToStr(FWorld.MindCenter.Minds[i].Weight)+'%');
   Itm.SubItems.Add('');
   Itm.SubItems.Add(BoolToStr(FWorld.MindCenter.Minds[i].Enabled, True));
  end; // for i
 finally
  FWorld.Free;
  MapButton.Enabled:= False;
  StopButton.Enabled:= False;
  StartButton.Enabled:= True;
  GroupBox1.Enabled:= True;
 end;
end;


procedure TPoligonMainForm.StopButtonClick(Sender: TObject);
begin
 FCancel:= True;
end;

procedure TPoligonMainForm.MapButtonClick(Sender: TObject);
var
 l_Form: TFSForm;
begin
 FMapVisible:= not FMapVisible;
 (*  *)
 if FMapVisible then
   f_FSForm.Show;
 (* *)
 (*
 if FMapVisible then
 begin
  ClientHeight:= MapGrid.Top + MapGrid.Height + 10;
  Width:=550;
 end
 else
 begin
  ClientHeight:= GroupBox2.Top+GroupBox2.Height+10;
  Width:=550;
 end;
 *)
end;

procedure TPoligonMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  StopButton.Click;
end;

procedure TPoligonMainForm.FormCreate(Sender: TObject);
begin
 DoubleBuffered:= True;
 Randomize;
 ClientHeight:= GroupBox2.Top+GroupBox2.Height+10;
 //Width:=550;
 FMapVisible:= False;
end;

const
 WormColor : array[0..4] of TColor = (clBlue, clGreen, clTeal, clPurple, clGray);
 TargetColor : array[-1..1] of TColor = (clLtGray, clRed, clMaroon);

procedure TPoligonMainForm.MapGridDrawCell(Sender: TObject; ACol, ARow: Integer;
  Rect: TRect; State: TGridDrawState);
var
 l_T: TwwThing;
begin
 if not FCancel and FMapVisible then
 begin
  MapGrid.Canvas.Brush.Color:= clWhite;
  l_T:= FWorld.ThingAt(Point(aCol, aRow));
  if l_T <> nil then
  begin
   if l_T.Entity = weLive then
    MapGrid.Canvas.Brush.Color:= WormColor[l_T.Variety]
   else
    MapGrid.Canvas.Brush.Color:= TargetColor[l_T.Variety];
  end; // l_T <> nil
  MapGrid.Canvas.FillRect(Rect);
 end; // FCancel
end;

procedure TPoligonMainForm.NewIdea(Sender: TObject);
begin
 if FMapVisible and FShowIdeas then
  MapGrid.Refresh;
 Application.ProcessMessages;
end;

procedure TPoligonMainForm.CheckBox1Click(Sender: TObject);
begin
 FShowIdeas:= CheckBox1.Checked;
end;

end.
