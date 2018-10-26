program Schema;

uses
  Forms,
  USchema in 'USchema.pas' {FRefreshDB},
  RefreshDB in 'RefreshDB.pas' {RefreshDM: TDataModule};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFRefreshDB, FRefreshDB);
  Application.CreateForm(TRefreshDM, RefreshDM);
  Application.Run;
end.
