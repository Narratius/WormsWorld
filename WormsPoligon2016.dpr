program WormsPoligon2016;

uses
  Vcl.Forms,
  PoligonForm in 'PoligonForm.pas' {WormPoligonForm};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TWormPoligonForm, WormPoligonForm);
  Application.Run;
end.
