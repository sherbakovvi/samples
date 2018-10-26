object FRefreshDB: TFRefreshDB
  Left = 0
  Top = 0
  Caption = 'Refresh DataBase'
  ClientHeight = 760
  ClientWidth = 1107
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object SourceFDB: TEdit
    Left = 8
    Top = 18
    Width = 377
    Height = 21
    TabOrder = 0
    Text = 'SourceFDB'
    OnChange = SourceFDBChange
  end
  object Source: TButton
    Left = 392
    Top = 18
    Width = 75
    Height = 25
    Caption = 'Source'
    TabOrder = 1
    OnClick = SourceClick
  end
  object TargetFDB: TEdit
    Left = 488
    Top = 18
    Width = 377
    Height = 21
    TabOrder = 2
    Text = 'TargetFDB'
    OnChange = SourceFDBChange
  end
  object Target: TButton
    Left = 871
    Top = 18
    Width = 75
    Height = 25
    Caption = 'Target'
    TabOrder = 3
    OnClick = TargetClick
  end
  object Script: TMemo
    Left = 0
    Top = 80
    Width = 1107
    Height = 680
    Align = alBottom
    ScrollBars = ssBoth
    TabOrder = 4
  end
  object RefreshDB: TButton
    Left = 1024
    Top = 16
    Width = 75
    Height = 25
    Caption = 'RefreshDB'
    Enabled = False
    TabOrder = 5
    OnClick = RefreshDBClick
  end
  object Demo: TCheckBox
    Left = 871
    Top = 57
    Width = 170
    Height = 17
    Caption = 'Make update script only'
    Checked = True
    State = cbChecked
    TabOrder = 6
  end
  object OpenDialog: TOpenDialog
    Filter = 'FireBird DB|*.fdb'
    Left = 920
    Top = 96
  end
end
