unit Effect;

interface

uses
  System.SysUtils, System.Variants, System.Classes, System.UITypes, System.UIConsts, FMX.Types, FMX.Forms, FMX.Controls,
  FMX.Filter, FMX.Layouts, FMX.ListBox, FMX.Objects, FMX.Colors, FMX.Ani, FMX.Grid,
  FMX.Types3D, FMX.Layers3D;

type
  TfrmEffect = class(TForm)
    Layout1: TLayout;
    Layout2: TLayout;
    listCat: TListBox;
    Splitter4: TSplitter;
    listFX: TListBox;
    Source: TImage;
    Target: TImage;
    Dest: TImage;
    Splitter1: TSplitter;
    panelSettings: TListBox;
    Resources1: TStyleBook;
    Panel4: TPanel;
    btnBench: TButton;
    labelBench: TLabel;
    panelTransition: TPanel;
    btnPlay: TButton;
    AniIndicator1: TAniIndicator;
    ToolBar: TToolBar;
    sysClose: TButton;
    ImClose: TImage;
    sysMax: TButton;
    ImMax: TImage;
    sysMin: TButton;
    ImMin: TImage;
    procedure FormCreate(Sender: TObject);
    procedure listCat1Click(Sender: TObject);
    procedure listFX1Click(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnBench1Click(Sender: TObject);
    procedure btnPlay1Click(Sender: TObject);
    procedure sysMinClick(Sender: TObject);
    procedure sysMaxClick(Sender: TObject);
    procedure sysCloseClick(Sender: TObject);
  private
    { Private declarations }
    procedure DoFloatTrackChange(Sender: TObject);
    procedure DoColorChanged(Sender: TObject);
    procedure DoPointChanged(Sender: TObject);
    procedure UpdatePreview;
  public
    { Public declarations }
    Filter: TFilter;
    Rec: TFilterRec;
    TransitionAni: TFloatAnimation;
  end;

  procedure ShowEffects(Srcbmp : TBitmap);

var
  frmEffect: TfrmEffect;

implementation

{$R *.fmx}

procedure ShowEffects(Srcbmp : TBitmap);
var F : TCustomForm;
begin
  with frmEffect do
  begin
    Dest.Bitmap.Assign(Srcbmp);
    F := TCustomForm(Application.MainForm);
    SetBounds(F.Left, F.Top, F.Width, F.Height);
    StyleBook := F.StyleBook;
    Source.Position.Y := F.Height - Source.Height;
    Target.Position.Y := Source.Position.Y;
    Source.Bitmap.Assign(Srcbmp);
    ShowModal;
  end;
end;

procedure TfrmEffect.FormCreate(Sender: TObject);
var
  S: TStrings;
  I : integer;
begin
  S := TStringList.Create;
  FillCategory(S);
  I := S.IndexOf('Generator');
  if I <> -1 then
    S.Delete(I);
  listCat.Assign(S);
  S.Free;
end;

procedure TfrmEffect.FormDestroy(Sender: TObject);
begin
  if Filter <> nil then
    Filter.Free;
end;

procedure TfrmEffect.listCat1Click(Sender: TObject);
var
  S: TStrings;
begin
  if (TransitionAni <> nil) and (TransitionAni.Running) then
    TransitionAni.Stop;

  if listCat.ItemIndex < 0 then Exit;
  listFX.ItemIndex := -1;
  S := TStringList.Create;
  FillFiltersInCategory(listCat.ListItems[listCat.ItemIndex].Text, S);
  listFX.Assign(S);
  S.Free;
end;

procedure TfrmEffect.listFX1Click(Sender: TObject);
var
  i: integer;
  Item: TListboxItem;
  Shape: TSelectionPoint;
begin
  if (TransitionAni <> nil) and (TransitionAni.Running) then
    TransitionAni.Stop;

  if listFX.ItemIndex < 0 then Exit;
  // Delete setting controls
  if TransitionAni <> nil then
    FreeAndNil(TransitionAni);
  Dest.DeleteChildren;
  panelSettings.Clear;
  // Create Filter
  if Filter <> nil then
    Filter.Free;
  Filter := FilterByName(listFX.ListItems[listFX.ItemIndex].Text);
  // Create settings
  Rec := FilterClassByName(listFX.ListItems[listFX.ItemIndex].Text).FilterAttr;
//  labelName.Text := Rec.Desc;
  for i := 0 to High(Rec.Values) do
  with Rec.Values[i] do
  begin
    case ValueType of
      TShaderValueType.vtFloat:
        begin
          Item := TListboxItem.Create(nil);
          Item.Parent := panelSettings;
          Item.Height := 64;
          Item.StyleLookup := 'trackitem';
          Item.ApplyStyleLookup;
          Item.Text := Name + ' (' + FloatToStrF(Min, ffFixed, 10, 2) + '-' + FloatToStrF(Max, ffFixed, 10, 2) + ')';
          Item.Binding['desc'] := desc;
          TTrackBar(Item.FindBinding('track')).Min := Min;
          TTrackBar(Item.FindBinding('track')).Max := Max;
          TTrackBar(Item.FindBinding('track')).Value := Default;
          TTrackBar(Item.FindBinding('track')).Tag := i;
          Item.Binding['track'] := EventToVariant(DoFloatTrackChange);
          if Name = 'Progress' then
          begin
            TransitionAni := TFloatAnimation.Create(Self);
            TransitionAni.Parent := TTrackBar(Item.FindBinding('track'));
            TransitionAni.StartValue := 0;
            TransitionAni.StopValue := 100;
            TransitionAni.PropertyName := 'Value';
            TransitionAni.Duration := 2;
            TransitionAni.Loop := true;
            TransitionAni.AutoReverse := true;
          end;
          Item.Opacity := 0;
          Item.AnimateFloatDelay('Opacity', 1, 0.5, i / 10);
        end;
      TShaderValueType.vtPoint:
        begin
          Shape := TSelectionPoint.Create(Self);
          Shape.Parent := Dest;
          Shape.GripSize := 7;
          Shape.Position.X := VarToPoint(Default).x;
          Shape.Position.Y := VarToPoint(Default).y;
          Shape.OnTrack := DoPointChanged;
          Shape.Tag := i;
        end;
      TShaderValueType.vtColor:
        begin
          Item := TListboxItem.Create(nil);
          Item.Parent := panelSettings;
          Item.Height := 64;
          Item.StyleLookup := 'coloritem';
          Item.ApplyStyleLookup;
          Item.Text := Name;
          Item.Binding['desc'] := desc;
          Item.Binding['color'] := Default;
          Item.Binding['color'] := EventToVariant(DoColorChanged);
          TFmxObject(Item.FindBinding('color')).Tag := i;
          Item.Opacity := 0;
          Item.AnimateFloatDelay('Opacity', 1, 0.5, i / 10);
        end;
    end;
  end;
  UpdatePreview;
  if panelTransition.Visible <> (listCat.ListItems[listCat.ItemIndex].Text = 'Transition') then
  begin
    if panelTransition.Visible then
    begin
      btnPlay.AnimateFloatWait('Opacity', 0, 0.3);
      panelTransition.AnimateFloatWait('Height', 0, 0.3);
      panelTransition.Visible := false;
    end
    else
    begin
      panelTransition.Visible := true;
      panelTransition.Height := 0;
      panelTransition.AnimateFloat('Height', 36, 0.3);
      btnPlay.Opacity := 0;
      btnPlay.AnimateFloatDelay('Opacity', 1, 0.3, 0.3);
    end;
  end;
end;

procedure TfrmEffect.sysCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmEffect.sysMaxClick(Sender: TObject);
begin
  if WindowState = TWindowState.wsNormal then
    WindowState := TWindowState.wsMaximized
  else
    WindowState := TWindowState.wsNormal;
end;

procedure TfrmEffect.sysMinClick(Sender: TObject);
begin
  WindowState := TWindowState.wsMinimized;
end;

procedure TfrmEffect.DoFloatTrackChange(Sender: TObject);
begin
  Filter.Values[Rec.Values[TFmxObject(Sender).Tag].Name] := TTrackBar(Sender).Value;
  UpdatePreview;
end;

procedure TfrmEffect.DoColorChanged(Sender: TObject);
begin
  Filter.Values[Rec.Values[TFmxObject(Sender).Tag].Name] := StringToAlphaColor(TFmxObject(Sender).Data);
  UpdatePreview;
end;

procedure TfrmEffect.DoPointChanged(Sender: TObject);
begin
  Filter.Values[Rec.Values[TFmxObject(Sender).Tag].Name] := VarFromPointXY(TControl(Sender).Position.X, TControl(Sender).Position.Y);
  UpdatePreview;
end;

procedure TfrmEffect.UpdatePreview;
begin
  if Filter <> nil then
  begin
    // set input
    Filter.ValuesAsBitmap['Input'] := Source.Bitmap;
    // set Target only for transition
    Filter.ValuesAsBitmap['Target'] := Target.Bitmap;
    // apply, get and show result
    Dest.Bitmap := TBitmap(Filter.ValuesAsBitmap['output']);
  end;
end;

function GetTickCount: single;
var
  H, M, S, MS: word;
begin
  DecodeTime(time, H, M, S, MS);
  Result := ((((H * 60 * 60) + (M * 60) + S) * 1000) + MS);
end;

procedure TfrmEffect.btnBench1Click(Sender: TObject);
const
  Steps = 200;
var
  i: integer;
  StartTime, NewTime, Time: single;
begin
  btnBench.Enabled := false;
  labelBench.Visible := false;
  AniIndicator1.Visible := true;
  AniIndicator1.Enabled := true;

  Time := 0;
  for i := 1 to Steps do
  begin
    if Filter <> nil then
    begin
      // set input
      Filter.ValuesAsBitmap['input'] := Source.Bitmap;
      // apply (usually apply method called when you order Output }
      StartTime := GetTickCount / 1000;
      Filter.Apply;
      NewTime := GetTickCount / 1000;

      Time := Time + (NewTime - StartTime);

      Application.ProcessMessages;
    end;
  end;

  AniIndicator1.Enabled := false;
  AniIndicator1.Visible := false;

  labelBench.Visible := true;
  labelBench.Opacity := 0;
  labelBench.AnimateFloat('Opacity', 1, 0.3);
  labelBench.Text := 'Average: ' + FloatToStrF((Time) / Steps, ffFixed, 6, 4) + 'ms';
  btnBench.Enabled := true;
end;

procedure TfrmEffect.btnPlay1Click(Sender: TObject);
begin
  { Play Transition }
  if btnPlay.Text = 'Play' then
  begin
    TransitionAni.Start;
    btnPlay.Text := 'Stop';
  end
  else
  begin
    TransitionAni.Stop;
    btnPlay.Text := 'Play';
  end;
end;

end.
