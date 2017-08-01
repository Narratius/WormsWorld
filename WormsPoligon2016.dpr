program WormsPoligon2016;

uses
  Vcl.Forms,
  PoligonForm in 'PoligonForm.pas' {PoligonMainForm},
  wwCrazyApple in 'wwCrazyApple.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TPoligonMainForm, PoligonMainForm);
  Application.Run;
end.
