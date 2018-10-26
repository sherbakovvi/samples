program Viewer;

uses
  FMX.Forms,
  UFireScan in 'UFireScan.pas' {ScanFrm},
  UViewImg in 'UViewImg.pas' {ViewImg},
  Effect in 'Effect.pas' {frmEffect};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TScanFrm, ScanFrm);
  Application.CreateForm(TfrmEffect, frmEffect);
  Application.Run;
end.
