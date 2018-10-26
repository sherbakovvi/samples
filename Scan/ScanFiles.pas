unit ScanFiles;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls, ImgList, ShlObj, ShellConsts, ShellAPI, Math,
  jpeg, ExtCtrls, IniFiles;

const
  WM_NEXT_FILE = WM_USER + 1;

type
  TFTest = class(TForm)
    pbProgress: TProgressBar;
    lblFile_Dir: TLabel;
    btnPause: TButton;
    btnResume: TButton;
    btnStop: TButton;
    lvDups: TListView;
    btnScan: TButton;
    btnExit: TButton;
    ilSys: TImageList;
    bvl1: TBevel;
    img1: TImage;
    procedure btnExitClick(Sender: TObject);
    procedure btnScanClick(Sender: TObject);
    procedure btnPauseClick(Sender: TObject);
    procedure btnResumeClick(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormShow(Sender: TObject);
    procedure lvDupsCustomDrawItem(Sender: TCustomListView;
      Item: TListItem; State: TCustomDrawState; var DefaultDraw: Boolean);
    procedure FormDestroy(Sender: TObject);
  private
    UsedDiskBytes, ScanBytes  : Int64;
    ScanFinished : Boolean;
    FileList : TStringList;
    procedure WMNEXTFILE(var Message: TMessage); message WM_NEXT_FILE;
  public
  end;

  PSendInfo = ^TSendInfo;
  TSendInfo = record
    FileName : array[0..259] of Char;
    FilePath : array[0..MAX_PATH] of Char;
    ScanBytes  : Int64;
  end;

  PFileInfo = ^TFileInfo;
  TFileInfo = record
    FileName : array[0..259] of Char;
    FilePath : array[0..MAX_PATH] of Char;
    Time: Integer;
    Size: Integer;
  end;

  TScanThread = class(TThread)
    Disk: Char;
    FileList : TStringList;
    MsgHandle: THandle;
    procedure Execute; override;
    constructor Create(aDisk : Char; aMsgHandle : THandle);
    destructor Destroy; override;
  end;

var
  FTest: TFTest;

implementation

{$R *.dfm}

var
  ScanThread : TScanThread = nil;

function GetShellImage(const FileName : string): Integer;
var
  FileInfo: TSHFileInfo;
  Flags   : Integer;
begin
  Flags := SHGFI_SYSICONINDEX or SHGFI_SMALLICON;
  SHGetFileInfo(PChar(FileName), 0, FileInfo, SizeOf(FileInfo), Flags);
  Result := FileInfo.iIcon;
end;

procedure TFTest.btnExitClick(Sender: TObject);
begin
  Close;
end;

procedure TFTest.btnScanClick(Sender: TObject);
const
  DriveChar = 'c';
  DriveNo   = Ord(DriveChar) - ord('a') + 1;
begin
  ScanBytes := 0;
  UsedDiskBytes := DiskSize(DriveNo) - DiskFree(DriveNo);
  FreeAndNil(ScanThread);
  ScanThread := TScanThread.Create('C', Handle);
  ScanFinished := False;
  btnStop.Enabled := True;
  btnPause.Enabled := True;
end;

procedure TFTest.btnPauseClick(Sender: TObject);
begin
  ScanThread.Suspend;
  btnResume.Enabled := True;
  btnStop.Enabled := False;
  btnPause.Enabled := False;
end;

procedure TFTest.btnResumeClick(Sender: TObject);
begin
  ScanThread.Resume;
end;

procedure TFTest.btnStopClick(Sender: TObject);
begin
  if MessageDlg('Are you sure ?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    ScanThread.Terminate;
  end;
end;

{ TScanThread }

constructor TScanThread.Create(aDisk: Char; aMsgHandle: THandle);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  Disk := aDisk;
  MsgHandle := aMsgHandle;
  FileList := TStringList.Create;
  FileList.CaseSensitive := False;
  FileList.Duplicates    := dupAccept;
  FileList.Capacity := 100000;
//  Priority  := tpHigher;
  Resume;
end;

destructor TScanThread.Destroy;
var I : Integer;
begin
  for I := 0 to FileList.Count - 1 do
    Dispose(PFileInfo(FileList.Objects[ I ]));
  FileList.Free;
  inherited;
end;

procedure TScanThread.Execute;
var ScanBytes : Int64;
    Ticks : DWORD;

  procedure ScanDir(Dir : string);
  var F : TSearchRec;
      Info : PFileInfo;
      Send : PSendInfo;
      NowTicks : DWORD;
  begin
    if Terminated then
      Exit;
    if FindFirst(Dir + '\*.*', faAnyFile, F) = 0 then
    begin
      repeat
        if F.Attr and faDirectory <> 0 then
        begin
          if F.Name[ 1 ] <> '.' then
            ScanDir(Dir + '\' + F.Name);
        end else
        begin
           if Terminated then
             Exit;
          New(Info);
          StrPCopy(Info.FileName, F.Name);
          StrPCopy(Info.FilePath, Dir);
          Info.Time := F.Time;
          Info.Size := F.Size;
          Inc(ScanBytes, F.Size);
          FileList.AddObject(LowerCase(F.Name), Pointer(Info));
          NowTicks := GetTickCount;
          if NowTicks - Ticks > 200 then
          begin
            New(Send);
            StrPCopy(Send.FileName, F.Name);
            StrPCopy(Send.FilePath, Dir);
            Send.ScanBytes := ScanBytes;
            PostMessage(MsgHandle, WM_NEXT_FILE, WParam(Send), 0);
            Ticks := NowTicks;
            ScanBytes := 0;
          end;
        end;
      until FindNext(F) <> 0;
      FindClose(F);
    end;
  end;

begin
  ScanBytes := 0;
  Ticks := GetTickCount;
  ScanDir(Disk + ':');
  PostMessage(MsgHandle, WM_NEXT_FILE, 0, 0);
end;

procedure TFTest.WMNEXTFILE(var Message: TMessage);
var  I, DupCount, GrpCount : Integer;
     Info, FirstInfo : PFileInfo;
     SameFile, First : Boolean;
     curFileName, curFilePath : string;
     curFileTime, curFileSize : Integer;

    procedure AddLine(Info : PFileInfo);
    var SizeKB : Integer;
    begin
      with lvDups.Items.Add, Info^ do
      begin
        Caption := FileName;
        ImageIndex := GetShellImage(string(FilePath) + '\' + string(FileName));;
        SubItems.Add(FilePath);
        SizeKB := (Size + 1023 ) div 1024;
        if SizeKB = 0 then
         SizeKB := 1;
        SubItems.Add(Format('%dKB', [SizeKB]));
        Data := Pointer(GrpCount);
      end;
    end;

begin
  if Message.WParam = 0 then
  begin
    ScanFinished := True;
    if ScanThread.Terminated then
      Exit;
    FileList := ScanThread.FileList;
    DupCount := 0;
    GrpCount := 0;
    pbProgress.Position := 0;
    lblFile_Dir.Caption := 'Wait please, duplicates list is preparing';
    Update;
    FileList.BeginUpdate;
    lvDups.Items.BeginUpdate;
    try
      FileList.Sort;
      I := 0;
      while I < FileList.Count do
      begin
        FirstInfo := PFileInfo(FileList.Objects[ I ]);
        curFileName := FirstInfo.FileName;
        curFilePath := FirstInfo.FilePath;
        curFileTime := FirstInfo.Time;
        curFileSize := FirstInfo.Size;
        pbProgress.Position := (I * 100) div FileList.Count;
        First := True;
        Inc(I);
        while (I < FileList.Count) do
        begin
          Info := PFileInfo(FileList.Objects[ I ]);
          SameFile := SameText(curFileName, Info.FileName) and (curFileTime = Info.Time)
             and (curFileSize = Info.Size);
          if SameFile then
          begin
            if First then
            begin
              Inc(GrpCount);
              Inc(DupCount);
              First := False;
              AddLine(FirstInfo);
            end;
            Inc(DupCount);
            AddLine(Info);
            Inc(I);
          end else
            Break;
        end;
      end;
    finally
      FileList.EndUpdate;
      lvDups.Items.EndUpdate;
    end;
    btnResume.Enabled := False;
    btnStop.Enabled   := False;
    btnPause.Enabled  := False;
    btnScan.Enabled   := True;
    lblFile_Dir.Caption := 'Duplicates total : ' + IntToStr(DupCount);
  end else with PSendInfo(Message.WParam)^ do
  begin
    Inc(Self.ScanBytes, ScanBytes);
    lblFile_Dir.Caption := string(FilePath) + '\' + string(FileName);
    pbProgress.Position := (Self.ScanBytes * 100) div UsedDiskBytes;
    Dispose(PSendInfo(Message.WParam));
  end;
end;

procedure TFTest.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := ScanFinished or (MessageDlg('Are you sure ?', mtConfirmation, [mbYes, mbNo], 0) = mrYes);
  if CanClose and (ScanThread <> nil) and not ScanThread.Terminated then
    ScanThread.Terminate;
end;

procedure TFTest.FormShow(Sender: TObject);
var FileInfo: TSHFileInfo;
begin
  ilSys.Handle := SHGetFileInfo('C:\', 0, FileInfo, SizeOf(FileInfo), SHGFI_SYSICONINDEX or SHGFI_SMALLICON);
  ScanFinished := True;
  FileList := nil;
//  Color := img1.Picture.Bitmap.Canvas.Pixels[ 0, 0 ];
end;

procedure TFTest.lvDupsCustomDrawItem(Sender: TCustomListView;
 Item: TListItem; State: TCustomDrawState; var DefaultDraw: Boolean);
begin
  Sender.Canvas.Brush.Color := ifthen(Integer(Item.Data) mod 2 = 1, clCream, clLtGray);
end;

procedure TFTest.FormDestroy(Sender: TObject);
begin
  ScanThread.Free;
end;

end.
