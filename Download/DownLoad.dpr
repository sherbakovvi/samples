program DownLoad;

uses
  Forms,
  UDown in 'UDown.pas' {FDown};

{$R *.res}
{$R manifest.RES}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFDown, FDown);
  Application.Run;
end.
