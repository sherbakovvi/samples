unit UPlayerEx;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls, ImgList, ToolWin, ExtCtrls, StrUtils, CommCtrl,
  Tracker2, Menus;

const
  WM_PLAYNOTIFY = WM_USER + 1;
type
  TPlayerState = (psClosed, psPlaying, psEndOfPlay, psStopped, psPaused);
  TFPlay = class(TForm)
    tlbBar: TToolBar;
    btnPlay: TToolButton;
    btnFastPlay: TToolButton;
    btnPause: TToolButton;
    btnRewind: TToolButton;
    btnBkFrame: TToolButton;
    btnGoFrame: TToolButton;
    pnlPlayWnd: TPanel;
    btnSep1: TToolButton;
    btnStop: TToolButton;
    btnSep5: TToolButton;
    btnSep2: TToolButton;
    btnSearch: TToolButton;
    btnSep: TToolButton;
    btnOpen: TToolButton;
    btn1: TToolButton;
    btnCapture: TToolButton;
    btnAbout: TToolButton;
    btnHelp: TToolButton;
    btnAudio: TToolButton;
    btnLoop: TToolButton;
    btn2: TToolButton;
    dlgOpen: TOpenDialog;
    ilImList: TImageList;
    btnLang: TToolButton;
    pnlStat: TPanel;
    lblLength: TLabel;
    lbl1: TLabel;
    lblPos: TLabel;
    ilDisabled: TImageList;
    btnSpeed: TToolButton;
    pmSpeed: TPopupMenu;
    N1001: TMenuItem;
    N2001: TMenuItem;
    N4001: TMenuItem;
    N8001: TMenuItem;
    procedure btnStopClick(Sender: TObject);
    procedure btnPauseClick(Sender: TObject);
    procedure btnOpenClick(Sender: TObject);
    procedure btnPlayClick(Sender: TObject);
    procedure btnFastPlayClick(Sender: TObject);
    procedure btnBkFrameClick(Sender: TObject);
    procedure btnRewindClick(Sender: TObject);
    procedure btnSearchClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnGoFrameClick(Sender: TObject);
    procedure btnCaptureClick(Sender: TObject);
    procedure btnLoopClick(Sender: TObject);
    procedure btnAudioClick(Sender: TObject);
    procedure btnSettClick(Sender: TObject);
    procedure btnAboutClick(Sender: TObject);
    procedure btnHelpClick(Sender: TObject);
    procedure btnLangClick(Sender: TObject);
    procedure TrackBarPositionChanged(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure N1001Click(Sender: TObject);
  private
    FPlayerState: TPlayerState;
    Port: Word;
    Speed: DWORD;
    TimeLength: DWORD;
    //    TimePlayed : DWORD;
    PlayedFile: string;
    FilesPath: string;
    TrackBar: TTrackBar2;
    LastPos: Integer;
    InNotify: boolean;
    //    OldPosition : Integer;
    procedure SetPlayerState(const Value: TPlayerState);
    procedure DoGrayScale;
  protected
    property PlayerState: TPlayerState read FPlayerState write SetPlayerState;
    procedure WMPLAYNOTIFY(var Message: TMessage); message WM_PLAYNOTIFY;
  public
    procedure LangChanged;
    procedure OpenFile(FileName: string);
    procedure Check(Res: integer; Msg: string);
  end;

var
  FPlay: TFPlay;

implementation

uses HH5Player, HHReadWriter, RegIni, USearch;

{$R *.dfm}

procedure TFPlay.btnStopClick(Sender: TObject);
begin
  if PlayerState in [psClosed, psStopped, psPaused] then
    Exit;
  Check(HH5PLAYER_Stop(Port), 'Can"t stop file');
  PlayerState := psStopped;
end;

procedure TFPlay.btnPauseClick(Sender: TObject);
begin
  if PlayerState in [psClosed, psStopped, psPaused] then
    Exit;
  Check(HH5PLAYER_Pause(Port), 'Can"t pause file');
  PlayerState := psPaused;
end;

procedure TFPlay.btnOpenClick(Sender: TObject);
begin
  with dlgOpen do
  begin
    InitialDir := FilesPath;
    if Execute then
      OpenFile(FileName);
  end;
end;

procedure TFPlay.btnPlayClick(Sender: TObject);
begin
  if (PlayedFile <> '') and (PlayerState = psClosed) then
  begin
    OpenFile(PlayedFile);
    Exit;
  end;
  if PlayerState in [psClosed, psPlaying] then
    Exit;
  if PlayerState = psStopped then
    Check(HH5PLAYER_Play(Port), 'Can"t play file')
  else
    Check(HH5PLAYER_Resume(Port), 'Can"t resume file');
  PlayerState := psPlaying;
end;

procedure TFPlay.btnFastPlayClick(Sender: TObject);
begin
  if PlayerState in [psClosed] then
    Exit;
  Check(HH5PLAYER_FastPlay(Port, Speed), 'Can"t fastplay file');
end;

procedure TFPlay.btnBkFrameClick(Sender: TObject);
begin
  if PlayerState in [psClosed, psPlaying] then
    Exit;
  Check(HH5PLAYER_FrameBack(Port), 'Can"t FrameBack file');
end;

procedure TFPlay.btnRewindClick(Sender: TObject);
begin
  if PlayerState in [psClosed] then
    Exit;
  Check(HH5PLAYER_FastPlayBack(Port, Speed), 'Can"t fastplay file');
end;

procedure TFPlay.Check(Res: integer; Msg: string);
begin
  if Res <> 0 then
  begin
    MessageDlg(Msg + ',error : ' + IntToStr(Res), mtError, [mbOK], 0);
    Abort;
  end;
end;

procedure TFPlay.btnSearchClick(Sender: TObject);
var
  FileName: string;
  P: TPoint;
begin
  P := tlbBar.ClientToScreen(Point(btnSearch.Left - FSearch.Width div 2,
    btnSearch.Top - FSearch.Height));
  FileName := Search(FilesPath, P);
  if FileName <> '' then
    OpenFile(FileName);
end;

procedure TFPlay.OpenFile(FileName: string);
var
  P: PChar;
  I: Integer;
begin
  if CompareText(FilesPath, Copy(FileName, 1, Length(FilesPath))) <> 0 then
  begin
    I := Pos('\General\', FileName);
    if I <> 0 then
      FilesPath := ExtractFilePath(Copy(FileName, 1, I - 1));
  end;
  PlayedFile := FileName;
  P := StrAlloc(Length(FileName) + 1);
  try
    StrPCopy(P, FileName);
    Check(HH5PLAYER_OpenStreamFileM(Port, @P, 1, TimeLength),
      'Can"t open file');
    HH5PLAYER_RegPlayStatusMsg(Port, Handle, WM_PLAYNOTIFY);
  finally
    StrDispose(P);
  end;
  Check(HH5PLAYER_Play(Port), 'Can"t play file');
  PlayerState := psPlaying;
  Check(HH5PLAYER_SetAudio(Port, btnAudio.Down), 'Can"t set audo');
  Check(HH5PLAYER_SetPlayLoop(Port, btnLoop.Down), 'Can"t set loop');
  lblLength.Caption := FormatDateTime('HH:nn:ss', TimeLength / SecsPerDay);
end;

procedure TFPlay.LangChanged;
begin
  btnPlay.Hint := ifthen(LangEn, 'Play', 'Воспроизведение');
  btnFastPlay.Hint := ifthen(LangEn, 'Fast play', 'Быстрое Воспроизведение');
  btnPause.Hint := ifthen(LangEn, 'Pause', 'Пауза');
  btnRewind.Hint := ifthen(LangEn, 'Rewind', 'Перемотка');
  btnBkFrame.Hint := ifthen(LangEn, 'Back frame', 'Назад кадр');
  btnGoFrame.Hint := ifthen(LangEn, 'Forw frame', 'Вперед кадр');
  btnStop.Hint := ifthen(LangEn, 'Stop', 'Остановить');
  btnSearch.Hint := ifthen(LangEn, 'Search', 'Поиск');
  btnOpen.Hint := ifthen(LangEn, 'Open file', 'Открыть файл');
  btnCapture.Hint := ifthen(LangEn, 'Capture frame', 'Сохранить кадр');
  btnAbout.Hint := ifthen(LangEn, 'About', 'О программе');
  btnHelp.Hint := ifthen(LangEn, 'Help', 'Помощь');
  btnAudio.Hint := ifthen(LangEn, 'Audio', 'Звук');
  btnLoop.Hint := ifthen(LangEn, 'Loop', 'АвтоПовтор');
  btnSpeed.Hint := ifthen(LangEn, 'Rewind speed', 'Скорость перемотки');
  btnLang.Hint := 'English/Русский';
end;

procedure TFPlay.FormShow(Sender: TObject);
begin
  PlayerState := psClosed;
  FilesPath := ReadString('Common', 'FilesPath', 'C:\XDVfiles');
  LangEn := ReadBool('Common', 'LangEn', True);
  Speed := ReadInteger('Common', 'RewindSpeed', 100);
  btnAudio.Down := ReadBool('Common', 'Audio', True);
  btnLoop.Down := ReadBool('Common', 'Loop', False);
  LangChanged;
  Port := 0;
  Check(HH5PLAYER_InitSDK(pnlPlayWnd.Handle), 'HH5PLAYER_InitSDK');
  Check(HH5PLAYER_InitPlayer(Port, pnlPlayWnd.Handle), 'HH5PLAYER_InitPlayer');
end;

procedure TFPlay.FormDestroy(Sender: TObject);
begin
  HH5PLAYER_ReleasePlayer(Port);
  HH5PLAYER_ReleaseSDK;
  TrackBar.Free;
end;

procedure TFPlay.WMPLAYNOTIFY(var Message: TMessage);
begin
  if Message.WParam = Port then
  begin
    if DWORD(Message.LParam) = $FFFFFFFF then
      // lParam PlayTime, $FFFFFFFF : end of play
    begin
      Message.LParam := 0;
      if not btnLoop.Down then
        PlayerState := psEndOfPlay;
    end;
    { if (DWORD(LParam) > EndTime  then
        LParam := 0;
    }
    LastPos := (Message.LParam * 100) div Integer(TimeLength);
    InNotify := True;
    TrackBar.PositionL := LastPos;
    InNotify := False;
  end
  else if Message.WParam = 301 then
  begin
  end;
  Message.Result := 1;
end;

procedure TFPlay.btnGoFrameClick(Sender: TObject);
begin
  if PlayerState in [psClosed, psPlaying] then
    Exit;
  Check(HH5PLAYER_FrameGO(Port), 'Can"t GoFrame file');
end;

procedure TFPlay.btnCaptureClick(Sender: TObject);
var
  bmp: Pointer;
  Size: Integer;
  T: TSystemTime;
  FBmp: string;
  H: THandle;
begin
  if PlayerState in [psClosed] then
    Exit;
  Check(HH5PLAYER_CaptureOnePicture(Port, @bmp, size), 'CaptureOnePicture');
  GetSystemTime(T);
  FBmp := FilesPath + 'picture';
  ForceDirectories(FBmp);
  FBmp := FBmp + '\' + Format('%04d_%02d_%02d_%02d_%02d_%02d.bmp', [t.wYear,
    t.wMonth, t.wDay, t.wHour, t.wMinute, t.wSecond]);
  H := FileCreate(FBmp);
  if H = INVALID_HANDLE_VALUE then
    Check(GetLastError, 'Can"t create picture file')
  else
  begin
    FileWrite(H, bmp^, size);
    FileClose(H);
  end;
end;

procedure TFPlay.btnLoopClick(Sender: TObject);
begin
  Check(HH5PLAYER_SetPlayLoop(Port, btnLoop.Down), 'Can"t set audo');
  WriteBool('Common', 'Loop', btnLoop.Down);
end;

procedure TFPlay.btnAudioClick(Sender: TObject);
begin
  Check(HH5PLAYER_SetAudio(Port, btnAudio.Down), 'Can"t set audo');
  WriteBool('Common', 'Audio', btnAudio.Down);
end;

procedure TFPlay.btnSettClick(Sender: TObject);
begin
  ;
end;

function ConvertBitmapToGrayscale(const Bitmap: TBitmap): TBitmap;
var
  I, J: Integer;
  Grayshade, Red, Green, Blue: Byte;
  PixelColor: Longint;
begin
  with Bitmap do
    for I := 0 to Width - 1 do
      for J := 0 to Height - 1 do
      begin
        PixelColor := ColorToRGB(Canvas.Pixels[I, J]);
        Red := PixelColor;
        Green := PixelColor shr 8;
        Blue := PixelColor shr 16;
        Grayshade := Round(0.3 * Red + 0.6 * Green + 0.1 * Blue);
        Canvas.Pixels[I, J] := RGB(Grayshade, Grayshade, Grayshade);
      end;
  Result := Bitmap;
end;

procedure TFPlay.DoGrayScale;
var
  BMP: TBitmap;
  I: Integer;
begin
  BMP := TBitmap.Create;
  try
    for I := 0 to ilImList.Count - 3 do
    begin
      ilImList.GetBitmap(I, BMP);
      BMP := ConvertBitmapToGrayscale(BMP);
      BMP.Transparent := True;
      ilDisabled.AddMasked(BMP, clWhite);
    end;
  finally
    BMP.Free;
  end;
end;

procedure TFPlay.btnAboutClick(Sender: TObject);
begin
  ;
end;

procedure TFPlay.btnHelpClick(Sender: TObject);
begin
  ;
end;

procedure TFPlay.SetPlayerState(const Value: TPlayerState);
begin
  FPlayerState := Value;
  btnPlay.Enabled := (FPlayerState in [psStopped, psPaused, psEndOfPlay]);
  btnFastPlay.Enabled := FPlayerState in [psStopped, psPaused];
  btnPause.Enabled := FPlayerState in [psPlaying];
  btnRewind.Enabled := FPlayerState in [psStopped, psPaused, psPlaying];
  btnBkFrame.Enabled := FPlayerState in [psStopped, psPaused];
  btnGoFrame.Enabled := FPlayerState in [psStopped, psPaused];
  btnStop.Enabled := FPlayerState in [psPlaying];
  //  btnOpen.Enabled      := FPlayerState in [];
  btnCapture.Enabled := FPlayerState in [psStopped, psPaused, psPlaying];
end;

procedure TFPlay.btnLangClick(Sender: TObject);
begin
  LangEn := not LangEn;
  if LangEn then
    btnLang.ImageIndex := 14
  else
    btnLang.ImageIndex := 15;
  WriteBool('Common', 'LangEn', LangEn);
  LangChanged;
end;

procedure TFPlay.TrackBarPositionChanged(Sender: TObject);
var
  Secs: Integer;
begin
  Secs := MulDiv(TTrackBar2(Sender).PositionL, TimeLength, 100);
  lblPos.Caption := FormatDateTime('HH:nn:ss', Secs / SecsPerDay);
  if not InNotify then
  begin
    Check(HH5PLAYER_Pause(Port), 'Can"t pause file');
    PlayerState := psPaused;
    Check(HH5PLAYER_SeekToSecond(Port, Secs), 'HH5PLAYER_SeekToSecond');
    Check(HH5PLAYER_Resume(Port), 'Can"t resume file');
    PlayerState := psPlaying;
  end;
end;

procedure TFPlay.FormCreate(Sender: TObject);
begin
  TrackBar := TTrackBar2.Create(Self);
  with TrackBar do
  begin
    Parent := Self;
    SecondThumb := False;
    Orientation := toHorizontal;
    OnChange := TrackBarPositionChanged;
    ThumbStyle := tsMediumPointer;
    TickStyle := tiUserDrawn;
    TickSize := 0;
    Height := 22;
    Color := $00F4D8BD;
    Align := alBottom;
    Max := 100;
  end;
  DoGrayScale;
end;

procedure TFPlay.N1001Click(Sender: TObject);
begin
  Speed := StrToInt(TMenuItem(Sender).Caption);
  WriteInteger('Common', 'RewindSpeed', Speed);
end;

end.

