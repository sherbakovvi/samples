unit USchema;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, pFIBMetaData, FIBDatabase, pFIBDatabase, StdCtrls, DB, FIBDataSet,
  pFIBDataSet, Grids, DBGrids, FIBQuery, pFIBQuery, RefreshDB;

type
  TFRefreshDB = class(TForm)
    SourceFDB: TEdit;
    Source: TButton;
    TargetFDB: TEdit;
    Target: TButton;
    OpenDialog: TOpenDialog;
    Script: TMemo;
    RefreshDB: TButton;
    Demo: TCheckBox;
    procedure SourceClick(Sender: TObject);
    procedure TargetClick(Sender: TObject);
    procedure RefreshDBClick(Sender: TObject);
    procedure SourceFDBChange(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;


var
  FRefreshDB: TFRefreshDB;

implementation

{$R *.dfm}

procedure TFRefreshDB.RefreshDBClick(Sender: TObject);
var OK : boolean;
begin
  RefreshDM.ExecuteScript := not Demo.Checked;
  OK := RefreshDM.RefreshDataBase(SourceFDB.Text, TargetFDB.Text);
  Script.Lines.Assign(RefreshDM.Scripter.Script);
  if not OK then
    ShowMessage('RefreshDataBase failed!');
end;

procedure TFRefreshDB.SourceClick(Sender: TObject);
begin
  if OpenDialog.Execute then
    SourceFDB.Text := OpenDialog.Filename;
end;

procedure TFRefreshDB.SourceFDBChange(Sender: TObject);
begin
  RefreshDB.Enabled := FileExists(SourceFDB.Text) and FileExists(TargetFDB.Text);
end;

procedure TFRefreshDB.TargetClick(Sender: TObject);
begin
  if OpenDialog.Execute then
    TargetFDB.Text := OpenDialog.Filename;
end;

end.
