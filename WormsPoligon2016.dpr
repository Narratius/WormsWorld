program WormsPoligon2016;

uses
  Vcl.Forms,
  PoligonForm in 'PoligonForm.pas' {WormPoligonForm},
  wwFullScreenForm in 'wwFullScreenForm.pas' {FSForm};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TWormPoligonForm, WormPoligonForm);
  Application.CreateForm(TFSForm, FSForm);
  Application.Run;
end.
