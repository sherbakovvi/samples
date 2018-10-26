program AusLogicsTest;

uses
  Forms,
  ScanFiles in 'ScanFiles.pas' {FTest};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TFTest, FTest);
  Application.Run;
end.
