unit UViewImg;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.Objects, FMX.Platform, System.Math,
  FMX.ExtCtrls, FMX.Ani, FMX.Effects, FMX.Layouts, System.IOUtils, Effect;

type
  TViewImage = class(TBitMap)
  private
    FileName : string;
    FileDate : TDateTime;
    function GetSize(SqSide : Single) : TPointF;
    function GetRect : TRectF;
  end;
  TViewImg = class(TForm)
    ToolBar: TToolBar;
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
    SizeGrip: TSizeGrip;
    Shadow: TImage;
    ViewImage: TImageViewer;
    BlurEffect: TBlurEffect;
    Effects: TButton;
    RotCountClockWise: TCornerButton;
    RotClockWise: TCornerButton;
    ImClockWise: TImage;
    ImCountClockWise: TImage;
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
    procedure EffectsClick(Sender: TObject);
    procedure RotClockWiseClick(Sender: TObject);
    procedure RotCountClockWiseClick(Sender: TObject);
  private
    PicOfs : integer;
    NewTopOfs  : Single;
    HeadHt, FootHt : Single;
    ImageWidth : Single;
    ColWidth : integer;
    Cols     : integer;
    LastInd  : integer;
    ImgList : TStringList;
    Selected : integer;
    SelectedChanged : boolean;
    TopOfs   : Single;
    LastRow  : integer;
    LastPaintInd : integer;
    RowHeights : array[0..1000] of Single;
    BMP : TBitMap;
    MinSize : integer;
    DefPageRows : integer;
    SelectColor : TAlphaColor;
    FrameColor : TAlphaColor;
    ViewDir : string;
    ViewFileName : string;
    GraphList : TStringList;
    Handled : boolean;
    function  OutHeight(Ind : integer) : Single;
    procedure ScanEnd(Sender: TObject);
    procedure UpdateList(Ind : integer);
    function  ImageExists(I : integer) : boolean;
    procedure SetHeights(FromInd, ToInd : integer);
    procedure DrawCell(Ind : Integer; Rect: TRectF);
    procedure PrepareBMP;
    procedure TrackChanged(Sender: TObject);
    procedure PlaceImage;
    procedure LoadImage(FileName : string);
  public
    procedure RunScan;
    procedure KeyDown(var Key: Word; var KeyChar: System.WideChar; Shift: TShiftState); override;
    procedure SetBounds(ALeft, ATop, AWidth, AHeight: Integer); override;
  end;

  TScanThread = class(TThread)
  private
    MinSize : Int64;
    ImageWidth: Single;
    Image   : TViewImage;
    ExtList : TStringList;
    Form    : TViewImg;
    procedure AddFolder;
  public
    constructor Create;
    destructor Destroy; override;
    procedure  Execute; override;
  end;

procedure DisplayImage(const AFileName : string; AGraphList : TStringList);

var
  ViewImg: TViewImg;

implementation

{$R *.fmx}
var
  ScanDir   : TScanThread = nil;
  Scanning  : boolean = False;

procedure DisplayImage(const AFileName : string; AGraphList : TStringList);
var F : TCustomForm;
   Image : TViewImage;
begin
  ViewImg := TViewImg.Create(Application);
  with ViewImg do
  try
    F := TCustomForm(Application.MainForm);
    SetBounds(F.Left, F.Top, F.Width, F.Height);
    StyleBook := F.StyleBook;
    ViewDir := ExtractFileDir(AFileName);
    ViewFileName := AFileName;
    Image := TViewImage.Create(0, 0);
    Image.LoadThumbnailFromFile(AFileName, ImageWidth, ImageWidth);
    Image.FileName := AFileName;
    FileAge(AFileName, Image.FileDate);
    ImgList.AddObject(Image.FileName, Image);
    Selected := 0;
    LoadImage(ViewFileName);
    GraphList := AGraphList;
    RunScan;
    ShowModal;
  finally
    Free;
  end;
end;

procedure TViewImg.LoadImage(FileName : string);
begin
  with ViewImage.Bitmap do
  begin
    Handled := False;
    LoadFromFile(FileName);
    PlaceImage;
  end;
end;

procedure TViewImg.PlaceImage;
var MaxHt    : Single;
    ShadSize : Single;
begin
  with ViewImage do
  begin
    ShadSize := System.Math.Min(Bitmap.Width, Bitmap.Height) / 4;
    if ShadSize > 50 then
      ShadSize := 50;
    MaxHt := Self.Height - ToolBar.Height - StatusBar.Height;
    if (Bitmap.Width + ShadSize < Grid.Position.X) and (Bitmap.Height + ShadSize < MaxHt) and not Handled then
    begin
      ViewImage.Align := TAlignLayout.alNone;
      ViewImage.Position.Point := PointF((Grid.Position.X - Bitmap.Width - ShadSize) / 2, (MaxHt - Bitmap.Height - ShadSize) / 2 + ShadSize + ToolBar.Height);
      ViewImage.Width  := Bitmap.Width + 4;
      ViewImage.Height := Bitmap.Height + 4;
      ViewImage.HScrollBar.Visible := False;
      ViewImage.VScrollBar.Visible := False;
      Shadow.Visible   := True;
      Shadow.BitMap.Assign(ViewImage.Bitmap);
      Shadow.BitMap.SetSize(Bitmap.Width, Bitmap.Height);
      Shadow.Width := Bitmap.Width;
      Shadow.Height := Bitmap.Height;
      Shadow.Position.Point := PointF(ViewImage.Position.X + ShadSize, ViewImage.Position.Y - ShadSize);
    end else if (Bitmap.Width < Grid.Position.X) and (Bitmap.Height < MaxHt) and not Handled then
    begin
      Shadow.Visible := False;
      ViewImage.Align := TAlignLayout.alNone;
      ViewImage.Position.Point := PointF((Grid.Position.X - Bitmap.Width) / 2, (MaxHt - Bitmap.Height) / 2 + ToolBar.Height);
      ViewImage.Width := Bitmap.Width + 4;
      ViewImage.Height:= Bitmap.Height + 4;
      ViewImage.HScrollBar.Visible := False;
      ViewImage.VScrollBar.Visible := False;
    end else
    begin
      Shadow.Visible := False;
      ViewImage.HScrollBar.Visible := Bitmap.Width > Grid.Position.X;
      ViewImage.VScrollBar.Visible := Bitmap.Height > MaxHt;
      ViewImage.Align := TAlignLayout.alClient;
    end;
  end;
end;

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
  FreeOnTerminate := False;
  Priority := tpNormal;
end;

destructor TScanThread.Destroy;
begin
  ExtList.Free;
  inherited;
end;

procedure TScanThread.AddFolder;
var Ind : integer;
begin
  with Form do
  begin
    if ImgList.IndexOf(Image.FileName) >= 0 then
      Exit;
    Ind := ImgList.AddObject(Image.FileName, Image);
    UpdateList(Ind);
  end;
end;

procedure TScanThread.Execute;

  procedure Scan(Dir : string);
  var F : TSearchRec;
      Ext, FileName : string;
  begin
    if FindFirst(Dir + TPath.DirectorySeparatorChar + '*' + TPath.ExtensionSeparatorChar + '*', faAnyFile, F) = 0 then
    begin
      repeat
         if Terminated then
           Break;
         if (F.Name = '') or (F.Name[ 1 ] = '.') then
           Continue;
         FileName := Dir + TPath.DirectorySeparatorChar  + F.Name;
         if F.Attr and faDirectory <> 0 then
         else if F.Size > MinSize then
         begin
           Ext := LowerCase(ExtractFileExt(F.Name));
           if Ext <> '' then
             Delete(Ext, 1, 1);
           if ExtList.IndexOf(Ext) <> -1 then
           begin
             Image := TViewImage.Create(0, 0);
             try
               Image.LoadThumbnailFromFile(FileName, ImageWidth, ImageWidth);
               Image.FileName := Dir + TPath.DirectorySeparatorChar  + F.Name;
               Image.FileDate := F.TimeStamp;
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

begin
  Scan(Form.ViewDir);
end;

procedure TViewImg.EffectsClick(Sender: TObject);
begin
  ShowEffects(ViewImage.Bitmap);
end;

procedure TViewImg.FormActivate(Sender: TObject);
begin
;
end;

procedure TViewImg.FormCreate(Sender: TObject);
begin
  BMP := TBitMap.Create(0, 0);
  LastInd := -1;
  MinSize := 5000;
  ImgList := TStringList.Create(True);
  ImgList.CaseSensitive := False;
  ScanDir:= TScanThread.Create;
  ColWidth := 150;
  PicOfs   := 10;
  ImageWidth := ColWidth - 2 * PicOfs;
  Selected  := -1;
  LastRow   := -1;
  LastPaintInd := -1;
  SelectColor := TAlphaColorRec.Lime;
  FrameColor  := TAlphaColorRec.DkGray;
  TrackBar.OnChange := TrackChanged;
  FootHt := 3;
  HeadHt := 3;
  TopOfs := 0;
  NewTopOfs := 0;
  NullCorners(imClose);
  NullCorners(imMax);
  NullCorners(imMin);
  GridResize(nil);
end;


procedure TViewImg.ScanEnd(Sender: TObject);
begin
  ScanAni.Enabled := False;
  Scanning := False;
  UpdateList(ImgList.Count - 1);
end;

procedure TViewImg.RotClockWiseClick(Sender: TObject);
begin
  if not Handled then
  begin
    Handled := True;
    PlaceImage;
  end;
  ViewImage.Bitmap.Rotate(90);
end;

procedure TViewImg.RotCountClockWiseClick(Sender: TObject);
begin
  if not Handled then
  begin
    Handled := True;
    PlaceImage;
  end;
  ViewImage.Bitmap.Rotate(-90);
end;

procedure TViewImg.RunScan;
begin
  if Scanning then
    Exit;
//  ScanAni.Visible := True;
  ScanAni.Enabled := True;
  Scanning := True;
  ScanDir.MinSize := MinSize;
  ScanDir.ImageWidth := ImageWidth;
  ScanDir.Form := Self;
  ScanDir.ExtList.Assign(GraphList);
  ScanDir.OnTerminate := ScanEnd;
  ScanDir.Start;
end;

procedure TViewImg.FormDestroy(Sender: TObject);
begin
  ScanDir.Free;
  ImgList.Free;
  BMP.Free;
end;

procedure TViewImg.DrawCell(Ind : Integer; Rect: TRectF);
var Size : TPointF;
    R : TRectF;
    Im: TViewImage;
begin
  with BMP.Canvas do
  begin
    Im := TViewImage(ImgList.Objects[ Ind ]);
    Size := Im.GetSize(ImageWidth);
    R := TRectF.Create(PointF(Rect.Left + (Rect.Width - Size.X) / 2, Rect.Top + HeadHt + (Rect.Height - HeadHt - FootHt - Size.Y) / 2), Size.X, Size.Y);
    InflateRect(R, 1, 1);
    DrawRectSides(R, 1, 1, AllCorners, 1, AllSides, TCornerType.ctBevel);
    InflateRect(R, -1, -1);
    DrawBitmap(Im, Im.GetRect, R, 1);
    if Selected = Ind then
    begin
      Stroke.Color := SelectColor;
      InflateRect(Rect, -1, -1);
      DrawRectSides(Rect, 1, 1, AllCorners, 1, AllSides, TCornerType.ctBevel);
      Stroke.Color := FrameColor;
    end;
  end;
end;

procedure TViewImg.PrepareBMP;
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
    SelectedChanged := True;
    SetClipRects([R]);
    ClearRect(R, TAlphaColorRec.Null);
    OfsBott := NewTopOfs + R.Bottom;
    OfsTop  := NewTopOfs + R.Top;
    Ht   := 0;
    Ind  := 0;
    Row  := 0;
    Last := ImgList.Count;
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
            Size := TViewImage(ImgList.Objects[ I ]).GetSize(ImageWidth);
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
        Rect := TRectF.Create(PointF(0, Tp), ColWidth, RowHeight);
        while Ind <= LastCol do with TViewImage(ImgList.Objects[ Ind ]) do
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

function TViewImg.OutHeight(Ind : integer) : Single;
begin
  Result := 0;
  while Ind >= 0 do
  begin
    Result := Result + RowHeights[ Ind ];
    Dec(Ind);
  end;
end;

procedure TViewImg.KeyDown(var Key: Word; var KeyChar: System.WideChar; Shift: TShiftState);
var DefPageItems : Integer;

  procedure NewSel(Sel : integer; Down : boolean);
  var SelRow, I : integer;
      R, Res : TRectF;
      Ht, RowHt : Single;
  begin
    if Sel >= ImgList.Count then
      Sel := ImgList.Count - 1
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
  if ImgList.Count = 0 then
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
      begin
        NewSel(Selected - Cols, False);
        if SelectedChanged  then with TViewImage(ImgList.Objects[ Selected ]) do
          LoadImage(FileName);
      end;
    VKDOWN :
      begin
        NewSel(Selected + Cols, True);
        if SelectedChanged  then with TViewImage(ImgList.Objects[ Selected ]) do
          LoadImage(FileName);
      end;
    VKNEXT  :
      NewSel(Selected + DefPageItems, True);
    VKPRIOR :
      if Selected >= DefPageItems then
        NewSel(Selected - DefPageItems, False);
    VKHOME  :
      begin
        SelectedChanged := Selected <> 0;
        Selected := 0;
        NewTopOfs := 0;
      end;
    VKEND   :
        NewSel((ImgList.Count - 1) - (ImgList.Count - 1) mod Cols, True);
    VKRETURN :
      if Selected >= 0 then with TViewImage(ImgList.Objects[ Selected ]) do
        LoadImage(FileName);
  else
    SelectedChanged := False;
  end;
  if SelectedChanged then
    Key := 0;
  inherited;
  if SelectedChanged then
  begin
    TrackBar.Value := Trunc(NewTopOfs);
    with Grid do InvalidateRect(LocalRect);
  end;
end;

procedure TViewImg.GridMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
var I, Ind : integer;
    Ht, Ofs, RowHeight : Single;
begin
  Ofs := TopOfs + Y;
  I   := 0;
  Ht  := 0;
  Ind :=  Trunc(X / ColWidth);
  while True do
  begin
    RowHeight := RowHeights[ I ];
    Ht        := Ht + RowHeight;
    if Ind > LastPaintInd then
      Exit;
    if Ht > Ofs then
    begin
      Selected := Ind;
      SelectedChanged := True;
      with TViewImage(ImgList.Objects[ Selected ]) do
        LoadImage(FileName);
      NewTopOfs := TopOfs;
      with Grid do InvalidateRect(LocalRect);
      Exit;
    end;
    Inc(Ind, Cols);
    Inc(I);
  end;
end;

procedure TViewImg.GridPaint(Sender: TObject; Canvas: TCanvas;
  const ARect: TRectF);
begin
  PrepareBMP;
  with Grid, Canvas do
  begin
    DrawBitmap(BMP, RectF(0, 0, BMP.Width, BMP.Height), ARect, 1);
  end;
end;

procedure TViewImg.GridResize(Sender: TObject);
begin
  Cols  := 1;
  Grid.Width  := ColWidth;
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
  LastPaintInd := -1;
  TopOfs  := 0;
  NewTopOfs := 0;
  DefPageRows := Trunc(BMP.Height / (ImageWidth + HeadHt + FootHt));
  Handled := True;
  PlaceImage;
end;

procedure TViewImg.sysCloseClick(Sender: TObject);
begin
  ScanDir.Terminate;
  ScanDir.WaitFor;
  Close;
end;

procedure TViewImg.sysmaxClick(Sender: TObject);
begin
  if WindowState = TWindowState.wsNormal then
    WindowState := TWindowState.wsMaximized
  else
    WindowState := TWindowState.wsNormal;
end;

procedure TViewImg.sysMinClick(Sender: TObject);
begin
  WindowState := TWindowState.wsMinimized;
end;

procedure TViewImg.SetBounds(ALeft, ATop, AWidth, AHeight: Integer);
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

procedure TViewImg.SetHeights(FromInd, ToInd : integer);
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
    while I <= J do with TViewImage(ImgList.Objects[ I ]) do
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

procedure TViewImg.StatusBarPaint(Sender: TObject; Canvas: TCanvas;
  const ARect: TRectF);
var S : string;
begin
  if Selected >= 0 then with Canvas, TViewImage(ImgList.Objects[ Selected ]) do
  begin
    Font.Family  := 'Verdana';
    Font.Size    := 11;
    Font.Style   := [];
    Fill.Color := SelectColor;
    Fill.Kind  := TBrushKind.bkSolid;
    S := DateToStr(FileDate) + ' ' + FileName;
    FillText(ARect, S, False, 1, [], TTextAlign.taCenter);
  end;
end;

procedure TViewImg.ToolBarMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
begin
  StartWindowDrag;
end;

procedure TViewImg.TrackBarMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
begin
  TrackBar.Max := OutHeight(LastRow);
end;

procedure TViewImg.TrackChanged(Sender: TObject);
begin
  NewTopOfs := TrackBar.Value;
  with Grid do InvalidateRect(LocalRect);
end;

function TViewImg.ImageExists(I : integer) : boolean;
begin
  Result := True;
  with TViewImage(ImgList.Objects[ I ]) do
    if IsEmpty or (Width = 0) then
    try
      LoadThumbnailFromFile(FileName, ImageWidth, ImageWidth);
      if Width = 0 then
        Abort;
      FileAge(FileName, FileDate);
    except
      Result := False;
      ImgList.Delete(I);
    end;
end;

procedure TViewImg.UpdateList(Ind : integer);
var I : integer;
    Ht : Single;
    FullPage, ItemOnGrid : boolean;
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
  Ht   := OutHeight(LastRow);
  FullPage   := (TopOfs = 0) and (Ht > Grid.Height) and (Ind mod Cols = Cols - 1);
  ItemOnGrid := (TopOfs > 0) and (Ht > TopOfs) and (Ht < TopOfs + Grid.Height);
  if ItemOnGrid or FullPage or (TopOfs = 0) then
    with Grid do InvalidateRect(LocalRect);
  if not TrackBar.IsTracking then
    TrackBar.Max := Ht;
end;


end.
