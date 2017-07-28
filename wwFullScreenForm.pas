unit wwFullScreenForm;

{ Отрисовка червяков в полном экране }

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, WormsWorld,
  System.ImageList, Vcl.ImgList;

type
  TFSForm = class(TForm)
    WorldPaintBox: TPaintBox;
    Worms8ImageList: TImageList;
    Worms16ImageList: TImageList;
    procedure FormCreate(Sender: TObject);
    procedure WorldPaintBoxPaint(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure FormClick(Sender: TObject);
  private
    FWorld: TWormsField;
    f_Step: Integer;
    f_Images: TImageList;
  public
    { Public declarations }
    property World: TWormsField
      read FWorld write FWorld;
  end;

var
  FSForm: TFSForm;

implementation

{$R *.dfm}

Uses
 wwClasses, wwUtils, wwTypes;

var
 WormColors : array[0..4] of Cardinal;


procedure TFSForm.FormClick(Sender: TObject);
begin
  Close;
end;

procedure TFSForm.FormCreate(Sender: TObject);
begin
 DoubleBuffered:= True;
 WormColors[0]:= RGB(93,114,164);
 WormColors[1]:= RGB(172,163,98);
 WormColors[2]:= RGB(170,104,97);
 WormColors[3]:= RGB(143,97,170);
 WormColors[4]:= RGB(96,170,158);
 f_Step:= 8;
 f_Images:= Worms8ImageList;
end;

procedure TFSForm.FormKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #27 then
   Close;
end;

procedure TFSForm.WorldPaintBoxPaint(Sender: TObject);
var
 l_T: TwwThing;
 i, j: Integer;
 l_Rect: TRect;
 k, l_What: Integer;
 Y: Single;
 l_Draw: Boolean;
begin
  l_Rect:= WorldPaintBox.ClientRect;
  WorldPaintBox.Canvas.Brush.Color:= clDkGray;
  WorldPaintBox.Canvas.FillRect(l_Rect);

  if WorldPaintBox.ClientWidth div FWorld.Size.Width > 8 then
  begin
    f_Step:= 16;
    f_Images:= Worms16ImageList;
  end
  else
  begin
    f_Step:= 8;
    f_Images:= Worms8ImageList;
  end;

  j:= 0;
  for i:= 0 to Pred(FWorld.Count) do
  begin
   l_T:= FWorld.Things[i];

   if not l_T.IsDead then
   begin
    for k:= 0 to Pred(l_T.Length) do
    begin
     if (k > 0) then
      l_Draw:= not wwUtils.Equal(l_T.Points[k].Position, l_T.Points[Pred(k)].Position)
     else
      l_Draw:= True;
     if l_Draw then
     begin
      l_Rect.Left:= l_T.Points[k].Position.X*f_Step;
      l_Rect.Top:= l_T.Points[k].Position.Y*f_Step;
      if l_T.Entity = weLive then
        f_Images.Draw(WorldPaintBox.Canvas, l_Rect.Left, l_Rect.Top, 1+l_T.Variety*14+ l_T.Points[k].Value)
      else
        f_Images.Draw(WorldPaintBox.Canvas, l_Rect.Left, l_Rect.Top, l_T.Variety)
     end; // l_Draw
    end; // for k
   end; // not l_T.IsDead

   if l_T.Entity = weLive then
   begin
    WorldPaintBox.Canvas.Font.Color:= WormColors[l_T.Variety];
    WorldPaintBox.Canvas.Font.Style:= [fsBold];
    WorldPaintBox.Canvas.TextOut(i*(WorldPaintBox.ClientWidth div FWorld.WormsCount), WorldPaintBox.ClientHeight-16,
       Format('%s: %d за %d ходов', [l_T.Caption, l_T.Length, l_T.Age]));
   end;

  end; // for i
 end; // FCancelend;

end.
