unit UFireScan;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.Objects, FMX.Platform, System.Math,
  FMX.ExtCtrls, FMX.Ani, System.IniFiles, System.IOUtils;

type
  TIniSett = record
    ColWidth : integer;
    MinSize  : integer;
    SelectColor : TAlphaColor;
    FrameColor : TAlphaColor;
  end;
  TViewImage = class(TBitMap)
  private
    FileDir  : string;
    FileName : string;
    FileDate : TDateTime;
    function GetSize(SqSide : Single) : TPointF;
    function GetRect : TRectF;
  end;
  TScanFrm = class(TForm)
    ToolBar: TToolBar;
    StyleBook: TStyleBook;
    TrackPan: TPanel;
    ScanAni: TAniIndicator;
    TrackBar: TTrackBar;
    Grid: TPanel;
    sysClose: TButton;
    sysMax: TButton;
    sysMin: TButton;
    ImClose: TImage;
    ImMax: TImage;
    ImMin: TImage;
    StatusBar: TPanel;
    SizeGrip1: TSizeGrip;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure sysCloseClick(Sender: TObject);
    procedure sysmaxClick(Sender: TObject);
    procedure sysMinClick(Sender: TObject);
    procedure GridPaint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
    procedure GridResize(Sender: TObject);
    procedure GridMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure TrackBarMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure ToolBarMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure StatusBarPaint(Sender: TObject; Canvas: TCanvas;
      const ARect: TRectF);
  private
    BG  : TViewImage;
    TH  : Single;
    PicOfs : integer;
    NewTopOfs  : Single;
    LeftOfs  : Single;
    HeadHt, FootHt : Single;
    ImageWidth : Single;
    ColWidth : integer;
    Cols     : integer;
    Added    : integer;
    LastInd  : integer;
    FolderList : TStringList;
    Selected : integer;
    SelectedChanged : boolean;
    TopOfs   : Single;
    LastRow  : integer;
    LastPaintInd  : integer;
    LastTick : Single;
    RowHeights : array[0..1000] of Single;
    BMP : TBitMap;
    LastScan, PredScan : TDateTime;
    MinSize : integer;
    DefPageRows: integer;
    SelectColor: TAlphaColor;
    FrameColor : TAlphaColor;
    GraphList  : TStringList;
    ScanDirs   : TStringList;
    DirListOnly: boolean;
    function  OutHeight(Ind : integer) : Single;
    procedure ScanEnd(Sender: TObject);
    procedure UpdateList(Ind : integer);
    function  ImageExists(I : integer) : boolean;
    procedure SetHeights(FromInd, ToInd : integer);
    procedure DrawCell(Ind : Integer; Rect: TRectF);
    procedure PrepareBMP;
    procedure TrackChanged(Sender: TObject);
  public
    procedure RunScan;
    procedure LoadScan(ScanName : string);
    procedure KeyDown(var Key: Word; var KeyChar: System.WideChar; Shift: TShiftState); override;
    procedure SetBounds(ALeft, ATop, AWidth, AHeight: Integer); override;
  end;

  TScanThread = class(TThread)
  private
    Tm      : TDateTime;
    MinSize : Int64;
    ImageWidth: Single;
    Image   : TViewImage;
    ExtList : TStringList;
    DirList : TStringList;
    DirListOnly : boolean;
    Form    : TScanFrm;
    procedure AddFolder;
    procedure InvalidateImage(Ind : integer);
  public
    constructor Create;
    destructor Destroy; override;
    procedure  Execute; override;
  end;

var
  ScanFrm: TScanFrm;

implementation

{$R *.fmx}
uses UViewImg{$IFDEF MSWINDOWS},Winapi.ShlObj{$ENDIF};

var
  ScanThread: TScanThread = nil;
  Scanning  : boolean = False;
  Closing   : boolean = False;

{$IFDEF MSWINDOWS}
function GetSpecialPath(CSIDL: Word; var Path : string): boolean;
var tmp : array[ 0..1000 ] of WideChar;
begin
  Result := SHGetSpecialFolderPath(0, tmp, CSIDL, False);
  if Result then
    Path := tmp;
end;

procedure AddPath(List : TStringList; CSIDL: Word);
var S : string;
begin
  if GetSpecialPath(CSIDL, S) then
    List.Add(ansilowercase(S));
end;
{$ENDIF}

procedure NullCorners(Image : TImage);
begin
  with Image, BitMap do
  begin
    Pixels[0,0] := TAlphaColorRec.Null;
    Pixels[1,0] := TAlphaColorRec.Null;
    Pixels[0,1] := TAlphaColorRec.Null;
    Pixels[Width - 1,0] := TAlphaColorRec.Null;
    Pixels[Width - 1,1] := TAlphaColorRec.Null;
    Pixels[Width - 2,0] := TAlphaColorRec.Null;
    Pixels[Width - 1,Height - 1] := TAlphaColorRec.Null;
    Pixels[Width - 1,Height - 2] := TAlphaColorRec.Null;
    Pixels[Width - 2,Height - 1] := TAlphaColorRec.Null;
    Pixels[0,Height - 1] := TAlphaColorRec.Null;
    Pixels[0,Height - 2] := TAlphaColorRec.Null;
    Pixels[1,Height - 1] := TAlphaColorRec.Null;
    BitMapChanged;
  end;
end;

function TViewImage.GetSize(SqSide : Single) : TPointF;
begin
  if Height > Width then
  begin
    Result.Y := SqSide;
    Result.X := (SqSide * Width) / Height;
  end else
  begin
    Result.X := SqSide;
    Result.Y := (SqSide * Height) / Width;
  end;
end;

function TViewImage.GetRect : TRectF;
begin
  Result := RectF(0, 0, Width, height);
end;

{ TScanThread }

constructor TScanThread.Create;
begin
  inherited Create(True);
  ExtList  := TStringList.Create;
  DirList  := TStringList.Create;
  FreeOnTerminate := False;
  Priority := tpNormal;
end;

destructor TScanThread.Destroy;
begin
  ExtList.Free;
  DirList.Free;
  inherited;
end;

procedure TScanThread.InvalidateImage(Ind : integer);
begin

end;

procedure TScanThread.AddFolder;
var Ind : integer;
begin
  with Form do
  begin
    Inc(Added);
    Ind := FolderList.IndexOf(Image.FileDir);
    if Ind = -1 then
    begin
      Ind := FolderList.AddObject(Image.FileDir, Image);
      UpdateList(Ind);
    end else
    begin
      (FolderList.Objects[ Ind ]).Free;
      FolderList.Objects[ Ind ] := Image;
      InvalidateImage(Ind);
    end;
  end;
end;

procedure TScanThread.Execute;
var ExtMask : string;

  procedure Scan(Dir : string; CheckDir : boolean);
  var F : TSearchRec;
      Ext, FileName : string;
      Done : boolean;
  begin
    if FindFirst(Dir + TPath.DirectorySeparatorChar + '*' + ExtMask, faAnyFile, F) = 0 then
    begin
      Done := False;
      repeat
         if Terminated then
           Break;
         if (Tm <> 0) and (Tm >= F.TimeStamp) or (F.Name = '') or (F.Name[ 1 ] = '.') then
           Continue;
         FileName := Dir + TPath.DirectorySeparatorChar + LowerCase(F.Name);
         if F.Attr and faDirectory <> 0 then
         begin
           if not CheckDir or (DirList.IndexOf(FileName) = -1) then
             Scan(FileName, CheckDir)
         end
         else if (F.Size > MinSize) and not Done then
         begin
           Ext := ExtractFileExt(FileName);
           if Ext <> '' then
             Delete(Ext, 1, 1);
           if ExtList.IndexOf(Ext) <> -1 then
           begin
             Image := TViewImage.Create(0, 0);
             try
               Image.LoadThumbnailFromFile(FileName, ImageWidth, ImageWidth);
               Image.FileDir  := Dir;
               Image.FileName := F.Name;
               Image.FileDate := F.TimeStamp;
               Done := True;
             except
               Image.Free;
             end;
             Synchronize(AddFolder);
           end;
         end;
      until FindNext(F) <> 0;
      FindClose(F);
    end;
  end;
var I : integer;
begin
  Tm := 0;
  if ExtList.Count = 1 then
    ExtMask := ExtList[ 0 ]
  else if ExtList.Count = 2 then
  begin
    if (ExtList[ 0 ] = 'wmf') and (ExtList[ 1 ] = 'emf') then
      ExtMask := '.*mf'
    else if (ExtList[ 0 ] = 'tiff') and (ExtList[ 1 ] = 'tif') then
      ExtMask := '.tif*'
    else if (ExtList[ 0 ] = 'jpeg') and (ExtList[ 1 ] = 'jpg') then
      ExtMask := '.jp*'
    else
      ExtMask := '.*';
  end else
    ExtMask := '.*';
  if DirList.Count = 0 then
    Scan('c' + TPath.VolumeSeparatorChar, True)
  else
  begin
    for I := 0 to DirList.Count - 1 do
      Scan(DirList[ I ], False);
    if not DirListOnly then
      Scan('c' + TPath.VolumeSeparatorChar, True);
  end;
end;

procedure TScanFrm.FormActivate(Sender: TObject);
begin
;
end;

procedure TScanFrm.FormCreate(Sender: TObject);
var Ini : TIniFile;
begin
  Application.Title := 'PhotoViewer';
  BMP := TBitMap.Create(0, 0);
  LastInd := -1;
  PredScan:= 0;
  MinSize := 5000;
  FolderList := TStringList.Create(True);
  FolderList.CaseSensitive := False;
  ScanDirs  := TStringList.Create;
  GraphList := TStringList.Create;
  Ini := TIniFile.Create('config.ini');
  try
    GraphList.CommaText := ansilowercase(Ini.ReadString('data', 'extlist', 'wmf,emf,tiff,tif,jpeg,jpg,bmp,png,gif'));
    ScanDirs.CommaText  := ansilowercase(Trim(Ini.ReadString('data', 'dirlist','')));
    SelectColor := Cardinal(Ini.ReadInteger('data', 'selectcolor', Integer(TAlphaColorRec.Lime)));
    FrameColor  := Cardinal(Ini.ReadInteger('data', 'framecolor', Integer(TAlphaColorRec.DkGray)));
    ColWidth    := Ini.ReadInteger('data', 'colwidth', 150);
    DirListOnly := True;//Ini.ReadBool('data', 'dirListonly', False);
{$IFDEF MSWINDOWS}
    if ScanDirs.Count = 0 then
    begin
      ScanDirs.Add('c:\delphi_7\face');
      ScanDirs.Add(ansilowercase(GetCurrentDir));
      AddPath(ScanDirs, CSIDL_COMMON_PICTURES);
//      AddPath(ScanDirs, CSIDL_PROGRAM_FILES_COMMON);
//      AddPath(ScanDirs, CSIDL_COMMON_APPDATA);
      AddPath(ScanDirs, CSIDL_MYDOCUMENTS);
//      DirListOnly := False;
    end;
{$ENDIF}
  finally
    Ini.Free;
  end;
  ScanThread:= TScanThread.Create;
  PicOfs   := 10;
  ImageWidth := ColWidth - 2 * PicOfs;
  BG := TViewImage.CreateFromFile('satin.jpg');
  Selected  := -1;
  LastRow   := -1;
  LastPaintInd := -1;
  TrackBar.OnChange := TrackChanged;
//  LoadScan('LastScan.dat');
  TH := Canvas.TextHeight('0I');
  FootHt := TH + 8;
  HeadHt := TH + 8;
  TopOfs := 0;
  NewTopOfs := 0;
  LastTick := Platform.GetTick;
  NullCorners(imClose);
  NullCorners(imMax);
  NullCorners(imMin);
  GridResize(nil);
  RunScan;
end;


procedure TScanFrm.ScanEnd(Sender: TObject);
begin
  ScanAni.Enabled := False;
  if not Closing then
  begin
    Scanning := False;
    UpdateList(FolderList.Count - 1);
  end;
  PredScan := LastScan;
end;

procedure TScanFrm.RunScan;
begin
  if Scanning then
    Exit;
//  ScanAni.Visible := True;
  ScanAni.Enabled := True;
  LastScan := Now;
  Scanning := True;
  ScanThread.Tm := PredScan;
  ScanThread.DirListOnly := DirListOnly;
  ScanThread.MinSize := MinSize;
  ScanThread.ImageWidth := ImageWidth;
  ScanThread.Form := Self;
  ScanThread.ExtList.Assign(GraphList);
  ScanThread.DirList.Assign(ScanDirs);
  ScanThread.OnTerminate := ScanEnd;
  ScanThread.Start;
end;

procedure TScanFrm.LoadScan(ScanName : string);
var Last : TFileStream;
    Len  : WORD;
    Dir, Nm : string;
    Image : TViewImage;
begin
  try
    Last := TFileStream.Create(ScanName, fmOpenRead + fmShareDenyWrite);
    try
      Last.Read(PredScan, SizeOf(PredScan));
      Last.Read(MinSize, SizeOf(MinSize));
      while Last.Position < Last.Size do
      begin
        Last.Read(Len, SizeOf(Len));
        SetLength(Dir, Len div 2);
        Last.Read(Dir[ 1 ], Len);
        Last.Read(Len, SizeOf(Len));
        SetLength(Nm, Len div 2);
        Last.Read(Nm[ 1 ], Len);
        Image := TViewImage.Create(0, 0);
        Image.FileName := Nm;
        Image.FileDir  := Dir;
        FolderList.AddObject(Dir, Image);
      end;
    finally
      Last.Free;
    end;
  except
  end;
end;

procedure TScanFrm.FormDestroy(Sender: TObject);
var Last : TFileStream;
    Len : WORD;
    I : integer;
begin
  ScanThread.Free;
  GraphList.Free;
  ScanDirs.Free;
{  if not Scanning then
  try
    Last := TFileStream.Create('LastScan.dat', fmCreate);
    try
      Last.Write(LastScan, SizeOf(LastScan));
      Last.Write(MinSize, SizeOf(MinSize));
      for I := 0 to FolderList.Count - 1 do with TViewImage(FolderList.Objects[ I ]) do
      begin
        Len := Length(FileDir) * 2;
        Last.Write(Len, SizeOf(Len));
        Last.Write(FileDir[ 1 ], Len);
        Len := Length(FileName) * 2;
        Last.Write(Len, SizeOf(Len));
        Last.Write(FileName[ 1 ], Len);
      end;
    finally
      Last.Free;
    end;
  except
  end;}
  FolderList.Free;
  BG.Free;
  BMP.Free;
end;

procedure TScanFrm.DrawCell(Ind : Integer; Rect: TRectF);
var Size : TPointF;
    R : TRectF;
    S : string;
    Im: TViewImage;
begin
  with BMP.Canvas do
  begin
    Im := TViewImage(FolderList.Objects[ Ind ]);
    R  := TRectF.Create(PointF(Rect.Left + PicOfs, Rect.Top + 4), ImageWidth, TH);
    S  := DateToStr(Im.FileDate);
    FillText(R, S, False, 1, [], TTextAlign.taCenter);
    Size := Im.GetSize(ImageWidth);
    R := TRectF.Create(PointF(Rect.Left + (Rect.Width - Size.X) / 2, Rect.Top + HeadHt + (Rect.Height - HeadHt - FootHt - Size.Y) / 2), Size.X, Size.Y);
    InflateRect(R, 1, 1);
    DrawRectSides(R, 1, 1, AllCorners, 1, AllSides, TCornerType.ctBevel);
    InflateRect(R, -1, -1);
    DrawBitmap(Im, Im.GetRect, R, 1);
    R := TRectF.Create(PointF(Rect.Left + PicOfs, Rect.Bottom - FootHt), ImageWidth, TH);
    S := ExtractFileName(Im.FileDir);
    FillText(R, S, False, 1, [], TTextAlign.taCenter);
    if Selected = Ind then
    begin
      Stroke.Color := SelectColor;
      InflateRect(Rect, -1, -1);
      DrawRectSides(Rect, 1, 1, AllCorners, 1, AllSides, TCornerType.ctBevel);
      Stroke.Color := FrameColor;
    end;
  end;
end;

procedure TScanFrm.PrepareBMP;
var I, J, Row, DY, Ind, Last, LastCol, ScanSize : integer;
    Rect, R : TRectF;
    Size   : TPointF;
    SetMax : boolean;
    Tp, Ht, RowHeight, OfsTop, OfsBott : Single;
begin
  DY := Round(NewTopOfs - TopOfs);
  SetMax := False;
  with BMP, Canvas do
  begin
    ScanSize := Width * 4;
    R := TRectF.Create(PointF(0, 0), Width, Height);
    if (Abs(DY) < Height) and not SelectedChanged then
    begin
      if DY < 0 then
      begin
        for I := Height + DY - 1 downto 0 do
          System.Move(Scanline[ I ][0], Scanline[ I - DY ][0], ScanSize);
        R := TRectF.Create(PointF(0, 0), Width, -DY);
      end else if DY > 0 then
      begin
        for I := DY to Height - 1 do
          System.Move(Scanline[ I ][0], Scanline[ I - DY ][0], ScanSize);
        R := TRectF.Create(PointF(0, Height - DY), Width, DY);
      end;
      UpdateHandles;
      BitmapChanged;
    end;
    SelectedChanged := False;
    SetClipRects([R]);
    ClearRect(R, TAlphaColorRec.Null);
    OfsBott := NewTopOfs + R.Bottom;
    OfsTop  := NewTopOfs + R.Top;
    Ht   := 0;
    Ind  := 0;
    Row  := 0;
    Last := FolderList.Count;
    while (Ind < Last) and (Ht < OfsBott) do
    begin
      if Row < LastRow  then
      begin
        RowHeight := RowHeights[ Row ];
        LastCol   := Ind + Cols - 1;
      end else
      begin
        SetMax := True;
        RowHeight := 0;
        J := Ind + Cols;
        I := Ind;
        LastCol := I - 1;
        while I < J do
        begin
          if I >= Last then
            Break;
          if not ImageExists(I) then
            Dec(Last)
          else
          begin
            Size := TViewImage(FolderList.Objects[ I ]).GetSize(ImageWidth);
            RowHeight := System.Math.Max(RowHeight, Size.Y);
            LastCol := I;
            Inc(I);
          end;
        end;
        RowHeight := RowHeight + FootHt + HeadHt;
        RowHeights[ Row ] := RowHeight;
        LastRow := Row;
      end;
      Ht := Ht + RowHeight;
      if Ht > OfsTop then
      begin
        Tp   := Ht - NewTopOfs - RowHeight;
        Rect := TRectF.Create(PointF(LeftOfs, Tp), ColWidth, RowHeight);
        while Ind <= LastCol do with TViewImage(FolderList.Objects[ Ind ]) do
        begin
          DrawCell(Ind, Rect);
          if Ind > LastPaintInd then
            LastPaintInd := Ind;
          Inc(Ind);
          Rect.Offset(ColWidth, 0);
        end;
      end;
      Inc(Row);
      Ind := LastCol + 1;
    end;
    ExcludeClipRect(R);
  end;
  TopOfs := NewTopOfs;
  if SetMax and not TrackBar.IsTracking then
    TrackBar.Max := OutHeight(LastRow);
end;

function TScanFrm.OutHeight(Ind : integer) : Single;
begin
  Result := 0;
  while Ind >= 0 do
  begin
    Result := Result + RowHeights[ Ind ];
    Dec(Ind);
  end;
end;

procedure TScanFrm.SetBounds(ALeft, ATop, AWidth, AHeight: Integer);
var Over : boolean;
begin
  Over := (AWidth < 400) or (AHeight < 400);
  if Over then
  begin
    if AWidth < 400 then
      AWidth := 400;
    if AHeight < 400 then
      AHeight := 400;
  end;
  inherited SetBounds(ALeft, ATop, AWidth, AHeight);
  if Over then
    Abort;
end;

procedure TScanFrm.KeyDown(var Key: Word; var KeyChar: Char; Shift: TShiftState);
var DefPageItems : Integer;

  procedure NewSel(Sel : integer; Down : boolean);
  var SelRow, I : integer;
      R, Res : TRectF;
      Ht, RowHt : Single;
  begin
    if Sel > LastPaintInd then
      Sel := LastPaintInd
    else if Sel < 0 then
      Sel := 0;
    SelectedChanged := Selected <> Sel;
    Selected := Sel;
    SelRow   := Sel div Cols;
    Ht  := 0;
    for I := 0 to SelRow - 1 do
      Ht := Ht + RowHeights[ I ];
    RowHt := RowHeights[ SelRow ];
    R     := TRectF.Create(PointF(Grid.Position.X, Ht - TopOfs), ColWidth, RowHt);
    Res   := TRectF.Intersect(Grid.LocalRect, R);
    if not (Res = R) then
    begin
      if Down then
        NewTopOfs := Ht + RowHt - Trunc(Grid.Height)
      else
        NewTopOfs := Ht;
    end;
  end;

begin
  if FolderList.Count = 0 then
  begin
    inherited;
    Exit;
  end;
  DefPageItems := DefPageRows * Cols;
  NewTopOfs := TopOfs;
  SelectedChanged := True;
  case Key of
    VKLEFT :
      NewSel(Selected - 1, False);
    VKRIGHT:
      NewSel(Selected + 1, True);
    VKUP :
      NewSel(Selected - Cols, False);
    VKDOWN :
      NewSel(Selected + Cols, True);
    VKNEXT  :
      NewSel(Selected + DefPageItems, True);
    VKPRIOR :
      NewSel(Selected - DefPageItems, False);
    VKHOME  :
      begin
        SelectedChanged := Selected <> 0;
        Selected  := 0;
        NewTopOfs := 0;
      end;
    VKEND   :
      NewSel(LastPaintInd, True);
    VKRETURN :
      if Selected >= 0 then with TViewImage(FolderList[ Selected ]) do
      begin
        DisplayImage(FileDir + TPath.DirectorySeparatorChar  + FileName, GraphList);
        with Grid do InvalidateRect(LocalRect);
      end;
  else
    SelectedChanged := False;
  end;
  if SelectedChanged then
  begin
    Key := 0;
    if Selected >= 0 then
      with StatusBar do InvalidateRect(LocalRect);
  end;
  inherited;
  if SelectedChanged then
  begin
    TrackBar.Value := Trunc(NewTopOfs);
    with Grid do InvalidateRect(LocalRect);
  end;
end;

procedure TScanFrm.GridMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
var I, Ind : integer;
    Ht, Ofs, RowHeight : Single;
begin
  Ofs := TopOfs + Y;
  I   := 0;
  Ht  := 0;
  Ind := Trunc((X - LeftOfs) / ColWidth);
  while True do
  begin
    RowHeight := RowHeights[ I ];
    Ht := Ht + RowHeight;
    if Ind > LastPaintInd then
       Exit;
    if Ht > Ofs then
    begin
      SelectedChanged := True;
      Selected := Ind;
      with TViewImage(FolderList.Objects[ Selected ]) do
        DisplayImage(FileDir + TPath.DirectorySeparatorChar + FileName, GraphList);
      with StatusBar do InvalidateRect(LocalRect);
      NewTopOfs := TopOfs;
      with Grid do InvalidateRect(LocalRect);
      Exit;
    end;
    Inc(Ind, Cols);
    Inc(I);
  end;
end;

procedure TScanFrm.GridPaint(Sender: TObject; Canvas: TCanvas;
  const ARect: TRectF);
begin
  PrepareBMP;
  with Grid, Canvas do
  begin
    DrawBitmap(BG, BG.GetRect, ARect, 1);
    DrawBitmap(BMP, RectF(0, 0, BMP.Width, BMP.Height), ARect, 1);
  end;
end;

procedure TScanFrm.GridResize(Sender: TObject);
begin
  Cols    := Trunc(Grid.Width / ColWidth);
  LeftOfs := (Grid.Width - Cols * ColWidth) / 2;
  with BMP do
  begin
    Width  := Trunc(Grid.Width);
    Height := Trunc(Grid.Height);
    with Canvas do
    begin
      Stroke.Color := FrameColor;
      Font.Family  := 'Verdana';
      Font.Size    := 11;
      Font.Style   := [];
    end;
  end;
  FillChar(RowHeights, SizeOf(RowHeights), #0);
  LastRow := -1;
  TopOfs  := 0;
  NewTopOfs := 0;
  LastPaintInd := -1;
  DefPageRows := Trunc(BMP.Height / (ImageWidth + HeadHt + FootHt));
end;

procedure TScanFrm.sysCloseClick(Sender: TObject);
begin
  Closing := True;
  ScanThread.Terminate;
  ScanThread.WaitFor;
  Close;
end;

procedure TScanFrm.sysmaxClick(Sender: TObject);
begin
  if WindowState = TWindowState.wsNormal then
    WindowState := TWindowState.wsMaximized
  else
    WindowState := TWindowState.wsNormal;
end;

procedure TScanFrm.sysMinClick(Sender: TObject);
begin
  WindowState := TWindowState.wsMinimized;
end;

procedure TScanFrm.SetHeights(FromInd, ToInd : integer);
var I, J : integer;
    Size : TPointF;
    RowHeight : Single;
begin
  J := FromInd mod Cols;
  if J = Cols - 1 then
    I := FromInd + 1
  else
    I := FromInd - J;
  while I <= ToInd do
  begin
    LastRow := I div Cols;
    RowHeight := 0;
    J := System.Math.Min(I + Cols - 1, ToInd);
    while I <= J do with TViewImage(FolderList.Objects[ I ]) do
    begin
      Size := GetSize(ImageWidth);
      RowHeight := System.Math.Max(RowHeight, Size.Y);
      Inc(I);
    end;
    RowHeight := RowHeight + FootHt + HeadHt;
    RowHeights[ LastRow ] := RowHeight;
    I := J + 1;
  end;
end;

procedure TScanFrm.StatusBarPaint(Sender: TObject; Canvas: TCanvas;
  const ARect: TRectF);
var S : string;
begin
  if Selected >= 0 then with Canvas, TViewImage(FolderList.Objects[ Selected ]) do
  begin
    Font.Family  := 'Verdana';
    Font.Size    := 11;
    Font.Style   := [];
    Fill.Color := SelectColor;
    Fill.Kind  := TBrushKind.bkSolid;
    S := DateToStr(FileDate) + ' ' + FileDir + TPath.DirectorySeparatorChar + FileName;
    FillText(ARect, S, False, 1, [], TTextAlign.taCenter);
  end;
end;

procedure TScanFrm.ToolBarMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
begin
  StartWindowDrag;
end;

procedure TScanFrm.TrackBarMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
begin
  TrackBar.Max := OutHeight(LastRow);
end;

procedure TScanFrm.TrackChanged(Sender: TObject);
begin
  NewTopOfs := TrackBar.Value;
  with Grid do InvalidateRect(LocalRect);
end;

function  TScanFrm.ImageExists(I : integer) : boolean;
begin
  Result := True;
  with TViewImage(FolderList.Objects[ I ]) do
    if IsEmpty or (Width = 0) then
    try
      LoadThumbnailFromFile(FileDir + TPath.DirectorySeparatorChar + FileName, ImageWidth, ImageWidth);
      if Width = 0 then
        Abort;
      FileAge(FileDir + TPath.DirectorySeparatorChar + FileName, FileDate);
    except
      Result := False;
      FolderList.Delete(I);
    end;
end;

procedure TScanFrm.UpdateList(Ind : integer);
var I : integer;
    Tick, Ht : Single;
    FullPage : boolean;
    ItemOnGrid : boolean;
begin
  I := LastInd + 1;
  while I <= Ind do
  begin
    if not ImageExists(I) then
      Dec(Ind)
    else
      Inc(I);
  end;
  SetHeights(LastInd, Ind);
  LastInd := Ind;
  Tick := Platform.GetTick;
  Ht   := OutHeight(LastRow);
  FullPage   := (TopOfs = 0) and (Ht > Grid.Height) and (Ind mod Cols = Cols - 1);
  ItemOnGrid := (TopOfs > 0) and (Ht > TopOfs) and (Ht < TopOfs + Grid.Height);
  if ItemOnGrid or FullPage or (TopOfs = 0) and (Tick - LastTick > 2) then
  begin
    LastTick := Tick;
    with Grid do InvalidateRect(LocalRect);
  end;
  if not TrackBar.IsTracking then
    TrackBar.Max := Ht;
end;


end.
